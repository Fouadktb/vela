export type AppErrorCode =
  | "provider.invalidCredentials"
  | "provider.unreachable"
  | "provider.emptyCatalog"
  | "provider.parseFailed"
  | "playback.noPlayableStream"
  | "playback.mpvUnavailable"
  | "playback.externalPlayerMissing"
  | "storage.failure";

export interface AppErrorShape {
  code: AppErrorCode;
  message: string;
  actionLabel: string | null;
}

export function createAppError(
  code: AppErrorCode,
  message: string,
  actionLabel: string | null = null
): AppErrorShape {
  return { code, message, actionLabel };
}
