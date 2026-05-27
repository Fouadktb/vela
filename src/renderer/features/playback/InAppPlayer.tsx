import { useEffect, useRef, useState } from "react";
import type { Dispatch, MutableRefObject, SetStateAction } from "react";
import type Hls from "hls.js";
import type mpegts from "mpegts.js";
import { iptvApi } from "../../app/api";
import type { PlayRequest, PlaybackState, PlaybackTrack, ResolvedPlaybackSource } from "../../../shared/playback/types";
import { PlayerControls } from "./PlayerControls";

interface InAppPlayerProps {
  request: PlayRequest | null;
  onClose(): void;
}

type EngineInstance = { type: "hls"; instance: Hls } | { type: "mpegts"; instance: mpegts.Player } | null;
const inAppStartupFallbackTimeoutMs = 7_000;

export function InAppPlayer({ request, onClose }: InAppPlayerProps) {
  const videoRef = useRef<HTMLVideoElement | null>(null);
  const engineRef = useRef<EngineInstance>(null);
  const fallbackStartedRef = useRef(false);
  const [source, setSource] = useState<ResolvedPlaybackSource | null>(null);
  const [fallbackActive, setFallbackActive] = useState(false);
  const [state, setState] = useState<PlaybackState | null>(null);

  useEffect(() => {
    let isCancelled = false;

    cleanupEngine(engineRef.current, videoRef.current);
    engineRef.current = null;
    fallbackStartedRef.current = false;
    setFallbackActive(false);

    if (!request) {
      setSource(null);
      setState(null);
      return;
    }

    setState(createPlaybackStateFromRequest(request, "loading"));

    iptvApi.playback
      .resolve(request)
      .then((resolvedSource) => {
        if (isCancelled) {
          return;
        }

        setSource(resolvedSource);
        setState(createPlaybackStateFromSource(resolvedSource, "loading"));

        if (resolvedSource.preferredEngine === "fallback") {
          void startFallbackPlayback(request, setState, setFallbackActive, fallbackStartedRef);
        } else {
          void iptvApi.playback.stop();
        }
      })
      .catch((error) => {
        if (!isCancelled) {
          setState({
            ...createPlaybackStateFromRequest(request, "error"),
            errorMessage: error instanceof Error ? error.message : "Playback could not start."
          });
        }
      });

    return () => {
      isCancelled = true;
    };
  }, [request?.itemId, request?.itemType]);

  useEffect(() => {
    if (!source || source.preferredEngine === "fallback" || fallbackActive) {
      return;
    }

    const video = videoRef.current;
    if (!video) {
      return;
    }

    let isDisposed = false;
    setState(createPlaybackStateFromSource(source, "loading"));

    const updateFromVideo = (patch: Partial<PlaybackState> = {}) => {
      if (isDisposed) {
        return;
      }

      setState((current) => ({
        ...(current ?? createPlaybackStateFromSource(source, "loading")),
        ...patch,
        positionSeconds: Number.isFinite(video.currentTime) ? video.currentTime : 0,
        durationSeconds: getFiniteDuration(video),
        isSeekable: !source.isLive && getFiniteDuration(video) !== null,
        subtitleTracks: getHtmlSubtitleTracks(video)
      }));
    };

    const startFallback = () => {
      if (isDisposed || !request) {
        return;
      }
      void startFallbackPlayback(request, setState, setFallbackActive, fallbackStartedRef);
    };

    const handlePlaying = () => updateFromVideo({ status: "playing", errorMessage: null });
    const handlePause = () => {
      if (!video.ended) {
        updateFromVideo({ status: "paused" });
      }
    };
    const handleEnded = () => {
      setState(createIdleState());
      onClose();
    };
    const handleError = () => startFallback();
    const handleLoadedMetadata = () => updateFromVideo();
    const handleTimeUpdate = () => updateFromVideo();
    const startupFallbackTimeout = window.setTimeout(() => {
      if (!video.paused && video.readyState >= HTMLMediaElement.HAVE_CURRENT_DATA) {
        return;
      }
      startFallback();
    }, inAppStartupFallbackTimeoutMs);

    video.addEventListener("playing", handlePlaying);
    video.addEventListener("pause", handlePause);
    video.addEventListener("ended", handleEnded);
    video.addEventListener("error", handleError);
    video.addEventListener("loadedmetadata", handleLoadedMetadata);
    video.addEventListener("durationchange", handleLoadedMetadata);
    video.addEventListener("timeupdate", handleTimeUpdate);

    void attachPlaybackEngine(source, video, updateFromVideo, startFallback)
      .then((engine) => {
        if (isDisposed) {
          cleanupEngine(engine, video);
          return;
        }
        engineRef.current = engine;
      })
      .catch(startFallback);

    return () => {
      isDisposed = true;
      window.clearTimeout(startupFallbackTimeout);
      video.removeEventListener("playing", handlePlaying);
      video.removeEventListener("pause", handlePause);
      video.removeEventListener("ended", handleEnded);
      video.removeEventListener("error", handleError);
      video.removeEventListener("loadedmetadata", handleLoadedMetadata);
      video.removeEventListener("durationchange", handleLoadedMetadata);
      video.removeEventListener("timeupdate", handleTimeUpdate);
      cleanupEngine(engineRef.current, video);
      engineRef.current = null;
    };
  }, [source, fallbackActive, request?.itemId, request?.itemType, onClose]);

  if (!request) {
    return null;
  }

  if (fallbackActive) {
    return (
      <div className="fallback-player" aria-label="Video player">
        <div className="fallback-player-copy">
          <span>Playback</span>
          <strong>{state?.title ?? "Playback"}</strong>
        </div>
        <FallbackPlayerControls onClose={onClose} />
      </div>
    );
  }

  return (
    <div className="in-app-player" aria-label="Video player">
      <video className="in-app-video" ref={videoRef} playsInline />
      {state?.status === "loading" ? <div className="in-app-player-status">Loading playback</div> : null}
      {state?.status === "error" ? <div className="in-app-player-status error">{state.errorMessage}</div> : null}
      <PlayerControls
        state={state}
        onPause={() => toggleVideoPlayback(videoRef.current, setState)}
        onStop={() => {
          cleanupEngine(engineRef.current, videoRef.current);
          engineRef.current = null;
          setState(createIdleState());
          onClose();
        }}
        onSeek={(offsetSeconds) => seekVideo(videoRef.current, offsetSeconds)}
        onSelectAudioTrack={(trackId) => selectAudioTrack(engineRef.current, trackId, setState)}
        onSelectSubtitleTrack={(trackId) => selectSubtitleTrack(engineRef.current, videoRef.current, trackId, setState)}
      />
    </div>
  );
}

