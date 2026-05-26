import { spawn, type ChildProcessWithoutNullStreams } from "node:child_process";
import { randomUUID } from "node:crypto";
import { createConnection } from "node:net";
import { tmpdir } from "node:os";
import { join } from "node:path";
import type { PlaybackState, PlayRequest, SeekRequest } from "../../../src/shared/playback/types.js";
import type { createCatalogRepository } from "../storage/catalogRepository.js";

interface CreateMpvControllerOptions {
  catalogRepository: ReturnType<typeof createCatalogRepository>;
  onStateChange(state: PlaybackState): void;
}

interface BuildMpvArgsInput {
  ipcPath: string;
  url: string;
  title: string;
}

type MpvIpcCommand = [string, ...Array<string | number | boolean>];

const maxStderrMessageLength = 500;

export function buildMpvArgs({ ipcPath, url, title }: BuildMpvArgsInput): string[] {
  return ["--force-window=yes", "--idle=no", `--input-ipc-server=${ipcPath}`, `--title=${title}`, url];
}

export function buildMpvIpcCommand(command: MpvIpcCommand): string {
  return `${JSON.stringify({ command })}\n`;
}

export function createMpvController(options: CreateMpvControllerOptions) {
  let process: ChildProcessWithoutNullStreams | null = null;
  let currentIpcPath: string | null = null;
  let state: PlaybackState = createIdleState();

  const setState = (patch: Partial<PlaybackState>) => {
    state = { ...state, ...patch };
    options.onStateChange(state);
  };

  const sendCommand = (command: MpvIpcCommand): Promise<void> => {
    if (!process || process.killed || !currentIpcPath) {
      return Promise.resolve();
    }

    const ipcPath = currentIpcPath;
    return new Promise((resolve) => {
      const socket = createConnection(ipcPath);
      socket.once("connect", () => {
        socket.end(buildMpvIpcCommand(command), resolve);
      });
      socket.once("error", () => {
        socket.destroy();
        resolve();
      });
    });
  };

  const terminateProcess = (): void => {
    if (!process || process.killed) {
      process = null;
      return;
    }
    process.removeAllListeners();
    process.kill();
    process = null;
    currentIpcPath = null;
  };

  const play = async (request: PlayRequest): Promise<void> => {
    if (request.itemType !== "live") {
      throw new Error(`Unsupported playback item type: ${request.itemType}`);
    }

    const channel = options.catalogRepository.getLiveChannel(request.itemId);
    if (!channel) {
      throw new Error(`Live channel not found: ${request.itemId}`);
    }

    const url = channel.stream.url;
    if (!url) {
      throw new Error(`No playable stream for live channel: ${request.itemId}`);
    }

    terminateProcess();
    setState({
      status: "loading",
      itemId: channel.id,
      itemType: "live",
      title: channel.name,
      positionSeconds: 0,
      durationSeconds: null,
      isSeekable: false,
      errorMessage: null
    });

    const ipcPath = join(tmpdir(), `iptv-player-mpv-${randomUUID()}.sock`);
    const mpvProcess = spawn("mpv", buildMpvArgs({ ipcPath, url, title: channel.name }));
    process = mpvProcess;
    currentIpcPath = ipcPath;

    mpvProcess.stderr.on("data", (chunk: Buffer) => {
      const message = sanitizeMpvMessage(chunk.toString("utf8"));
      if (message.length > 0) {
        setState({ errorMessage: message });
      }
    });

    mpvProcess.once("spawn", () => {
      options.catalogRepository.markRecentlyWatched(channel.id, "live");
      setState({ status: "playing" });
    });

    mpvProcess.once("error", (error) => {
      if (process === mpvProcess) {
        process = null;
        currentIpcPath = null;
      }
      setState({
        status: "error",
        errorMessage: sanitizeMpvMessage(error.message)
      });
    });

    mpvProcess.once("exit", (code, signal) => {
      if (process === mpvProcess) {
        process = null;
        currentIpcPath = null;
      }
      if (state.status !== "error" && state.status !== "idle") {
        setState({
          status: code === 0 || signal === "SIGTERM" ? "idle" : "error",
          errorMessage: code === 0 || signal === "SIGTERM" ? null : `mpv exited with code ${code ?? signal ?? "unknown"}`
        });
      }
    });
  };

  return {
    play,
    async pause(): Promise<void> {
      if (state.status === "playing") {
        await sendCommand(["set_property", "pause", true]);
        setState({ status: "paused" });
      } else if (state.status === "paused") {
        await sendCommand(["set_property", "pause", false]);
        setState({ status: "playing" });
      }
    },
    stop(): Promise<void> {
      terminateProcess();
      setState(createIdleState());
      return Promise.resolve();
    },
    async seek(request: SeekRequest): Promise<void> {
      if (state.isSeekable) {
        await sendCommand(["seek", request.offsetSeconds, "relative"]);
      }
    },
    getState(): PlaybackState {
      return state;
    }
  };
}

function createIdleState(): PlaybackState {
  return {
    status: "idle",
    itemId: null,
    itemType: null,
    title: null,
    positionSeconds: 0,
    durationSeconds: null,
    isSeekable: false,
    errorMessage: null
  };
}

function sanitizeMpvMessage(message: string): string {
  return message
    .replace(/([?&]password=)[^&\s]*/gi, "$1REDACTED")
    .replace(/\s+/g, " ")
    .trim()
    .slice(0, maxStderrMessageLength);
}
