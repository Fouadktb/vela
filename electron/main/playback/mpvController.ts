import { spawn, type ChildProcessWithoutNullStreams } from "node:child_process";
import { randomUUID } from "node:crypto";
import { existsSync } from "node:fs";
import { createConnection } from "node:net";
import { tmpdir } from "node:os";
import { delimiter, join, win32 } from "node:path";
import type { PlaybackState, PlaybackTrack, PlayRequest, SeekRequest } from "../../../src/shared/playback/types.js";
import type { createCatalogRepository } from "../storage/catalogRepository.js";

interface CreateMpvControllerOptions {
  catalogRepository: ReturnType<typeof createCatalogRepository>;
  onStateChange(state: PlaybackState): void;
}

interface BuildMpvArgsInput {
  ipcPath: string;
  url: string;
  title: string;
  platform?: NodeJS.Platform;
}

interface ResolveMpvExecutablePathOptions {
  env: NodeJS.ProcessEnv;
  platform: NodeJS.Platform;
  resourcesPath: string;
  existsSync(path: string): boolean;
}

type MpvIpcValue = string | number | boolean | null;
type MpvIpcCommand = [string, ...MpvIpcValue[]];

interface MpvIpcResponse<T> {
  request_id?: number;
  error?: string;
  data?: T;
}

interface MpvRawTrack {
  id?: unknown;
  type?: unknown;
  title?: unknown;
  lang?: unknown;
  default?: unknown;
  selected?: unknown;
}

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

export function buildMpvArgs({ ipcPath, url, title, platform = process.platform }: BuildMpvArgsInput): string[] {
  return [
    "--no-config",
    "--player-operation-mode=pseudo-gui",
    "--force-window=immediate",
    "--idle=no",
    "--keep-open=no",
    "--terminal=no",
    "--term-osd=no",
    "--input-terminal=no",
    "--cursor-autohide=700",
    "--cursor-autohide-fs-only=no",
    "--force-window-position=yes",
    "--geometry=82%x82%",
    "--autofit-larger=92%x92%",
    "--background=color",
    "--background-color=#FF0D0C0A",
    "--border=no",
    "--snap-window=yes",
    "--stop-screensaver=always",
    "--hwdec=auto-safe",
    "--profile=fast",
    "--cache=yes",
    "--cache-pause=no",
    "--cache-pause-initial=no",
    "--demuxer-readahead-secs=8",
    "--demuxer-max-bytes=256MiB",
    "--network-timeout=15",
    "--hls-bitrate=max",
    "--audio-display=no",
    "--osc=yes",
    `--script-opts=${buildOscScriptOptions()}`,
    "--osd-level=1",
    "--osd-on-seek=msg-bar",
    "--osd-duration=850",
    "--osd-bar-align-y=0.92",
    "--osd-bar-w=88",
    "--osd-bar-h=2.2",
    "--osd-bar-outline-size=0",
    "--osd-font=sans-serif",
    "--osd-font-size=28",
    "--osd-color=#FFF4ECD7",
    "--osd-selected-color=#FFD8F271",
    "--osd-outline-color=#E0000000",
    "--osd-outline-size=1.1",
    "--osd-back-color=#B414120F",
    "--osd-shadow-offset=0",
    "--sub-font=sans-serif",
    "--sub-font-size=42",
    "--sub-color=#FFF9F2DF",
    "--sub-outline-color=#E0000000",
    "--sub-outline-size=2.2",
    "--sub-shadow-offset=0",
    ...buildPlatformMpvArgs(platform),
    `--input-ipc-server=${ipcPath}`,
    `--title=${title}`,
    url
  ];
}

export function resolveMpvExecutablePath(options: ResolveMpvExecutablePathOptions): string | null {
  const explicitPath = options.env.MPV_PATH?.trim();
  if (explicitPath) {
    return explicitPath;
  }

  for (const candidate of getBundledMpvCandidates(options.resourcesPath, options.platform)) {
    if (options.existsSync(candidate)) {
      return candidate;
    }
  }

  for (const candidate of getSystemMpvCandidates(options.platform, options.env)) {
    if (options.existsSync(candidate)) {
      return candidate;
    }
  }

  const executableName = options.platform === "win32" ? "mpv.exe" : "mpv";
  for (const directory of (options.env.PATH ?? "").split(delimiter)) {
    if (!directory) {
      continue;
    }
    const candidate = join(directory, executableName);
    if (options.existsSync(candidate)) {
      return candidate;
    }
  }

  return null;
}