function FallbackPlayerControls({ onClose }: { onClose(): void }) {
  const [fallbackState, setFallbackState] = useState<PlaybackState | null>(null);

  useEffect(() => {
    let isMounted = true;

    iptvApi.playback
      .getState()
      .then((nextState) => {
        if (isMounted) {
          setFallbackState(nextState);
        }
      })
      .catch(() => {
        if (isMounted) {
          setFallbackState(null);
        }
      });

    const unsubscribe = iptvApi.playback.onState((nextState) => {
      setFallbackState(nextState);
      if (nextState.status === "idle") {
        onClose();
      }
    });

    return () => {
      isMounted = false;
      unsubscribe();
    };
  }, [onClose]);

  return (
    <PlayerControls
      state={fallbackState}
      onPause={() => void iptvApi.playback.pause()}
      onStop={() => {
        void iptvApi.playback.stop();
        onClose();
      }}
      onSeek={(offsetSeconds) => void iptvApi.playback.seek({ offsetSeconds })}
      onSelectAudioTrack={(trackId) => void iptvApi.playback.selectAudioTrack(trackId)}
      onSelectSubtitleTrack={(trackId) => void iptvApi.playback.selectSubtitleTrack(trackId)}
    />
  );
}

async function attachPlaybackEngine(
  source: ResolvedPlaybackSource,
  video: HTMLVideoElement,
  updateFromVideo: (patch?: Partial<PlaybackState>) => void,
  startFallback: () => void
): Promise<EngineInstance> {
  video.removeAttribute("src");
  safeMediaCall(() => video.load());

  if (source.preferredEngine === "hls") {
    const { default: HlsRuntime } = await import("hls.js");

    if (HlsRuntime.isSupported()) {
      const hls = new HlsRuntime({
        enableWorker: true,
        lowLatencyMode: source.isLive
      });
      hls.attachMedia(video);
      hls.on(HlsRuntime.Events.MEDIA_ATTACHED, () => hls.loadSource(source.url));
      hls.on(HlsRuntime.Events.MANIFEST_PARSED, () => {
        updateFromVideo(getHlsTrackState(hls));
        void video.play().catch(startFallback);
      });
      hls.on(HlsRuntime.Events.AUDIO_TRACKS_UPDATED, () => updateFromVideo(getHlsTrackState(hls)));
      hls.on(HlsRuntime.Events.AUDIO_TRACK_SWITCHED, () => updateFromVideo(getHlsTrackState(hls)));
      hls.on(HlsRuntime.Events.SUBTITLE_TRACKS_UPDATED, () => updateFromVideo(getHlsTrackState(hls)));
      hls.on(HlsRuntime.Events.SUBTITLE_TRACK_SWITCH, () => updateFromVideo(getHlsTrackState(hls)));
      hls.on(HlsRuntime.Events.ERROR, (_event, data) => {
        if (data.fatal) {
          startFallback();
        }
      });
      return { type: "hls", instance: hls };
    }

    if (video.canPlayType("application/vnd.apple.mpegurl")) {
      video.src = source.url;
      void video.play().catch(startFallback);
      return null;
    }

    startFallback();
    return null;
  }

  if (source.preferredEngine === "mpegts") {
    const { default: mpegtsRuntime } = await import("mpegts.js");

    if (!mpegtsRuntime.isSupported()) {
      startFallback();
      return null;
    }

    const player = mpegtsRuntime.createPlayer(
      {
        type: "mpegts",
        isLive: source.isLive,
        cors: true,
        url: source.url
      },
      {
        enableWorker: true,
        enableStashBuffer: !source.isLive,
        isLive: source.isLive,
        liveBufferLatencyChasing: source.isLive
      }
    );
    player.attachMediaElement(video);
    player.on(mpegtsRuntime.Events.ERROR, startFallback);
    player.load();
    void video.play().catch(startFallback);
    return { type: "mpegts", instance: player };
  }

  video.src = source.url;
  safeMediaCall(() => video.load());
  void video.play().catch(startFallback);
  return null;
}

