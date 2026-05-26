import type { IptvApi } from "../../shared/ipc/types";

declare global {
  interface Window {
    iptv?: IptvApi;
  }
}

export function getIptvApi(): IptvApi {
  if (!window.iptv) {
    throw new Error("IPTV preload API is unavailable");
  }

  return window.iptv;
}

export const iptvApi = getIptvApi();
