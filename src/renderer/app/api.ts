import type { IptvApi } from "../../shared/ipc/types";

declare global {
  interface Window {
    iptv: IptvApi;
  }
}

export const iptvApi = window.iptv;