async function startFallbackPlayback(
  request: PlayRequest,
  setState: Dispatch<SetStateAction<PlaybackState | null>>,
  setFallbackActive: Dispatch<SetStateAction<boolean>>,
  fallbackStartedRef: MutableRefObject<boolean>
): Promise<void> {
  if (fallbackStartedRef.current) {
    return;
  }

  fallbackStartedRef.current = true;
  setFallbackActive(true);
  try {
    await iptvApi.playback.play(request);
  } catch (error) {
    setState({
      ...createPlaybackStateFromRequest(request, "error"),
      errorMessage: error instanceof Error ? error.message : "Playback could not start."
    });
  }
}

function cleanupEngine(engine: EngineInstance, video: HTMLVideoElement | null): void {
  if (engine?.type === "hls") {
    engine.instance.destroy();
  } else if (engine?.type === "mpegts") {
    engine.instance.destroy();
  }

  if (video) {
    const hadSource = Boolean(video.currentSrc || video.getAttribute("src"));
    if (hadSource) {
      safeMediaCall(() => video.pause());
    }
    video.removeAttribute("src");
    if (hadSource) {
      safeMediaCall(() => video.load());
    }
  }
}

function toggleVideoPlayback(
  video: HTMLVideoElement | null,
  setState: Dispatch<SetStateAction<PlaybackState | null>>
): void {
  if (!video) {
    return;
  }

  if (video.paused) {
    void video.play();
    setState((current) => (current ? { ...current, status: "playing" } : current));
    return;
  }

  video.pause();
  setState((current) => (current ? { ...current, status: "paused" } : current));
}

