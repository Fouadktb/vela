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

const maxDiagnosticLength = 300;
const mpvIpcCommandTimeoutMs = 1_500;
const secretQueryKeys = [
  "password",
  "pass",
  "username",
  "user",
  "token",
  "auth",
  "key",
  "signature",
  "sig",
  "expires",
  "session",
  "sessionid",
  "session_id",
  "apikey",
  "api_key",
  "access_token",
  "refresh_token"
];

export function buildMpvArgs({ ipcPath, url, title }: BuildMpvArgsInput): string[] {
  return ["--force-window=yes", "--idle=no", `--input-ipc-server=${ipcPath}`, `--title=${title}`, url];
}

export function buildMpvIpcCommand(command: MpvIpcCommand): string {
  return `${JSON.stringify({ command })}\n`;
}

export function buildMpvIpcPath(platform: NodeJS.Platform = process.platform, id: string = randomUUID()): string {
  if (platform === "win32") {
    return `\\\\.\\pipe\\iptv-player-mpv-${id}`;
  }

  return join(tmpdir(), `iptv-player-mpv-${id}.sock`);
}

export function sanitizePlaybackDiagnostic(message: string): string {
  const secretPattern = new RegExp(`([?&](${secretQueryKeys.join("|")})=)[^&\\s]+`, "gi");
  const bareSecretPattern = new RegExp(`\\b(${secretQueryKeys.join("|")})=([^&\\s]+)`, "gi");

  return message
    .replace(secretPattern, "$1REDACTED")
    .replace(bareSecretPattern, "$1=REDACTED")
    .replace(/\b[a-z][a-z0-9+.-]*:\/\/[^\s]+/gi, "[URL REDACTED]")
    .replace(/\s+/g, " ")
    .trim()
    .slice(0, maxDiagnosticLength);
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
    return new Promise((resolve, reject) => {
      const socket = createConnection(ipcPath);
      const timeout = setTimeout(() => {
        socket.destroy();
        reject(new Error("mpv IPC command timed out"));
      }, mpvIpcCommandTimeoutMs);

      const finish = (error?: Error) => {
        clearTimeout(timeout);
        socket.removeAllListeners();
        if (error) {
          reject(new Error("mpv IPC command failed"));
          return;
        }
        resolve();
      };

      socket.once("connect", () => {
        socket.end(buildMpvIpcCommand(command), () => finish());
      });
      socket.once("error", (error) => {
        socket.destroy();
        finish(error);
      });
    });
  };

  const terminateProcess = (): void => {
    if (!process || process.killed) {
      process = null;
      currentIpcPath = null;
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

    const ipcPath = buildMpvIpcPath();
    const mpvProcess = spawn("mpv", buildMpvArgs({ ipcPath, url, title: channel.name }));
    process = mpvProcess;
    currentIpcPath = ipcPath;

    mpvProcess.stderr.on("data", (chunk: Buffer) => {
      const diagnostic = sanitizePlaybackDiagnostic(chunk.toString("utf8"));
      if (diagnostic.length > 0) {
        setState({ errorMessage: "mpv reported a playback error." });
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
        errorMessage: "mpv failed to start."
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
          errorMessage: code === 0 || signal === "SIGTERM" ? null : "mpv exited unexpectedly."
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