export function buildMpvIpcCommand(command: MpvIpcCommand): string {
  return `${JSON.stringify({ command })}\n`;
}

function buildMpvIpcRequest(command: MpvIpcCommand, requestId: number): string {
  return `${JSON.stringify({ command, request_id: requestId })}\n`;
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

export function toPlaybackTrackState(
  rawTracks: MpvRawTrack[],
  selectedAudioTrack: unknown,
  selectedSubtitleTrack: unknown
): Pick<PlaybackState, "audioTracks" | "subtitleTracks" | "selectedAudioTrackId" | "selectedSubtitleTrackId"> {
  const selectedAudioTrackId = toTrackId(selectedAudioTrack);
  const selectedSubtitleTrackId = toTrackId(selectedSubtitleTrack);
  const audioTracks = rawTracks
    .map((track) => toPlaybackTrack(track, "audio", selectedAudioTrackId))
    .filter((track): track is PlaybackTrack => track !== null);
  const subtitleTracks = rawTracks
    .map((track) => toPlaybackTrack(track, "subtitle", selectedSubtitleTrackId))
    .filter((track): track is PlaybackTrack => track !== null);

  return {
    audioTracks,
    subtitleTracks,
    selectedAudioTrackId,
    selectedSubtitleTrackId
  };
}

export function createMpvController(options: CreateMpvControllerOptions) {
  let processRef: ChildProcessWithoutNullStreams | null = null;
  let currentIpcPath: string | null = null;
  let state: PlaybackState = createIdleState();
  let nextIpcRequestId = 1;

  const setState = (patch: Partial<PlaybackState>) => {
    state = { ...state, ...patch };
    options.onStateChange(state);
  };

  const sendCommand = (command: MpvIpcCommand): Promise<void> => {
    if (!processRef || processRef.killed || !currentIpcPath) {
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

  const sendCommandWithResponse = <T>(command: MpvIpcCommand): Promise<T | undefined> => {
    if (!processRef || processRef.killed || !currentIpcPath) {
      return Promise.resolve(undefined);
    }

    const ipcPath = currentIpcPath;
    const requestId = nextIpcRequestId;
    nextIpcRequestId += 1;

    return new Promise((resolve, reject) => {
      const socket = createConnection(ipcPath);
      let buffer = "";
      const timeout = setTimeout(() => {
        socket.destroy();
        reject(new Error("mpv IPC command timed out"));
      }, mpvIpcCommandTimeoutMs);

      const finish = (response?: MpvIpcResponse<T>, error?: Error) => {
        clearTimeout(timeout);
        socket.removeAllListeners();
        socket.destroy();
        if (error) {
          reject(new Error("mpv IPC command failed"));
          return;
        }
        if (response?.error && response.error !== "success") {
          reject(new Error("mpv IPC command failed"));
          return;
        }
        resolve(response?.data);
      };

      socket.on("data", (chunk: Buffer) => {
        buffer += chunk.toString("utf8");
        const lines = buffer.split("\n");
        buffer = lines.pop() ?? "";

        for (const line of lines) {
          if (!line.trim()) {
            continue;
          }

          let response: MpvIpcResponse<T>;
          try {
            response = JSON.parse(line) as MpvIpcResponse<T>;
          } catch {
            continue;
          }

          if (response.request_id === requestId) {
            finish(response);
            return;
          }
        }
      });
      socket.once("connect", () => {
        socket.write(buildMpvIpcRequest(command, requestId));
      });
      socket.once("error", (error) => {
        finish(undefined, error);
      });
    });
  };

  const refreshTrackState = async (): Promise<void> => {
    try {
      const rawTracks = (await sendCommandWithResponse<unknown>(["get_property", "track-list"])) ?? [];
      const selectedAudioTrack = await sendCommandWithResponse<unknown>(["get_property", "aid"]);
      const selectedSubtitleTrack = await sendCommandWithResponse<unknown>(["get_property", "sid"]);
      if (Array.isArray(rawTracks)) {
        setState(toPlaybackTrackState(rawTracks as MpvRawTrack[], selectedAudioTrack, selectedSubtitleTrack));
      }
    } catch {
      // Track metadata is best-effort because mpv may not expose IPC immediately after spawn.
    }
  };

  const terminateProcess = (): void => {
    if (!processRef || processRef.killed) {
      processRef = null;
      currentIpcPath = null;
      return;
    }
    processRef.removeAllListeners();
    processRef.kill();
    processRef = null;
    currentIpcPath = null;
  };

  const play = async (request: PlayRequest): Promise<void> => {
    const itemType = request.itemType;
    if (itemType !== "live" && itemType !== "movie" && itemType !== "episode") {
      throw new Error(`Unsupported playback item type: ${itemType}`);
    }

    const item = getPlayableCatalogItem(request.itemId, itemType);
    if (!item) {
      throw new Error(`Catalog item not found: ${request.itemId}`);
    }

    const url = item.stream.url;
    if (!url) {
      throw new Error(`No playable stream for catalog item: ${request.itemId}`);
    }
    const title =
      item.type === "live"
        ? item.name
        : item.type === "episode"
          ? `S${item.seasonNumber} E${item.episodeNumber} ${item.title}`
          : item.title;

    terminateProcess();
    setState({
      status: "loading",
      itemId: item.id,
      itemType,
      title,
      positionSeconds: 0,
      durationSeconds: null,
      isSeekable: itemType !== "live",
      audioTracks: [],
      subtitleTracks: [],
      selectedAudioTrackId: null,
      selectedSubtitleTrackId: null,
      errorMessage: null
    });

    const mpvPath = resolveMpvExecutablePath({
      env: process.env,
      platform: process.platform,
      resourcesPath: process.resourcesPath,
      existsSync
    });

    if (!mpvPath) {
      setState({
        status: "error",
        errorMessage: "mpv is not installed or bundled with this app yet."
      });
      return;
    }

    const ipcPath = buildMpvIpcPath();
    const mpvProcess = spawn(mpvPath, buildMpvArgs({ ipcPath, url, title, platform: process.platform }));
    processRef = mpvProcess;
    currentIpcPath = ipcPath;

    mpvProcess.stderr.on("data", (chunk: Buffer) => {
      const diagnostic = sanitizePlaybackDiagnostic(chunk.toString("utf8"));
      if (diagnostic.length > 0) {
        setState({ errorMessage: "mpv reported a playback error." });
      }
    });

    mpvProcess.once("spawn", () => {
      options.catalogRepository.markRecentlyWatched(item.id, itemType);
      setState({ status: "playing" });
      setTimeout(() => void refreshTrackState(), 350);
    });

    mpvProcess.once("error", (error) => {
      if (processRef === mpvProcess) {
        processRef = null;
        currentIpcPath = null;
      }
      setState({
        status: "error",
        errorMessage: "mpv failed to start. Check that the bundled player is available."
      });
    });

    mpvProcess.once("exit", (code, signal) => {
      if (processRef === mpvProcess) {
        processRef = null;
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
    async selectAudioTrack(trackId: number): Promise<void> {
      await sendCommandWithResponse(["set_property", "aid", trackId]);
      await refreshTrackState();
    },
    async selectSubtitleTrack(trackId: number | null): Promise<void> {
      await sendCommandWithResponse(["set_property", "sid", trackId ?? "no"]);
      await refreshTrackState();
    },
    getState(): PlaybackState {
      return state;
    }
  };

  function getPlayableCatalogItem(itemId: string, itemType: "live" | "movie" | "episode") {
    if (itemType === "live") {
      return options.catalogRepository.getLiveChannel(itemId);
    }
    if (itemType === "movie") {
      return options.catalogRepository.getMovie(itemId);
    }

    return options.catalogRepository.getEpisode(itemId);
  }
}

function toPlaybackTrack(
  rawTrack: MpvRawTrack,
  expectedType: PlaybackTrack["type"],
  selectedTrackId: number | null
): PlaybackTrack | null {
  const id = toTrackId(rawTrack.id);
  if (id === null) {
    return null;
  }

  const trackType = rawTrack.type === "audio" ? "audio" : rawTrack.type === "sub" ? "subtitle" : null;
  if (trackType !== expectedType) {
    return null;
  }

  const language = typeof rawTrack.lang === "string" && rawTrack.lang.trim() ? rawTrack.lang.trim() : null;
  const title = toTrackTitle(rawTrack.title, language, trackType, id);

  return {
    id,
    type: trackType,
    title,
    language,
    isDefault: rawTrack.default === true,
    isSelected: rawTrack.selected === true || selectedTrackId === id
  };
}

function toTrackId(value: unknown): number | null {
  if (typeof value === "number" && Number.isInteger(value) && value > 0) {
    return value;
  }

  if (typeof value === "string" && /^\d+$/.test(value)) {
    const parsed = Number.parseInt(value, 10);
    return parsed > 0 ? parsed : null;
  }

  return null;
}

function toTrackTitle(rawTitle: unknown, language: string | null, trackType: PlaybackTrack["type"], id: number): string {
  if (typeof rawTitle === "string" && rawTitle.trim()) {
    return rawTitle.trim();
  }

  if (language) {
    return language;
  }

  return trackType === "audio" ? `Audio ${id}` : `Subtitle ${id}`;
}

function buildOscScriptOptions(): string {
  return [
    "osc-layout=bottombar",
    "osc-seekbarstyle=bar",
    "osc-deadzonesize=0",
    "osc-minmousemove=3",
    "osc-hidetimeout=1200",
    "osc-fadeduration=220",
    "osc-boxalpha=70",
    "osc-barmargin=6",
    "osc-scalewindowed=1.08",
    "osc-scalefullscreen=1.18"
  ].join(",");
}

function buildPlatformMpvArgs(platform: NodeJS.Platform): string[] {
  if (platform !== "darwin") {
    return [];
  }

  return [
    "--macos-title-bar-appearance=vibrantDark",
    "--macos-title-bar-material=hudWindow",
    "--macos-title-bar-color=#2212100D",
    "--macos-fs-animation-duration=160",
    "--macos-geometry-calculation=visible"
  ];
}

function getBundledMpvCandidates(resourcesPath: string, platform: NodeJS.Platform): string[] {
  const pathJoin = platform === "win32" ? win32.join : join;
  if (platform === "win32") {
    return [
      pathJoin(resourcesPath, "bin", "mpv", "win32", "mpv.exe"),
      pathJoin(resourcesPath, "bin", "mpv.exe")
    ];
  }

  if (platform === "darwin") {
    return [
      pathJoin(resourcesPath, "bin", "mpv", "darwin", "mpv.app", "Contents", "MacOS", "mpv"),
      pathJoin(resourcesPath, "bin", "mpv", "darwin", "mpv"),
      pathJoin(resourcesPath, "bin", "mpv")
    ];
  }

  return [
    pathJoin(resourcesPath, "bin", "mpv", platform, "mpv"),
    pathJoin(resourcesPath, "bin", "mpv")
  ];
}

function getSystemMpvCandidates(platform: NodeJS.Platform, env: NodeJS.ProcessEnv): string[] {
  if (platform === "darwin") {
    return [
      "/Applications/mpv.app/Contents/MacOS/mpv",
      "/opt/homebrew/bin/mpv",
      "/usr/local/bin/mpv"
    ];
  }

  if (platform === "win32") {
    const programFiles = env.ProgramFiles ?? "C:\\Program Files";
    const programFilesX86 = env["ProgramFiles(x86)"] ?? "C:\\Program Files (x86)";
    const localAppData = env.LOCALAPPDATA;
    return [
      win32.join(programFiles, "mpv", "mpv.exe"),
      win32.join(programFilesX86, "mpv", "mpv.exe"),
      ...(localAppData ? [win32.join(localAppData, "mpv", "mpv.exe")] : [])
    ];
  }

  return [];
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
    audioTracks: [],
    subtitleTracks: [],
    selectedAudioTrackId: null,
    selectedSubtitleTrackId: null,
    errorMessage: null
  };
}
