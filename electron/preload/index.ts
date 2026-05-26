import { contextBridge } from "electron";

contextBridge.exposeInMainWorld("iptv", {
  version: "0.1.0"
});