function seekVideo(video: HTMLVideoElement | null, offsetSeconds: -10 | 10): void {
  if (!video || !Number.isFinite(video.duration)) {
    return;
  }

  video.currentTime = Math.min(video.duration, Math.max(0, video.currentTime + offsetSeconds));
}

function selectAudioTrack(
  engine: EngineInstance,
  trackId: number,
  setState: Dispatch<SetStateAction<PlaybackState | null>>
): void {
  if (engine?.type === "hls") {
    engine.instance.audioTrack = trackId;
    setState((current) => (current ? { ...current, ...getHlsTrackState(engine.instance) } : current));
  }
}

function selectSubtitleTrack(
  engine: EngineInstance,
  video: HTMLVideoElement | null,
  trackId: number | null,
  setState: Dispatch<SetStateAction<PlaybackState | null>>
): void {
  if (engine?.type === "hls") {
    engine.instance.subtitleTrack = trackId ?? -1;
    setState((current) => (current ? { ...current, ...getHlsTrackState(engine.instance) } : current));
    return;
  }

  if (!video) {
    return;
  }

  for (const [index, track] of Array.from(video.textTracks).entries()) {
    track.mode = trackId === index ? "showing" : "disabled";
  }
  setState((current) => (current ? { ...current, subtitleTracks: getHtmlSubtitleTracks(video) } : current));
}

function getHlsTrackState(hls: Hls): Pick<PlaybackState, "audioTracks" | "subtitleTracks" | "selectedAudioTrackId" | "selectedSubtitleTrackId"> {
  return {
    audioTracks: hls.audioTracks.map((track, index) => ({
      id: index,
      type: "audio",
      title: track.name || track.lang || `Audio ${index + 1}`,
      language: track.lang || null,
      isDefault: Boolean(track.default),
      isSelected: hls.audioTrack === index
    })),
    subtitleTracks: hls.subtitleTracks.map((track, index) => ({
      id: index,
      type: "subtitle",
      title: track.name || track.lang || `Subtitle ${index + 1}`,
      language: track.lang || null,
      isDefault: Boolean(track.default),
      isSelected: hls.subtitleTrack === index
    })),
    selectedAudioTrackId: hls.audioTrack >= 0 ? hls.audioTrack : null,
    selectedSubtitleTrackId: hls.subtitleTrack >= 0 ? hls.subtitleTrack : null
  };
}

function getHtmlSubtitleTracks(video: HTMLVideoElement): PlaybackTrack[] {
  return Array.from(video.textTracks).map((track, index) => ({
    id: index,
    type: "subtitle",
    title: track.label || track.language || `Subtitle ${index + 1}`,
    language: track.language || null,
    isDefault: false,
    isSelected: track.mode === "showing"
  }));
}

function getFiniteDuration(video: HTMLVideoElement): number | null {
  return Number.isFinite(video.duration) && video.duration > 0 ? video.duration : null;
}

function createPlaybackStateFromRequest(request: PlayRequest, status: PlaybackState["status"]): PlaybackState {
  return {
    ...createIdleState(),
    status,
    itemId: request.itemId,
    itemType: request.itemType
  };
}

function createPlaybackStateFromSource(source: ResolvedPlaybackSource, status: PlaybackState["status"]): PlaybackState {
  return {
    ...createIdleState(),
    status,
    itemId: source.itemId,
    itemType: source.itemType,
    title: source.title,
    isSeekable: !source.isLive
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
    audioTracks: [],
    subtitleTracks: [],
    selectedAudioTrackId: null,
    selectedSubtitleTrackId: null,
    errorMessage: null
  };
}

function safeMediaCall(callback: () => void): void {
  try {
    callback();
  } catch {
    // jsdom does not implement media methods; real browser failures are surfaced by media events.
  }
}
