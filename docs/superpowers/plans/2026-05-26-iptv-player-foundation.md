# IPTV Player Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first working desktop vertical slice: Electron + React app shell, typed IPC, SQLite storage, M3U import, searchable catalog UI, and managed mpv playback foundation.

**Architecture:** Electron main owns privileged work: windows, IPC, SQLite, imports, and mpv process control. React renderer owns navigation, provider setup, catalog browsing, and playback controls through a typed preload API. Shared TypeScript types define the catalog, provider, playback, and error contracts.

**Tech Stack:** Electron, React, TypeScript, Vite, electron-builder, Vitest, Testing Library, SQLite via better-sqlite3, lucide-react, mpv controlled through JSON IPC.

---

## Scope

This plan implements the first foundation slice from `docs/superpowers/specs/2026-05-26-iptv-player-design.md`.

Included:

- Desktop project scaffold.
- Typed shared domain model.
- Electron main/preload/renderer boundary.
- SQLite schema and repositories.
- M3U parser and import service.
- Provider setup flow for M3U URL/file.
- Live TV catalog browsing, search, filters, favorites, and recently watched basics.
- Managed mpv process controller with command construction and IPC formatting.
- Playback UI controls, 10-second seek gestures, and external player launch command path.
- Local manual build scripts for macOS and Windows.

Not included in this first foundation plan:

- Xtream Codes adapter.
- Movies and series catalog UI.
- Episode selector implementation.
- EPG import.
- App signing, notarization, auto-update, or GitHub Actions releases.

Those items should get follow-up plans after this vertical slice is working.

## File Structure

Create or modify these files:

```text
package.json
pnpm-lock.yaml
tsconfig.json
tsconfig.node.json
vite.config.ts
vitest.config.ts
electron-builder.yml
index.html
electron/main/index.ts
electron/main/windows/createMainWindow.ts
electron/main/ipc/registerIpcHandlers.ts
electron/main/storage/database.ts
electron/main/storage/providerRepository.ts
electron/main/storage/catalogRepository.ts
electron/main/imports/importM3uProvider.ts
electron/main/playback/mpvController.ts
electron/main/playback/externalPlayer.ts
electron/preload/index.ts
src/shared/catalog/types.ts
src/shared/providers/types.ts
src/shared/playback/types.ts
src/shared/ipc/types.ts
src/shared/errors/appError.ts
src/providers/m3u/parseM3u.ts
src/providers/m3u/parseM3u.test.ts
src/storage/catalogRepository.test.ts
src/playback/mpvController.test.ts
src/renderer/main.tsx
src/renderer/app/App.tsx
src/renderer/app/api.ts
src/renderer/app/useAppData.ts
src/renderer/components/Sidebar.tsx
src/renderer/components/SearchBar.tsx
src/renderer/features/providers/ProviderSetup.tsx
src/renderer/features/live/LiveCatalog.tsx
src/renderer/features/live/LiveDetailPane.tsx
src/renderer/features/playback/PlayerControls.tsx
src/renderer/features/playback/playerGestures.ts
src/renderer/features/playback/playerGestures.test.ts
src/renderer/styles/global.css
scripts/check-mpv.js
docs/release-checklist.md
```

Keep files focused. If a file grows beyond its named responsibility during implementation, split it before adding more behavior.

## Task 1: Scaffold Desktop App

**Files:**

- Create: `package.json`
- Create: `tsconfig.json`
- Create: `tsconfig.node.json`
- Create: `vite.config.ts`
- Create: `vitest.config.ts`
- Create: `electron-builder.yml`
- Create: `index.html`
- Create: `electron/main/index.ts`
- Create: `electron/main/windows/createMainWindow.ts`
- Create: `electron/preload/index.ts`
- Create: `src/renderer/main.tsx`
- Create: `src/renderer/app/App.tsx`
- Create: `src/renderer/styles/global.css`

- [ ] **Step 1: Create package manifest**

Create `package.json`:

```json
{
  "name": "iptv-player",
  "version": "0.1.0",
  "description": "Desktop IPTV player for macOS and Windows",
  "private": true,
  "type": "module",
  "main": "dist-electron/main/index.js",
  "scripts": {
    "dev": "vite --host 127.0.0.1",
    "dev:electron": "concurrently -k \"pnpm dev\" \"wait-on http://127.0.0.1:5173 && cross-env VITE_DEV_SERVER_URL=http://127.0.0.1:5173 electron .\"",
    "typecheck": "tsc --noEmit && tsc --noEmit -p tsconfig.node.json",
    "test": "vitest run",
    "test:watch": "vitest",
    "build:renderer": "vite build",
    "build:main": "tsc -p tsconfig.node.json",
    "build": "pnpm typecheck && pnpm test && pnpm build:renderer && pnpm build:main",
    "build:mac": "pnpm build && electron-builder --mac",
    "build:win": "pnpm build && electron-builder --win",
    "check:mpv": "node scripts/check-mpv.js"
  },
  "dependencies": {
    "@vitejs/plugin-react": "^5.0.0",
    "better-sqlite3": "^11.10.0",
    "electron-store": "^10.0.0",
    "lucide-react": "^0.468.0",
    "react": "^19.0.0",
    "react-dom": "^19.0.0"
  },
  "devDependencies": {
    "@testing-library/jest-dom": "^6.6.0",
    "@testing-library/react": "^16.1.0",
    "@types/better-sqlite3": "^7.6.0",
    "@types/node": "^22.10.0",
    "@types/react": "^19.0.0",
    "@types/react-dom": "^19.0.0",
    "@vitest/coverage-v8": "^2.1.0",
    "concurrently": "^9.1.0",
    "cross-env": "^7.0.0",
    "electron": "^33.2.0",
    "electron-builder": "^25.1.0",
    "jsdom": "^25.0.0",
    "typescript": "^5.7.0",
    "vite": "^6.0.0",
    "vitest": "^2.1.0",
    "wait-on": "^8.0.0"
  },
  "build": {
    "appId": "com.fouadktb.iptvplayer",
    "productName": "IPTV Player"
  }
}
```

- [ ] **Step 2: Install dependencies**

Run:

```bash
corepack enable
pnpm install
```

Expected: `pnpm-lock.yaml` is created and install exits with code 0.

- [ ] **Step 3: Add TypeScript configs**

Create `tsconfig.json`:

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "useDefineForClassFields": true,
    "lib": ["DOM", "DOM.Iterable", "ES2022"],
    "allowJs": false,
    "skipLibCheck": true,
    "esModuleInterop": true,
    "allowSyntheticDefaultImports": true,
    "strict": true,
    "forceConsistentCasingInFileNames": true,
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",
    "types": ["vitest/globals", "@testing-library/jest-dom"]
  },
  "include": ["src", "electron/preload", "vite.config.ts", "vitest.config.ts"]
}
```

Create `tsconfig.node.json`:

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "outDir": "dist-electron",
    "rootDir": ".",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "types": ["node", "electron"]
  },
  "include": ["electron/main/**/*.ts", "electron/preload/**/*.ts", "src/shared/**/*.ts", "src/providers/**/*.ts"]
}
```

- [ ] **Step 4: Add Vite and Vitest configs**

Create `vite.config.ts`:

```ts
import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";

export default defineConfig({
  plugins: [react()],
  root: ".",
  base: "./",
  build: {
    outDir: "dist",
    emptyOutDir: true
  },
  server: {
    host: "127.0.0.1",
    port: 5173
  }
});
```

Create `vitest.config.ts`:

```ts
import react from "@vitejs/plugin-react";
import { defineConfig } from "vitest/config";

export default defineConfig({
  plugins: [react()],
  test: {
    environment: "jsdom",
    globals: true,
    include: ["src/**/*.test.ts", "src/**/*.test.tsx"],
    coverage: {
      provider: "v8",
      reporter: ["text", "html"]
    }
  }
});
```

- [ ] **Step 5: Add electron-builder config**

Create `electron-builder.yml`:

```yaml
appId: com.fouadktb.iptvplayer
productName: IPTV Player
directories:
  output: release
files:
  - dist/**
  - dist-electron/**
  - package.json
mac:
  target:
    - dmg
    - zip
win:
  target:
    - nsis
nsis:
  oneClick: false
  perMachine: false
  allowToChangeInstallationDirectory: true
```

- [ ] **Step 6: Add HTML entry**

Create `index.html`:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>IPTV Player</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/renderer/main.tsx"></script>
  </body>
</html>
```

- [ ] **Step 7: Add Electron main window creation**

Create `electron/main/windows/createMainWindow.ts`:

```ts
import { BrowserWindow } from "electron";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

export function createMainWindow(): BrowserWindow {
  const preloadPath = path.join(__dirname, "../preload/index.js");

  const window = new BrowserWindow({
    width: 1280,
    height: 820,
    minWidth: 980,
    minHeight: 640,
    title: "IPTV Player",
    backgroundColor: "#111111",
    webPreferences: {
      preload: preloadPath,
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: false
    }
  });

  const devServerUrl = process.env.VITE_DEV_SERVER_URL;
  if (devServerUrl) {
    void window.loadURL(devServerUrl);
    window.webContents.openDevTools({ mode: "detach" });
  } else {
    void window.loadFile(path.join(__dirname, "../../dist/index.html"));
  }

  return window;
}
```

Create `electron/main/index.ts`:

```ts
import { app } from "electron";
import { createMainWindow } from "./windows/createMainWindow.js";

app.setName("IPTV Player");

async function boot(): Promise<void> {
  await app.whenReady();
  createMainWindow();

  app.on("activate", () => {
    if (app.getAllWindows().length === 0) {
      createMainWindow();
    }
  });
}

app.on("window-all-closed", () => {
  if (process.platform !== "darwin") {
    app.quit();
  }
});

void boot();
```

- [ ] **Step 8: Add minimal preload**

Create `electron/preload/index.ts`:

```ts
import { contextBridge } from "electron";

contextBridge.exposeInMainWorld("iptv", {
  version: "0.1.0"
});
```

- [ ] **Step 9: Add renderer entry and styles**

Create `src/renderer/main.tsx`:

```tsx
import React from "react";
import { createRoot } from "react-dom/client";
import { App } from "./app/App";
import "./styles/global.css";

createRoot(document.getElementById("root") as HTMLElement).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
```

Create `src/renderer/app/App.tsx`:

```tsx
export function App() {
  return (
    <main className="app-shell">
      <aside className="sidebar">
        <div className="brand">IPTV Player</div>
      </aside>
      <section className="content">
        <h1>Desktop IPTV Player</h1>
        <p>Foundation shell is running.</p>
      </section>
    </main>
  );
}
```

Create `src/renderer/styles/global.css`:

```css
:root {
  color: #f4f4f1;
  background: #101010;
  font-family:
    Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI",
    sans-serif;
}

* {
  box-sizing: border-box;
}

body {
  margin: 0;
  min-width: 980px;
  min-height: 640px;
}

button,
input {
  font: inherit;
}

.app-shell {
  min-height: 100vh;
  display: grid;
  grid-template-columns: 232px 1fr;
  background: #f4f4f1;
  color: #151515;
}

.sidebar {
  background: #181818;
  color: #f7f7f7;
  padding: 20px;
}

.brand {
  font-size: 18px;
  font-weight: 700;
}

.content {
  padding: 28px;
}
```

- [ ] **Step 10: Verify scaffold**

Run:

```bash
pnpm typecheck
pnpm test
pnpm build
```

Expected:

- `pnpm typecheck` exits 0.
- `pnpm test` exits 0 with no tests found or passing tests, depending on Vitest behavior.
- `pnpm build` exits 0 and creates `dist/` and `dist-electron/`.

- [ ] **Step 11: Commit scaffold**

```bash
git add package.json pnpm-lock.yaml tsconfig.json tsconfig.node.json vite.config.ts vitest.config.ts electron-builder.yml index.html electron src
git commit -m "feat: scaffold desktop app"
```

## Task 2: Add Shared Domain And Typed IPC Contracts

**Files:**

- Create: `src/shared/catalog/types.ts`
- Create: `src/shared/providers/types.ts`
- Create: `src/shared/playback/types.ts`
- Create: `src/shared/errors/appError.ts`
- Create: `src/shared/ipc/types.ts`
- Modify: `electron/preload/index.ts`
- Create: `src/renderer/app/api.ts`

- [ ] **Step 1: Add catalog types**

Create `src/shared/catalog/types.ts`:

```ts
export type CatalogItemType = "live" | "movie" | "series" | "episode";
export type PlayableCatalogItemType = Exclude<CatalogItemType, "series">;

export interface StreamResolverData {
  providerType: "m3u" | "xtream";
  url?: string;
  streamId?: string;
  containerExtension?: string;
}

export interface LiveChannel {
  type: "live";
  id: string;
  providerId: string;
  name: string;
  logoUrl: string | null;
  category: string;
  stream: StreamResolverData;
  epgChannelId: string | null;
  lastSeenAt: string;
  isFavorite: boolean;
}

export interface Movie {
  type: "movie";
  id: string;
  providerId: string;
  title: string;
  posterUrl: string | null;
  category: string;
  year: number | null;
  rating: string | null;
  stream: StreamResolverData;
  lastSeenAt: string;
  isFavorite: boolean;
}

export interface Series {
  type: "series";
  id: string;
  providerId: string;
  title: string;
  posterUrl: string | null;
  category: string;
  lastSeenAt: string;
  isFavorite: boolean;
}

export interface Episode {
  type: "episode";
  id: string;
  providerId: string;
  seriesId: string;
  seasonNumber: number;
  episodeNumber: number;
  title: string;
  durationSeconds: number | null;
  progressSeconds: number;
  stream: StreamResolverData;
}

export type CatalogItem = LiveChannel | Movie | Series | Episode;
```

- [ ] **Step 2: Add provider types**

Create `src/shared/providers/types.ts`:

```ts
export type ProviderType = "m3u" | "xtream";

export interface Provider {
  id: string;
  type: ProviderType;
  name: string;
  source: string;
  username: string | null;
  password: string | null;
  createdAt: string;
  updatedAt: string;
  lastRefreshAt: string | null;
}

export interface ProviderSummary {
  id: string;
  type: ProviderType;
  name: string;
  createdAt: string;
  updatedAt: string;
  lastRefreshAt: string | null;
}

export function toProviderSummary(provider: Provider): ProviderSummary {
  return {
    id: provider.id,
    type: provider.type,
    name: provider.name,
    createdAt: provider.createdAt,
    updatedAt: provider.updatedAt,
    lastRefreshAt: provider.lastRefreshAt
  };
}

export interface CreateM3uProviderInput {
  name: string;
  source: string;
  sourceKind: "url" | "file";
}

export interface ImportProgress {
  providerId: string;
  phase: "fetching" | "parsing" | "saving" | "complete" | "failed";
  message: string;
  current: number;
  total: number;
}
```

- [ ] **Step 3: Add playback types**

Create `src/shared/playback/types.ts`:

```ts
import type { PlayableCatalogItemType } from "../catalog/types";

export interface PlayRequest {
  itemType: PlayableCatalogItemType;
  itemId: string;
}

export type PlaybackStatus = "idle" | "loading" | "playing" | "paused" | "error";

export interface PlaybackState {
  status: PlaybackStatus;
  itemId: string | null;
  itemType: PlayableCatalogItemType | null;
  title: string | null;
  positionSeconds: number;
  durationSeconds: number | null;
  isSeekable: boolean;
  errorMessage: string | null;
}

export interface SeekRequest {
  offsetSeconds: number;
}
```

- [ ] **Step 4: Add app error type**

Create `src/shared/errors/appError.ts`:

```ts
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
```

- [ ] **Step 5: Add IPC contract**

Create `src/shared/ipc/types.ts`:

```ts
import type { LiveChannel } from "../catalog/types";
import type { PlayRequest, PlaybackState, SeekRequest } from "../playback/types";
import type { CreateM3uProviderInput, ImportProgress, ProviderSummary } from "../providers/types";

export interface IptvApi {
  providers: {
    list(): Promise<ProviderSummary[]>;
    createM3u(input: CreateM3uProviderInput): Promise<ProviderSummary>;
    refresh(providerId: string): Promise<void>;
    onImportProgress(callback: (progress: ImportProgress) => void): () => void;
  };
  catalog: {
    listLiveChannels(query: string, category: string | null): Promise<LiveChannel[]>;
    toggleFavorite(itemId: string, itemType: "live"): Promise<void>;
  };
  playback: {
    play(request: PlayRequest): Promise<void>;
    pause(): Promise<void>;
    stop(): Promise<void>;
    seek(request: SeekRequest): Promise<void>;
    openExternal(request: PlayRequest): Promise<void>;
    getState(): Promise<PlaybackState>;
    onState(callback: (state: PlaybackState) => void): () => void;
  };
}

export const ipcChannels = {
  providersList: "providers:list",
  providersCreateM3u: "providers:createM3u",
  providersRefresh: "providers:refresh",
  providersImportProgress: "providers:importProgress",
  catalogListLiveChannels: "catalog:listLiveChannels",
  catalogToggleFavorite: "catalog:toggleFavorite",
  playbackPlay: "playback:play",
  playbackPause: "playback:pause",
  playbackStop: "playback:stop",
  playbackSeek: "playback:seek",
  playbackOpenExternal: "playback:openExternal",
  playbackGetState: "playback:getState",
  playbackState: "playback:state"
} as const;
```

- [ ] **Step 6: Expose typed preload API**

Replace `electron/preload/index.ts`:

```ts
import { contextBridge, ipcRenderer } from "electron";
import { ipcChannels, type IptvApi } from "../../src/shared/ipc/types.js";
import type { ImportProgress } from "../../src/shared/providers/types.js";
import type { PlaybackState } from "../../src/shared/playback/types.js";

const api: IptvApi = {
  providers: {
    list: () => ipcRenderer.invoke(ipcChannels.providersList),
    createM3u: (input) => ipcRenderer.invoke(ipcChannels.providersCreateM3u, input),
    refresh: (providerId) => ipcRenderer.invoke(ipcChannels.providersRefresh, providerId),
    onImportProgress: (callback) => {
      const listener = (_event: Electron.IpcRendererEvent, progress: ImportProgress) => callback(progress);
      ipcRenderer.on(ipcChannels.providersImportProgress, listener);
      return () => ipcRenderer.off(ipcChannels.providersImportProgress, listener);
    }
  },
  catalog: {
    listLiveChannels: (query, category) =>
      ipcRenderer.invoke(ipcChannels.catalogListLiveChannels, { query, category }),
    toggleFavorite: (itemId, itemType) =>
      ipcRenderer.invoke(ipcChannels.catalogToggleFavorite, { itemId, itemType })
  },
  playback: {
    play: (request) => ipcRenderer.invoke(ipcChannels.playbackPlay, request),
    pause: () => ipcRenderer.invoke(ipcChannels.playbackPause),
    stop: () => ipcRenderer.invoke(ipcChannels.playbackStop),
    seek: (request) => ipcRenderer.invoke(ipcChannels.playbackSeek, request),
    openExternal: (request) => ipcRenderer.invoke(ipcChannels.playbackOpenExternal, request),
    getState: () => ipcRenderer.invoke(ipcChannels.playbackGetState),
    onState: (callback) => {
      const listener = (_event: Electron.IpcRendererEvent, state: PlaybackState) => callback(state);
      ipcRenderer.on(ipcChannels.playbackState, listener);
      return () => ipcRenderer.off(ipcChannels.playbackState, listener);
    }
  }
};

contextBridge.exposeInMainWorld("iptv", api);
```

- [ ] **Step 7: Add renderer API type bridge**

Create `src/renderer/app/api.ts`:

```ts
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
```

- [ ] **Step 8: Run typecheck**

Run:

```bash
pnpm typecheck
```

Expected: TypeScript passes with the shared IPC contracts available to both preload and renderer.

- [ ] **Step 9: Commit shared contracts**

```bash
git add electron/preload src/shared src/renderer/app/api.ts tsconfig.node.json
git commit -m "feat: add typed IPC contracts"
```

## Task 3: Implement M3U Parser With Tests

**Files:**

- Create: `src/providers/m3u/parseM3u.ts`
- Create: `src/providers/m3u/parseM3u.test.ts`

- [ ] **Step 1: Write failing parser tests**

Create `src/providers/m3u/parseM3u.test.ts`:

```ts
import { describe, expect, it } from "vitest";
import { parseM3u } from "./parseM3u";

describe("parseM3u", () => {
  it("parses extended M3U channels into normalized channel drafts", () => {
    const input = `#EXTM3U
#EXTINF:-1 tvg-id="bbc.one" tvg-logo="https://logo.test/bbc.png" group-title="News",BBC One
https://stream.test/bbc.m3u8
#EXTINF:-1 tvg-id="sky.sports" group-title="Sports",Sky Sports
https://stream.test/sky.ts`;

    const result = parseM3u(input, {
      providerId: "provider-1",
      nowIso: "2026-05-26T12:00:00.000Z"
    });

    expect(result.channels).toHaveLength(2);
    expect(result.channels[0]).toMatchObject({
      id: "provider-1:live:bbc-one",
      providerId: "provider-1",
      name: "BBC One",
      logoUrl: "https://logo.test/bbc.png",
      category: "News",
      epgChannelId: "bbc.one",
      stream: {
        providerType: "m3u",
        url: "https://stream.test/bbc.m3u8"
      },
      lastSeenAt: "2026-05-26T12:00:00.000Z"
    });
    expect(result.channels[1].category).toBe("Sports");
    expect(result.diagnostics).toEqual([]);
  });

  it("skips malformed entries and records diagnostics", () => {
    const input = `#EXTM3U
#EXTINF:-1 group-title="News",No URL
#EXTINF:-1,Valid Channel
https://stream.test/valid.m3u8`;

    const result = parseM3u(input, {
      providerId: "provider-1",
      nowIso: "2026-05-26T12:00:00.000Z"
    });

    expect(result.channels).toHaveLength(1);
    expect(result.channels[0].name).toBe("Valid Channel");
    expect(result.diagnostics).toContainEqual({
      line: 2,
      message: "EXTINF entry has no following stream URL"
    });
  });
});
```

- [ ] **Step 2: Run parser tests to verify failure**

Run:

```bash
pnpm vitest run src/providers/m3u/parseM3u.test.ts
```

Expected: FAIL because `src/providers/m3u/parseM3u.ts` does not exist.

- [ ] **Step 3: Implement parser**

Create `src/providers/m3u/parseM3u.ts`:

```ts
import type { LiveChannel } from "../../shared/catalog/types";

interface ParseM3uOptions {
  providerId: string;
  nowIso: string;
}

interface ParseDiagnostic {
  line: number;
  message: string;
}

interface ParseM3uResult {
  channels: LiveChannel[];
  diagnostics: ParseDiagnostic[];
}

interface ExtInfDraft {
  line: number;
  name: string;
  attributes: Record<string, string>;
}

export function parseM3u(input: string, options: ParseM3uOptions): ParseM3uResult {
  const lines = input.split(/\r?\n/);
  const diagnostics: ParseDiagnostic[] = [];
  const channels: LiveChannel[] = [];
  let pending: ExtInfDraft | null = null;

  lines.forEach((rawLine, index) => {
    const lineNumber = index + 1;
    const line = rawLine.trim();

    if (!line || line === "#EXTM3U") {
      return;
    }

    if (line.startsWith("#EXTINF:")) {
      if (pending) {
        diagnostics.push({
          line: pending.line,
          message: "EXTINF entry has no following stream URL"
        });
      }
      pending = parseExtInf(line, lineNumber);
      return;
    }

    if (line.startsWith("#")) {
      return;
    }

    if (!pending) {
      diagnostics.push({
        line: lineNumber,
        message: "Stream URL has no preceding EXTINF metadata"
      });
      return;
    }

    channels.push(toLiveChannel(pending, line, options));
    pending = null;
  });

  if (pending) {
    diagnostics.push({
      line: pending.line,
      message: "EXTINF entry has no following stream URL"
    });
  }

  return { channels, diagnostics };
}

function parseExtInf(line: string, lineNumber: number): ExtInfDraft {
  const commaIndex = line.lastIndexOf(",");
  const metadata = commaIndex >= 0 ? line.slice(0, commaIndex) : line;
  const name = commaIndex >= 0 ? line.slice(commaIndex + 1).trim() : "Unnamed Channel";
  const attributes: Record<string, string> = {};

  for (const match of metadata.matchAll(/([\w-]+)="([^"]*)"/g)) {
    attributes[match[1]] = match[2];
  }

  return {
    line: lineNumber,
    name: name || "Unnamed Channel",
    attributes
  };
}

function toLiveChannel(draft: ExtInfDraft, url: string, options: ParseM3uOptions): LiveChannel {
  const slug = slugify(draft.name);

  return {
    type: "live",
    id: `${options.providerId}:live:${slug}`,
    providerId: options.providerId,
    name: draft.name,
    logoUrl: draft.attributes["tvg-logo"] || null,
    category: draft.attributes["group-title"] || "Uncategorized",
    stream: {
      providerType: "m3u",
      url
    },
    epgChannelId: draft.attributes["tvg-id"] || null,
    lastSeenAt: options.nowIso,
    isFavorite: false
  };
}

function slugify(value: string): string {
  return value
    .toLowerCase()
    .normalize("NFKD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 80);
}
```

- [ ] **Step 4: Verify parser tests pass**

Run:

```bash
pnpm vitest run src/providers/m3u/parseM3u.test.ts
```

Expected: PASS, 2 tests.

- [ ] **Step 5: Commit parser**

```bash
git add src/providers/m3u
git commit -m "feat: add M3U parser"
```

## Task 4: Add SQLite Storage And Repository Tests

**Files:**

- Create: `electron/main/storage/database.ts`
- Create: `electron/main/storage/providerRepository.ts`
- Create: `electron/main/storage/catalogRepository.ts`
- Create: `src/storage/catalogRepository.test.ts`
- Modify: `vitest.config.ts`

- [ ] **Step 1: Update test include for Electron storage tests**

Modify `vitest.config.ts`:

```ts
import react from "@vitejs/plugin-react";
import { defineConfig } from "vitest/config";

export default defineConfig({
  plugins: [react()],
  test: {
    environment: "jsdom",
    globals: true,
    include: ["src/**/*.test.ts", "src/**/*.test.tsx"],
    coverage: {
      provider: "v8",
      reporter: ["text", "html"]
    }
  }
});
```

Keep repository tests under `src/storage` so this include pattern picks them up.

- [ ] **Step 2: Write failing repository test**

Create `src/storage/catalogRepository.test.ts`:

```ts
import Database from "better-sqlite3";
import { describe, expect, it } from "vitest";
import { createSchema } from "../../electron/main/storage/database";
import { createCatalogRepository } from "../../electron/main/storage/catalogRepository";
import type { LiveChannel } from "../shared/catalog/types";

function channel(overrides: Partial<LiveChannel> = {}): LiveChannel {
  return {
    type: "live",
    id: "provider-1:live:bbc-one",
    providerId: "provider-1",
    name: "BBC One",
    logoUrl: null,
    category: "News",
    stream: {
      providerType: "m3u",
      url: "https://stream.test/bbc.m3u8"
    },
    epgChannelId: "bbc.one",
    lastSeenAt: "2026-05-26T12:00:00.000Z",
    isFavorite: false,
    ...overrides
  };
}

describe("catalogRepository", () => {
  it("upserts and searches live channels", () => {
    const db = new Database(":memory:");
    createSchema(db);
    const repo = createCatalogRepository(db);

    repo.upsertLiveChannels([channel()]);

    expect(repo.listLiveChannels("", null)).toHaveLength(1);
    expect(repo.listLiveChannels("bbc", null)[0].name).toBe("BBC One");
    expect(repo.listLiveChannels("", "News")).toHaveLength(1);
    expect(repo.listLiveChannels("", "Sports")).toHaveLength(0);
  });

  it("preserves favorites when channels are refreshed", () => {
    const db = new Database(":memory:");
    createSchema(db);
    const repo = createCatalogRepository(db);

    repo.upsertLiveChannels([channel()]);
    repo.toggleFavorite("provider-1:live:bbc-one", "live");
    repo.upsertLiveChannels([channel({ name: "BBC One HD" })]);

    expect(repo.listLiveChannels("bbc", null)[0]).toMatchObject({
      name: "BBC One HD",
      isFavorite: true
    });
  });
});
```

- [ ] **Step 3: Run repository test to verify failure**

Run:

```bash
pnpm vitest run src/storage/catalogRepository.test.ts
```

Expected: FAIL because `database.ts` and `catalogRepository.ts` do not exist.

- [ ] **Step 4: Implement database schema**

Create `electron/main/storage/database.ts`:

```ts
import Database from "better-sqlite3";
import { app } from "electron";
import path from "node:path";

export type SqliteDatabase = Database.Database;

export function openAppDatabase(): SqliteDatabase {
  const dbPath = path.join(app.getPath("userData"), "iptv-player.sqlite");
  const db = new Database(dbPath);
  createSchema(db);
  return db;
}

export function createSchema(db: SqliteDatabase): void {
  db.exec(`
    PRAGMA journal_mode = WAL;

    CREATE TABLE IF NOT EXISTS providers (
      id TEXT PRIMARY KEY,
      type TEXT NOT NULL,
      name TEXT NOT NULL,
      source TEXT NOT NULL,
      username TEXT,
      password TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      last_refresh_at TEXT
    );

    CREATE TABLE IF NOT EXISTS live_channels (
      id TEXT PRIMARY KEY,
      provider_id TEXT NOT NULL,
      name TEXT NOT NULL,
      logo_url TEXT,
      category TEXT NOT NULL,
      stream_json TEXT NOT NULL,
      epg_channel_id TEXT,
      last_seen_at TEXT NOT NULL,
      stale INTEGER NOT NULL DEFAULT 0
    );

    CREATE TABLE IF NOT EXISTS favorites (
      item_id TEXT NOT NULL,
      item_type TEXT NOT NULL,
      created_at TEXT NOT NULL,
      PRIMARY KEY (item_id, item_type)
    );

    CREATE TABLE IF NOT EXISTS recently_watched (
      item_id TEXT NOT NULL,
      item_type TEXT NOT NULL,
      last_watched_at TEXT NOT NULL,
      PRIMARY KEY (item_id, item_type)
    );

    CREATE INDEX IF NOT EXISTS idx_live_channels_provider ON live_channels(provider_id);
    CREATE INDEX IF NOT EXISTS idx_live_channels_category ON live_channels(category);
    CREATE INDEX IF NOT EXISTS idx_live_channels_name ON live_channels(name);
  `);
}
```

- [ ] **Step 5: Implement provider repository**

Create `electron/main/storage/providerRepository.ts`:

```ts
import crypto from "node:crypto";
import type { Provider, CreateM3uProviderInput } from "../../../src/shared/providers/types";
import type { SqliteDatabase } from "./database";

interface ProviderRow {
  id: string;
  type: "m3u" | "xtream";
  name: string;
  source: string;
  username: string | null;
  password: string | null;
  created_at: string;
  updated_at: string;
  last_refresh_at: string | null;
}

export function createProviderRepository(db: SqliteDatabase) {
  return {
    list(): Provider[] {
      const rows = db.prepare("SELECT * FROM providers ORDER BY created_at ASC").all() as ProviderRow[];
      return rows.map(toProvider);
    },
    createM3u(input: CreateM3uProviderInput): Provider {
      const now = new Date().toISOString();
      const provider: Provider = {
        id: crypto.randomUUID(),
        type: "m3u",
        name: input.name,
        source: input.source,
        username: null,
        password: null,
        createdAt: now,
        updatedAt: now,
        lastRefreshAt: null
      };

      db.prepare(`
        INSERT INTO providers (id, type, name, source, username, password, created_at, updated_at, last_refresh_at)
        VALUES (@id, @type, @name, @source, @username, @password, @createdAt, @updatedAt, @lastRefreshAt)
      `).run(provider);

      return provider;
    },
    markRefreshed(providerId: string): void {
      const now = new Date().toISOString();
      db.prepare("UPDATE providers SET last_refresh_at = ?, updated_at = ? WHERE id = ?").run(now, now, providerId);
    },
    get(providerId: string): Provider | null {
      const row = db.prepare("SELECT * FROM providers WHERE id = ?").get(providerId) as ProviderRow | undefined;
      return row ? toProvider(row) : null;
    }
  };
}

function toProvider(row: ProviderRow): Provider {
  return {
    id: row.id,
    type: row.type,
    name: row.name,
    source: row.source,
    username: row.username,
    password: row.password,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
    lastRefreshAt: row.last_refresh_at
  };
}
```

- [ ] **Step 6: Implement catalog repository**

Create `electron/main/storage/catalogRepository.ts`:

```ts
import type { LiveChannel } from "../../../src/shared/catalog/types";
import type { SqliteDatabase } from "./database";

interface LiveChannelRow {
  id: string;
  provider_id: string;
  name: string;
  logo_url: string | null;
  category: string;
  stream_json: string;
  epg_channel_id: string | null;
  last_seen_at: string;
  is_favorite: 0 | 1;
}

export function createCatalogRepository(db: SqliteDatabase) {
  return {
    upsertLiveChannels(channels: LiveChannel[]): void {
      const statement = db.prepare(`
        INSERT INTO live_channels (
          id, provider_id, name, logo_url, category, stream_json, epg_channel_id, last_seen_at, stale
        ) VALUES (
          @id, @providerId, @name, @logoUrl, @category, @streamJson, @epgChannelId, @lastSeenAt, 0
        )
        ON CONFLICT(id) DO UPDATE SET
          name = excluded.name,
          logo_url = excluded.logo_url,
          category = excluded.category,
          stream_json = excluded.stream_json,
          epg_channel_id = excluded.epg_channel_id,
          last_seen_at = excluded.last_seen_at,
          stale = 0
      `);

      const transaction = db.transaction((items: LiveChannel[]) => {
        for (const item of items) {
          statement.run({
            id: item.id,
            providerId: item.providerId,
            name: item.name,
            logoUrl: item.logoUrl,
            category: item.category,
            streamJson: JSON.stringify(item.stream),
            epgChannelId: item.epgChannelId,
            lastSeenAt: item.lastSeenAt
          });
        }
      });

      transaction(channels);
    },
    listLiveChannels(query: string, category: string | null): LiveChannel[] {
      const normalizedQuery = `%${query.trim().toLowerCase()}%`;
      const rows = db.prepare(`
        SELECT
          live_channels.*,
          CASE WHEN favorites.item_id IS NULL THEN 0 ELSE 1 END AS is_favorite
        FROM live_channels
        LEFT JOIN favorites
          ON favorites.item_id = live_channels.id
          AND favorites.item_type = 'live'
        WHERE stale = 0
          AND lower(name) LIKE ?
          AND (? IS NULL OR category = ?)
        ORDER BY is_favorite DESC, name ASC
      `).all(normalizedQuery, category, category) as LiveChannelRow[];

      return rows.map(toLiveChannel);
    },
    getLiveChannel(itemId: string): LiveChannel | null {
      const row = db.prepare(`
        SELECT
          live_channels.*,
          CASE WHEN favorites.item_id IS NULL THEN 0 ELSE 1 END AS is_favorite
        FROM live_channels
        LEFT JOIN favorites
          ON favorites.item_id = live_channels.id
          AND favorites.item_type = 'live'
        WHERE live_channels.id = ?
      `).get(itemId) as LiveChannelRow | undefined;

      return row ? toLiveChannel(row) : null;
    },
    toggleFavorite(itemId: string, itemType: "live"): void {
      const existing = db.prepare("SELECT item_id FROM favorites WHERE item_id = ? AND item_type = ?").get(itemId, itemType);

      if (existing) {
        db.prepare("DELETE FROM favorites WHERE item_id = ? AND item_type = ?").run(itemId, itemType);
        return;
      }

      db.prepare("INSERT INTO favorites (item_id, item_type, created_at) VALUES (?, ?, ?)").run(
        itemId,
        itemType,
        new Date().toISOString()
      );
    },
    markRecentlyWatched(itemId: string, itemType: "live"): void {
      db.prepare(`
        INSERT INTO recently_watched (item_id, item_type, last_watched_at)
        VALUES (?, ?, ?)
        ON CONFLICT(item_id, item_type) DO UPDATE SET last_watched_at = excluded.last_watched_at
      `).run(itemId, itemType, new Date().toISOString());
    }
  };
}

function toLiveChannel(row: LiveChannelRow): LiveChannel {
  return {
    type: "live",
    id: row.id,
    providerId: row.provider_id,
    name: row.name,
    logoUrl: row.logo_url,
    category: row.category,
    stream: JSON.parse(row.stream_json) as LiveChannel["stream"],
    epgChannelId: row.epg_channel_id,
    lastSeenAt: row.last_seen_at,
    isFavorite: row.is_favorite === 1
  };
}
```

- [ ] **Step 7: Verify storage tests pass**

Run:

```bash
pnpm vitest run src/storage/catalogRepository.test.ts
```

Expected: PASS, 2 tests.

- [ ] **Step 8: Run full checks**

Run:

```bash
pnpm typecheck
pnpm test
```

Expected: both commands exit 0.

- [ ] **Step 9: Commit storage**

```bash
git add electron/main/storage src/storage/catalogRepository.test.ts vitest.config.ts
git commit -m "feat: add local catalog storage"
```

## Task 5: Add M3U Import Service And IPC Handlers

**Files:**

- Create: `electron/main/imports/importM3uProvider.ts`
- Create: `electron/main/ipc/registerIpcHandlers.ts`
- Modify: `electron/main/index.ts`

- [ ] **Step 1: Implement M3U import service**

Create `electron/main/imports/importM3uProvider.ts`:

```ts
import fs from "node:fs/promises";
import { parseM3u } from "../../../src/providers/m3u/parseM3u.js";
import type { ImportProgress, Provider } from "../../../src/shared/providers/types.js";
import type { createCatalogRepository } from "../storage/catalogRepository.js";
import type { createProviderRepository } from "../storage/providerRepository.js";

interface ImportM3uProviderDeps {
  providerRepository: ReturnType<typeof createProviderRepository>;
  catalogRepository: ReturnType<typeof createCatalogRepository>;
  emitProgress(progress: ImportProgress): void;
}

export async function importM3uProvider(provider: Provider, deps: ImportM3uProviderDeps): Promise<void> {
  deps.emitProgress({
    providerId: provider.id,
    phase: "fetching",
    message: "Loading playlist",
    current: 0,
    total: 3
  });

  const playlist = await loadPlaylist(provider.source);

  deps.emitProgress({
    providerId: provider.id,
    phase: "parsing",
    message: "Parsing playlist",
    current: 1,
    total: 3
  });

  const parsed = parseM3u(playlist, {
    providerId: provider.id,
    nowIso: new Date().toISOString()
  });

  deps.emitProgress({
    providerId: provider.id,
    phase: "saving",
    message: `Saving ${parsed.channels.length} channels`,
    current: 2,
    total: 3
  });

  deps.catalogRepository.upsertLiveChannels(parsed.channels);
  deps.providerRepository.markRefreshed(provider.id);

  deps.emitProgress({
    providerId: provider.id,
    phase: "complete",
    message: `Imported ${parsed.channels.length} channels`,
    current: 3,
    total: 3
  });
}

async function loadPlaylist(source: string): Promise<string> {
  if (/^https?:\/\//i.test(source)) {
    const response = await fetch(source);
    if (!response.ok) {
      throw new Error(`Playlist request failed with HTTP ${response.status}`);
    }
    return response.text();
  }

  return fs.readFile(source, "utf8");
}
```

- [ ] **Step 2: Register IPC handlers**

Create `electron/main/ipc/registerIpcHandlers.ts`:

```ts
import type { BrowserWindow } from "electron";
import { ipcMain } from "electron";
import { ipcChannels } from "../../../src/shared/ipc/types.js";
import { toProviderSummary, type CreateM3uProviderInput } from "../../../src/shared/providers/types.js";
import type { createCatalogRepository } from "../storage/catalogRepository.js";
import type { createProviderRepository } from "../storage/providerRepository.js";
import type { importM3uProvider } from "../imports/importM3uProvider.js";
import type { createMpvController } from "../playback/mpvController.js";
import type { openInExternalPlayer } from "../playback/externalPlayer.js";

interface RegisterIpcHandlersDeps {
  mainWindow: BrowserWindow;
  providerRepository: ReturnType<typeof createProviderRepository>;
  catalogRepository: ReturnType<typeof createCatalogRepository>;
  importM3uProvider: typeof importM3uProvider;
  mpvController: ReturnType<typeof createMpvController>;
  openInExternalPlayer: typeof openInExternalPlayer;
}

export function registerIpcHandlers(deps: RegisterIpcHandlersDeps): void {
  ipcMain.handle(ipcChannels.providersList, () => deps.providerRepository.list().map(toProviderSummary));

  ipcMain.handle(ipcChannels.providersCreateM3u, async (_event, input: CreateM3uProviderInput) => {
    const provider = deps.providerRepository.createM3u(input);
    await deps.importM3uProvider(provider, {
      providerRepository: deps.providerRepository,
      catalogRepository: deps.catalogRepository,
      emitProgress: (progress) => deps.mainWindow.webContents.send(ipcChannels.providersImportProgress, progress)
    });
    return toProviderSummary(provider);
  });

  ipcMain.handle(ipcChannels.providersRefresh, async (_event, providerId: string) => {
    const provider = deps.providerRepository.get(providerId);
    if (!provider) {
      throw new Error(`Provider not found: ${providerId}`);
    }
    if (provider.type === "m3u") {
      await deps.importM3uProvider(provider, {
        providerRepository: deps.providerRepository,
        catalogRepository: deps.catalogRepository,
        emitProgress: (progress) => deps.mainWindow.webContents.send(ipcChannels.providersImportProgress, progress)
      });
    }
  });

  ipcMain.handle(ipcChannels.catalogListLiveChannels, (_event, input: { query: string; category: string | null }) =>
    deps.catalogRepository.listLiveChannels(input.query, input.category)
  );

  ipcMain.handle(ipcChannels.catalogToggleFavorite, (_event, input: { itemId: string; itemType: "live" }) => {
    deps.catalogRepository.toggleFavorite(input.itemId, input.itemType);
  });
}
```

- [ ] **Step 3: Wire storage and IPC in Electron main**

Modify `electron/main/index.ts`:

```ts
import { app } from "electron";
import { importM3uProvider } from "./imports/importM3uProvider.js";
import { registerIpcHandlers } from "./ipc/registerIpcHandlers.js";
import { createMpvController } from "./playback/mpvController.js";
import { openInExternalPlayer } from "./playback/externalPlayer.js";
import { createCatalogRepository } from "./storage/catalogRepository.js";
import { openAppDatabase } from "./storage/database.js";
import { createProviderRepository } from "./storage/providerRepository.js";
import { createMainWindow } from "./windows/createMainWindow.js";

app.setName("IPTV Player");

async function boot(): Promise<void> {
  await app.whenReady();

  const db = openAppDatabase();
  const providerRepository = createProviderRepository(db);
  const catalogRepository = createCatalogRepository(db);
  const mpvController = createMpvController({
    catalogRepository,
    onStateChange: () => undefined
  });

  const mainWindow = createMainWindow();
  registerIpcHandlers({
    mainWindow,
    providerRepository,
    catalogRepository,
    importM3uProvider,
    mpvController,
    openInExternalPlayer
  });

  app.on("activate", () => {
    if (app.getAllWindows().length === 0) {
      createMainWindow();
    }
  });
}

app.on("window-all-closed", () => {
  if (process.platform !== "darwin") {
    app.quit();
  }
});

void boot();
```

- [ ] **Step 4: Add temporary playback stubs to satisfy imports**

Create `electron/main/playback/mpvController.ts`:

```ts
import type { PlaybackState, PlayRequest, SeekRequest } from "../../../src/shared/playback/types";
import type { createCatalogRepository } from "../storage/catalogRepository";

interface CreateMpvControllerOptions {
  catalogRepository: ReturnType<typeof createCatalogRepository>;
  onStateChange(state: PlaybackState): void;
}

export function createMpvController(_options: CreateMpvControllerOptions) {
  const state: PlaybackState = {
    status: "idle",
    itemId: null,
    itemType: null,
    title: null,
    positionSeconds: 0,
    durationSeconds: null,
    isSeekable: false,
    errorMessage: null
  };

  return {
    play(_request: PlayRequest): Promise<void> {
      return Promise.resolve();
    },
    pause(): Promise<void> {
      return Promise.resolve();
    },
    stop(): Promise<void> {
      return Promise.resolve();
    },
    seek(_request: SeekRequest): Promise<void> {
      return Promise.resolve();
    },
    getState(): PlaybackState {
      return state;
    }
  };
}
```

Create `electron/main/playback/externalPlayer.ts`:

```ts
import type { PlayRequest } from "../../../src/shared/playback/types";

export async function openInExternalPlayer(_request: PlayRequest): Promise<void> {
  return Promise.resolve();
}
```

- [ ] **Step 5: Run checks**

Run:

```bash
pnpm typecheck
pnpm test
```

Expected: both commands exit 0.

- [ ] **Step 6: Commit import IPC**

```bash
git add electron/main
git commit -m "feat: add M3U import IPC"
```

## Task 6: Build Provider Setup And Live Catalog UI

**Files:**

- Modify: `src/renderer/app/App.tsx`
- Create: `src/renderer/app/useAppData.ts`
- Create: `src/renderer/components/Sidebar.tsx`
- Create: `src/renderer/components/SearchBar.tsx`
- Create: `src/renderer/features/providers/ProviderSetup.tsx`
- Create: `src/renderer/features/live/LiveCatalog.tsx`
- Create: `src/renderer/features/live/LiveDetailPane.tsx`
- Modify: `src/renderer/styles/global.css`

- [ ] **Step 1: Add app data hook**

Create `src/renderer/app/useAppData.ts`:

```ts
import { useCallback, useEffect, useMemo, useState } from "react";
import type { LiveChannel } from "../../shared/catalog/types";
import type { ProviderSummary } from "../../shared/providers/types";
import { iptvApi } from "./api";

export function useAppData() {
  const [providers, setProviders] = useState<ProviderSummary[]>([]);
  const [channels, setChannels] = useState<LiveChannel[]>([]);
  const [query, setQuery] = useState("");
  const [category, setCategory] = useState<string | null>(null);
  const [selectedChannelId, setSelectedChannelId] = useState<string | null>(null);
  const [statusMessage, setStatusMessage] = useState<string | null>(null);

  const selectedChannel = channels.find((channel) => channel.id === selectedChannelId) ?? channels[0] ?? null;

  const categories = useMemo(
    () => Array.from(new Set(channels.map((channel) => channel.category))).sort((a, b) => a.localeCompare(b)),
    [channels]
  );

  const reloadProviders = useCallback(async () => {
    setProviders(await iptvApi.providers.list());
  }, []);

  const reloadChannels = useCallback(async () => {
    const nextChannels = await iptvApi.catalog.listLiveChannels(query, category);
    setChannels(nextChannels);
    setSelectedChannelId((current) => current ?? nextChannels[0]?.id ?? null);
  }, [category, query]);

  useEffect(() => {
    void reloadProviders();
  }, [reloadProviders]);

  useEffect(() => {
    void reloadChannels();
  }, [reloadChannels]);

  useEffect(() => {
    return iptvApi.providers.onImportProgress((progress) => {
      setStatusMessage(progress.message);
      if (progress.phase === "complete") {
        void reloadProviders();
        void reloadChannels();
      }
    });
  }, [reloadChannels, reloadProviders]);

  return {
    providers,
    channels,
    categories,
    query,
    setQuery,
    category,
    setCategory,
    selectedChannel,
    setSelectedChannelId,
    statusMessage,
    reloadChannels,
    reloadProviders
  };
}
```

- [ ] **Step 2: Add sidebar**

Create `src/renderer/components/Sidebar.tsx`:

```tsx
import { Clock, Heart, MonitorPlay, Settings, Tv, Video } from "lucide-react";

export function Sidebar() {
  return (
    <aside className="sidebar">
      <div className="brand">IPTV Player</div>
      <nav className="sidebar-nav" aria-label="Main navigation">
        <button className="nav-item active" type="button">
          <Tv size={18} /> Live TV
        </button>
        <button className="nav-item" type="button" disabled>
          <Video size={18} /> Movies
        </button>
        <button className="nav-item" type="button" disabled>
          <MonitorPlay size={18} /> Series
        </button>
        <button className="nav-item" type="button" disabled>
          <Heart size={18} /> Favorites
        </button>
        <button className="nav-item" type="button" disabled>
          <Clock size={18} /> Recently Watched
        </button>
        <button className="nav-item" type="button" disabled>
          <Settings size={18} /> Settings
        </button>
      </nav>
    </aside>
  );
}
```

- [ ] **Step 3: Add search bar**

Create `src/renderer/components/SearchBar.tsx`:

```tsx
import { Search } from "lucide-react";

interface SearchBarProps {
  query: string;
  onQueryChange(query: string): void;
}

export function SearchBar({ query, onQueryChange }: SearchBarProps) {
  return (
    <label className="search-bar">
      <Search size={18} />
      <input
        value={query}
        onChange={(event) => onQueryChange(event.target.value)}
        placeholder="Search channels..."
        aria-label="Search channels"
      />
    </label>
  );
}
```

- [ ] **Step 4: Add provider setup**

Create `src/renderer/features/providers/ProviderSetup.tsx`:

```tsx
import { useState } from "react";
import { iptvApi } from "../../app/api";

interface ProviderSetupProps {
  onCreated(): Promise<void>;
}

export function ProviderSetup({ onCreated }: ProviderSetupProps) {
  const [name, setName] = useState("My IPTV");
  const [source, setSource] = useState("");
  const [sourceKind, setSourceKind] = useState<"url" | "file">("url");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function submit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError(null);
    setIsSubmitting(true);
    try {
      await iptvApi.providers.createM3u({ name, source, sourceKind });
      await onCreated();
    } catch (unknownError) {
      setError(unknownError instanceof Error ? unknownError.message : "Provider import failed");
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <form className="provider-setup" onSubmit={submit}>
      <h1>Add M3U Provider</h1>
      <p>Paste an M3U URL or enter a local playlist file path.</p>
      <label>
        Provider name
        <input value={name} onChange={(event) => setName(event.target.value)} required />
      </label>
      <label>
        Source type
        <select value={sourceKind} onChange={(event) => setSourceKind(event.target.value as "url" | "file")}>
          <option value="url">URL</option>
          <option value="file">Local file path</option>
        </select>
      </label>
      <label>
        M3U source
        <input value={source} onChange={(event) => setSource(event.target.value)} required />
      </label>
      {error ? <div className="error">{error}</div> : null}
      <button type="submit" disabled={isSubmitting}>
        {isSubmitting ? "Importing..." : "Import Provider"}
      </button>
    </form>
  );
}
```

- [ ] **Step 5: Add live catalog**

Create `src/renderer/features/live/LiveCatalog.tsx`:

```tsx
import type { LiveChannel } from "../../../shared/catalog/types";

interface LiveCatalogProps {
  channels: LiveChannel[];
  selectedChannelId: string | null;
  onSelect(channelId: string): void;
}

export function LiveCatalog({ channels, selectedChannelId, onSelect }: LiveCatalogProps) {
  if (channels.length === 0) {
    return <div className="empty-state">No channels match the current search.</div>;
  }

  return (
    <div className="catalog-grid">
      {channels.map((channel) => (
        <button
          className={channel.id === selectedChannelId ? "channel-card selected" : "channel-card"}
          key={channel.id}
          type="button"
          onClick={() => onSelect(channel.id)}
        >
          <div className="channel-logo">{channel.logoUrl ? <img src={channel.logoUrl} alt="" /> : channel.name.slice(0, 2)}</div>
          <div>
            <strong>{channel.name}</strong>
            <span>{channel.category}</span>
          </div>
        </button>
      ))}
    </div>
  );
}
```

- [ ] **Step 6: Add detail pane**

Create `src/renderer/features/live/LiveDetailPane.tsx`:

```tsx
import { Heart, Play, RefreshCw } from "lucide-react";
import type { LiveChannel } from "../../../shared/catalog/types";

interface LiveDetailPaneProps {
  channel: LiveChannel | null;
  onPlay(channel: LiveChannel): void;
  onToggleFavorite(channel: LiveChannel): void;
  onRefresh(): void;
}

export function LiveDetailPane({ channel, onPlay, onToggleFavorite, onRefresh }: LiveDetailPaneProps) {
  if (!channel) {
    return <aside className="detail-pane">Select a channel.</aside>;
  }

  return (
    <aside className="detail-pane">
      <div className="poster-frame">{channel.logoUrl ? <img src={channel.logoUrl} alt="" /> : channel.name}</div>
      <h2>{channel.name}</h2>
      <p>{channel.category}</p>
      <div className="detail-actions">
        <button type="button" onClick={() => onPlay(channel)}>
          <Play size={17} /> Play
        </button>
        <button type="button" onClick={() => onToggleFavorite(channel)}>
          <Heart size={17} /> {channel.isFavorite ? "Favorited" : "Favorite"}
        </button>
        <button type="button" onClick={onRefresh}>
          <RefreshCw size={17} /> Refresh
        </button>
      </div>
    </aside>
  );
}
```

- [ ] **Step 7: Wire app shell**

Replace `src/renderer/app/App.tsx`:

```tsx
import { Sidebar } from "../components/Sidebar";
import { SearchBar } from "../components/SearchBar";
import { LiveCatalog } from "../features/live/LiveCatalog";
import { LiveDetailPane } from "../features/live/LiveDetailPane";
import { ProviderSetup } from "../features/providers/ProviderSetup";
import { iptvApi } from "./api";
import { useAppData } from "./useAppData";

export function App() {
  const data = useAppData();

  if (data.providers.length === 0) {
    return (
      <main className="setup-screen">
        <ProviderSetup onCreated={data.reloadProviders} />
      </main>
    );
  }

  return (
    <main className="app-shell">
      <Sidebar />
      <section className="content">
        <header className="toolbar">
          <SearchBar query={data.query} onQueryChange={data.setQuery} />
          {data.statusMessage ? <span className="status-pill">{data.statusMessage}</span> : null}
        </header>
        <div className="category-row">
          <button className={data.category === null ? "chip active" : "chip"} type="button" onClick={() => data.setCategory(null)}>
            All
          </button>
          {data.categories.map((category) => (
            <button
              className={data.category === category ? "chip active" : "chip"}
              key={category}
              type="button"
              onClick={() => data.setCategory(category)}
            >
              {category}
            </button>
          ))}
        </div>
        <div className="main-grid">
          <LiveCatalog
            channels={data.channels}
            selectedChannelId={data.selectedChannel?.id ?? null}
            onSelect={data.setSelectedChannelId}
          />
          <LiveDetailPane
            channel={data.selectedChannel}
            onPlay={(channel) => iptvApi.playback.play({ itemType: "live", itemId: channel.id })}
            onToggleFavorite={async (channel) => {
              await iptvApi.catalog.toggleFavorite(channel.id, "live");
              await data.reloadChannels();
            }}
            onRefresh={async () => {
              const provider = data.providers[0];
              if (provider) {
                await iptvApi.providers.refresh(provider.id);
              }
            }}
          />
        </div>
      </section>
    </main>
  );
}
```

- [ ] **Step 8: Replace global styles**

Replace `src/renderer/styles/global.css` with the CSS below:

```css
:root {
  color: #f4f4f1;
  background: #101010;
  font-family:
    Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI",
    sans-serif;
}

* {
  box-sizing: border-box;
}

body {
  margin: 0;
  min-width: 980px;
  min-height: 640px;
}

button,
input,
select {
  font: inherit;
}

button {
  cursor: pointer;
}

button:disabled {
  cursor: not-allowed;
  opacity: 0.55;
}

.app-shell {
  min-height: 100vh;
  display: grid;
  grid-template-columns: 232px 1fr;
  background: #f4f4f1;
  color: #151515;
}

.sidebar {
  background: #181818;
  color: #f7f7f7;
  padding: 20px;
}

.brand {
  font-size: 18px;
  font-weight: 700;
  margin-bottom: 24px;
}

.sidebar-nav {
  display: grid;
  gap: 8px;
}

.nav-item {
  width: 100%;
  display: flex;
  align-items: center;
  gap: 10px;
  border: 0;
  border-radius: 7px;
  background: transparent;
  color: #d6d6d6;
  padding: 10px;
  text-align: left;
}

.nav-item.active {
  background: #2a2a2a;
  color: #ffffff;
}

.content {
  padding: 22px;
  min-width: 0;
}

.toolbar {
  display: flex;
  gap: 12px;
  align-items: center;
}

.search-bar {
  height: 40px;
  flex: 1;
  display: flex;
  align-items: center;
  gap: 10px;
  background: #ffffff;
  border: 1px solid #d8d8d0;
  border-radius: 7px;
  padding: 0 12px;
}

.search-bar input {
  border: 0;
  outline: 0;
  width: 100%;
}

.status-pill,
.chip {
  border: 1px solid #d8d8d0;
  border-radius: 999px;
  background: #ffffff;
  color: #151515;
  padding: 8px 12px;
  white-space: nowrap;
}

.category-row {
  display: flex;
  gap: 8px;
  overflow-x: auto;
  padding: 16px 0;
}

.chip.active {
  background: #151515;
  color: #ffffff;
}

.main-grid {
  display: grid;
  grid-template-columns: 1fr 320px;
  gap: 18px;
  align-items: start;
}

.catalog-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(210px, 1fr));
  gap: 12px;
}

.channel-card {
  min-height: 86px;
  display: flex;
  gap: 12px;
  align-items: center;
  border: 1px solid #deded6;
  border-radius: 8px;
  background: #ffffff;
  padding: 12px;
  text-align: left;
}

.channel-card.selected {
  border-color: #151515;
  box-shadow: 0 0 0 1px #151515;
}

.channel-card span {
  display: block;
  color: #6d6d68;
  margin-top: 4px;
}

.channel-logo {
  width: 44px;
  height: 44px;
  border-radius: 7px;
  background: #edede8;
  display: grid;
  place-items: center;
  overflow: hidden;
  font-weight: 700;
}

.channel-logo img,
.poster-frame img {
  width: 100%;
  height: 100%;
  object-fit: contain;
}

.detail-pane {
  min-height: 420px;
  border-left: 1px solid #deded6;
  padding-left: 18px;
}

.poster-frame {
  height: 170px;
  border-radius: 8px;
  background: #101010;
  color: #888;
  display: grid;
  place-items: center;
  overflow: hidden;
  margin-bottom: 16px;
}

.detail-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.detail-actions button,
.provider-setup button {
  border: 0;
  border-radius: 7px;
  background: #151515;
  color: #ffffff;
  padding: 10px 12px;
  display: inline-flex;
  align-items: center;
  gap: 8px;
}

.setup-screen {
  min-height: 100vh;
  display: grid;
  place-items: center;
  background: #f4f4f1;
  color: #151515;
}

.provider-setup {
  width: min(520px, calc(100vw - 40px));
  display: grid;
  gap: 14px;
}

.provider-setup label {
  display: grid;
  gap: 6px;
}

.provider-setup input,
.provider-setup select {
  height: 40px;
  border: 1px solid #d8d8d0;
  border-radius: 7px;
  padding: 0 10px;
}

.error {
  color: #9f1d1d;
}

.empty-state {
  border: 1px dashed #c9c9c0;
  border-radius: 8px;
  padding: 28px;
  color: #676762;
}
```

- [ ] **Step 9: Run checks**

Run:

```bash
pnpm typecheck
pnpm test
pnpm build
```

Expected: all commands exit 0.

- [ ] **Step 10: Commit UI**

```bash
git add src/renderer
git commit -m "feat: add live catalog UI"
```

## Task 7: Implement Managed mpv Controller

**Files:**

- Modify: `electron/main/playback/mpvController.ts`
- Modify: `electron/main/playback/externalPlayer.ts`
- Create: `src/playback/mpvController.test.ts`
- Modify: `electron/main/ipc/registerIpcHandlers.ts`
- Modify: `electron/main/index.ts`

- [ ] **Step 1: Write command-construction tests**

Create `src/playback/mpvController.test.ts`:

```ts
import { describe, expect, it } from "vitest";
import { buildMpvArgs, buildMpvIpcCommand } from "../../electron/main/playback/mpvController";
import { buildExternalPlayerArgs } from "../../electron/main/playback/externalPlayer";

describe("mpvController", () => {
  it("builds mpv args with IPC server and stream URL", () => {
    expect(buildMpvArgs({
      ipcPath: "/tmp/iptv-player.sock",
      url: "https://stream.test/live.m3u8",
      title: "BBC One"
    })).toEqual([
      "--force-window=yes",
      "--idle=no",
      "--input-ipc-server=/tmp/iptv-player.sock",
      "--title=BBC One",
      "https://stream.test/live.m3u8"
    ]);
  });

  it("formats seek IPC command", () => {
    expect(buildMpvIpcCommand(["seek", 10, "relative"])).toBe('{"command":["seek",10,"relative"]}\n');
  });

  it("builds external player args", () => {
    expect(buildExternalPlayerArgs("https://stream.test/live.m3u8")).toEqual(["https://stream.test/live.m3u8"]);
  });
});
```

- [ ] **Step 2: Run playback tests to verify failure**

Run:

```bash
pnpm vitest run src/playback/mpvController.test.ts
```

Expected: FAIL because exported helper functions do not exist.

- [ ] **Step 3: Implement mpv controller**

Replace `electron/main/playback/mpvController.ts`:

```ts
import { spawn, type ChildProcessWithoutNullStreams } from "node:child_process";
import net from "node:net";
import os from "node:os";
import path from "node:path";
import type { LiveChannel } from "../../../src/shared/catalog/types";
import type { PlaybackState, PlayRequest, SeekRequest } from "../../../src/shared/playback/types";
import type { createCatalogRepository } from "../storage/catalogRepository";

interface CreateMpvControllerOptions {
  catalogRepository: ReturnType<typeof createCatalogRepository>;
  onStateChange(state: PlaybackState): void;
}

interface BuildMpvArgsInput {
  ipcPath: string;
  url: string;
  title: string;
}

type MpvJsonValue = string | number | boolean | null | MpvJsonValue[];

const idleState: PlaybackState = {
  status: "idle",
  itemId: null,
  itemType: null,
  title: null,
  positionSeconds: 0,
  durationSeconds: null,
  isSeekable: false,
  errorMessage: null
};

export function buildMpvArgs(input: BuildMpvArgsInput): string[] {
  return [
    "--force-window=yes",
    "--idle=no",
    `--input-ipc-server=${input.ipcPath}`,
    `--title=${input.title}`,
    input.url
  ];
}

export function buildMpvIpcCommand(command: MpvJsonValue[]): string {
  return `${JSON.stringify({ command })}\n`;
}

export function createMpvController(options: CreateMpvControllerOptions) {
  let processRef: ChildProcessWithoutNullStreams | null = null;
  let state: PlaybackState = idleState;
  let ipcPath = "";

  function setState(nextState: PlaybackState): void {
    state = nextState;
    options.onStateChange(state);
  }

  async function play(request: PlayRequest): Promise<void> {
    if (request.itemType !== "live") {
      throw new Error(`Unsupported playback item type: ${request.itemType}`);
    }

    const channel = options.catalogRepository.getLiveChannel(request.itemId);
    if (!channel?.stream.url) {
      throw new Error(`No playable stream for item: ${request.itemId}`);
    }

    stopProcess();
    ipcPath = createIpcPath();
    processRef = spawn("mpv", buildMpvArgs({
      ipcPath,
      url: channel.stream.url,
      title: channel.name
    }));

    processRef.once("exit", () => {
      processRef = null;
      setState({ ...idleState });
    });

    processRef.stderr.on("data", (chunk: Buffer) => {
      const message = chunk.toString("utf8");
      if (message.toLowerCase().includes("error")) {
        setState({
          ...state,
          status: "error",
          errorMessage: sanitizeMpvMessage(message)
        });
      }
    });

    options.catalogRepository.markRecentlyWatched(channel.id, "live");
    setState(toPlayingState(channel));
  }

  async function pause(): Promise<void> {
    await sendCommand(["cycle", "pause"]);
    setState({ ...state, status: state.status === "paused" ? "playing" : "paused" });
  }

  async function stop(): Promise<void> {
    stopProcess();
    setState({ ...idleState });
  }

  async function seek(request: SeekRequest): Promise<void> {
    if (!state.isSeekable) {
      return;
    }
    await sendCommand(["seek", request.offsetSeconds, "relative"]);
  }

  async function sendCommand(command: MpvJsonValue[]): Promise<void> {
    if (!ipcPath) {
      return;
    }

    await new Promise<void>((resolve, reject) => {
      const socket = net.createConnection(ipcPath);
      socket.once("connect", () => {
        socket.write(buildMpvIpcCommand(command), () => {
          socket.end();
          resolve();
        });
      });
      socket.once("error", reject);
    });
  }

  function stopProcess(): void {
    if (processRef) {
      processRef.kill();
      processRef = null;
    }
  }

  return {
    play,
    pause,
    stop,
    seek,
    getState(): PlaybackState {
      return state;
    }
  };
}

function toPlayingState(channel: LiveChannel): PlaybackState {
  return {
    status: "playing",
    itemId: channel.id,
    itemType: "live",
    title: channel.name,
    positionSeconds: 0,
    durationSeconds: null,
    isSeekable: false,
    errorMessage: null
  };
}

function createIpcPath(): string {
  const suffix = `${Date.now()}-${Math.random().toString(16).slice(2)}`;
  if (process.platform === "win32") {
    return `\\\\.\\pipe\\iptv-player-${suffix}`;
  }
  return path.join(os.tmpdir(), `iptv-player-${suffix}.sock`);
}

function sanitizeMpvMessage(message: string): string {
  return message.replace(/password=[^&\s]+/gi, "password=REDACTED").trim().slice(0, 500);
}
```

- [ ] **Step 4: Implement external player command helper**

Replace `electron/main/playback/externalPlayer.ts`:

```ts
import { spawn } from "node:child_process";
import type { PlayRequest } from "../../../src/shared/playback/types";
import type { createCatalogRepository } from "../storage/catalogRepository";

export function buildExternalPlayerArgs(url: string): string[] {
  return [url];
}

export async function openInExternalPlayer(
  request: PlayRequest,
  catalogRepository?: ReturnType<typeof createCatalogRepository>
): Promise<void> {
  if (!catalogRepository || request.itemType !== "live") {
    return;
  }

  const channel = catalogRepository.getLiveChannel(request.itemId);
  if (!channel?.stream.url) {
    throw new Error(`No playable stream for item: ${request.itemId}`);
  }

  const player = process.env.IPTV_EXTERNAL_PLAYER || "mpv";
  const child = spawn(player, buildExternalPlayerArgs(channel.stream.url), {
    detached: true,
    stdio: "ignore"
  });
  child.unref();
}
```

- [ ] **Step 5: Wire playback IPC handlers**

Add these handlers near the end of `registerIpcHandlers` in `electron/main/ipc/registerIpcHandlers.ts`:

```ts
  ipcMain.handle(ipcChannels.playbackPlay, async (_event, request) => {
    await deps.mpvController.play(request);
    deps.mainWindow.webContents.send(ipcChannels.playbackState, deps.mpvController.getState());
  });

  ipcMain.handle(ipcChannels.playbackPause, async () => {
    await deps.mpvController.pause();
    deps.mainWindow.webContents.send(ipcChannels.playbackState, deps.mpvController.getState());
  });

  ipcMain.handle(ipcChannels.playbackStop, async () => {
    await deps.mpvController.stop();
    deps.mainWindow.webContents.send(ipcChannels.playbackState, deps.mpvController.getState());
  });

  ipcMain.handle(ipcChannels.playbackSeek, async (_event, request) => {
    await deps.mpvController.seek(request);
    deps.mainWindow.webContents.send(ipcChannels.playbackState, deps.mpvController.getState());
  });

  ipcMain.handle(ipcChannels.playbackOpenExternal, async (_event, request) => {
    await deps.openInExternalPlayer(request, deps.catalogRepository);
  });

  ipcMain.handle(ipcChannels.playbackGetState, () => deps.mpvController.getState());
```

The final `registerIpcHandlers` function should still include provider and catalog handlers from Task 5.

- [ ] **Step 6: Broadcast playback state changes**

Modify the `createMpvController` call in `electron/main/index.ts` after `mainWindow` exists:

```ts
  const mainWindow = createMainWindow();
  const mpvController = createMpvController({
    catalogRepository,
    onStateChange: (state) => {
      mainWindow.webContents.send("playback:state", state);
    }
  });
```

Keep `registerIpcHandlers` below that block so it receives the initialized `mpvController`.

- [ ] **Step 7: Run playback tests**

Run:

```bash
pnpm vitest run src/playback/mpvController.test.ts
```

Expected: PASS, 3 tests.

- [ ] **Step 8: Run all checks**

Run:

```bash
pnpm typecheck
pnpm test
pnpm build
```

Expected: all commands exit 0.

- [ ] **Step 9: Commit playback foundation**

```bash
git add electron/main/playback electron/main/ipc/registerIpcHandlers.ts electron/main/index.ts src/playback/mpvController.test.ts
git commit -m "feat: add managed mpv playback"
```

## Task 8: Add Playback Controls And 10-Second Seek Gestures

**Files:**

- Create: `src/renderer/features/playback/playerGestures.ts`
- Create: `src/renderer/features/playback/playerGestures.test.ts`
- Create: `src/renderer/features/playback/PlayerControls.tsx`
- Modify: `src/renderer/app/App.tsx`
- Modify: `src/renderer/styles/global.css`

- [ ] **Step 1: Write gesture tests**

Create `src/renderer/features/playback/playerGestures.test.ts`:

```ts
import { describe, expect, it } from "vitest";
import { getSeekSecondsForDoubleClick } from "./playerGestures";

describe("playerGestures", () => {
  it("seeks backward on left half", () => {
    expect(getSeekSecondsForDoubleClick({ clientX: 100, width: 400, isSeekable: true })).toBe(-10);
  });

  it("seeks forward on right half", () => {
    expect(getSeekSecondsForDoubleClick({ clientX: 300, width: 400, isSeekable: true })).toBe(10);
  });

  it("returns zero for non-seekable content", () => {
    expect(getSeekSecondsForDoubleClick({ clientX: 300, width: 400, isSeekable: false })).toBe(0);
  });
});
```

- [ ] **Step 2: Run gesture tests to verify failure**

Run:

```bash
pnpm vitest run src/renderer/features/playback/playerGestures.test.ts
```

Expected: FAIL because `playerGestures.ts` does not exist.

- [ ] **Step 3: Implement gesture helper**

Create `src/renderer/features/playback/playerGestures.ts`:

```ts
interface DoubleClickInput {
  clientX: number;
  width: number;
  isSeekable: boolean;
}

export function getSeekSecondsForDoubleClick(input: DoubleClickInput): -10 | 0 | 10 {
  if (!input.isSeekable) {
    return 0;
  }

  return input.clientX < input.width / 2 ? -10 : 10;
}
```

- [ ] **Step 4: Add player controls**

Create `src/renderer/features/playback/PlayerControls.tsx`:

```tsx
import { Pause, Play, Square, StepBack, StepForward } from "lucide-react";
import { useEffect, useState } from "react";
import type { PlaybackState } from "../../../shared/playback/types";
import { iptvApi } from "../../app/api";
import { getSeekSecondsForDoubleClick } from "./playerGestures";

export function PlayerControls() {
  const [state, setState] = useState<PlaybackState | null>(null);

  useEffect(() => {
    void iptvApi.playback.getState().then(setState);
    return iptvApi.playback.onState(setState);
  }, []);

  useEffect(() => {
    function onKeyDown(event: KeyboardEvent) {
      if (!state?.isSeekable) {
        return;
      }
      if (event.key === "ArrowLeft") {
        void iptvApi.playback.seek({ offsetSeconds: -10 });
      }
      if (event.key === "ArrowRight") {
        void iptvApi.playback.seek({ offsetSeconds: 10 });
      }
    }

    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, [state?.isSeekable]);

  if (!state || state.status === "idle") {
    return null;
  }

  return (
    <section
      className="player-controls"
      onDoubleClick={(event) => {
        const rect = event.currentTarget.getBoundingClientRect();
        const seconds = getSeekSecondsForDoubleClick({
          clientX: event.clientX - rect.left,
          width: rect.width,
          isSeekable: state.isSeekable
        });
        if (seconds !== 0) {
          void iptvApi.playback.seek({ offsetSeconds: seconds });
        }
      }}
    >
      <div>
        <strong>{state.title}</strong>
        {state.errorMessage ? <span className="playback-error">{state.errorMessage}</span> : null}
      </div>
      <div className="player-buttons">
        <button type="button" title="Back 10 seconds" disabled={!state.isSeekable} onClick={() => iptvApi.playback.seek({ offsetSeconds: -10 })}>
          <StepBack size={17} />
        </button>
        <button type="button" title="Play or pause" onClick={() => iptvApi.playback.pause()}>
          {state.status === "paused" ? <Play size={17} /> : <Pause size={17} />}
        </button>
        <button type="button" title="Stop" onClick={() => iptvApi.playback.stop()}>
          <Square size={17} />
        </button>
        <button type="button" title="Forward 10 seconds" disabled={!state.isSeekable} onClick={() => iptvApi.playback.seek({ offsetSeconds: 10 })}>
          <StepForward size={17} />
        </button>
      </div>
    </section>
  );
}
```

- [ ] **Step 5: Render player controls in app**

Modify `src/renderer/app/App.tsx` by adding this import:

```ts
import { PlayerControls } from "../features/playback/PlayerControls";
```

Render `<PlayerControls />` as the final child in the main app shell:

```tsx
      <PlayerControls />
```

Place it after the `</section>` closing tag for `.content` and before `</main>`.

- [ ] **Step 6: Add player control styles**

Append to `src/renderer/styles/global.css`:

```css
.player-controls {
  position: fixed;
  left: 252px;
  right: 20px;
  bottom: 20px;
  min-height: 64px;
  border: 1px solid #2f2f2f;
  border-radius: 8px;
  background: rgba(16, 16, 16, 0.94);
  color: #ffffff;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  padding: 12px 14px;
}

.player-buttons {
  display: flex;
  gap: 8px;
}

.player-buttons button {
  width: 38px;
  height: 38px;
  border: 1px solid #555;
  border-radius: 7px;
  background: #ffffff;
  color: #101010;
  display: grid;
  place-items: center;
}

.playback-error {
  display: block;
  color: #ffb3b3;
  margin-top: 4px;
}
```

- [ ] **Step 7: Run tests and checks**

Run:

```bash
pnpm vitest run src/renderer/features/playback/playerGestures.test.ts
pnpm typecheck
pnpm test
pnpm build
```

Expected: all commands exit 0.

- [ ] **Step 8: Commit controls**

```bash
git add src/renderer
git commit -m "feat: add playback controls"
```

## Task 9: Add mpv Check Script And Release Checklist

**Files:**

- Create: `scripts/check-mpv.js`
- Create: `docs/release-checklist.md`
- Modify: `.gitignore`

- [ ] **Step 1: Add mpv check script**

Create `scripts/check-mpv.js`:

```js
import { spawnSync } from "node:child_process";

const result = spawnSync("mpv", ["--version"], {
  encoding: "utf8"
});

if (result.error) {
  console.error("mpv was not found on PATH. Install mpv or configure the external player path before playback testing.");
  process.exit(1);
}

if (result.status !== 0) {
  console.error(result.stderr || result.stdout);
  process.exit(result.status ?? 1);
}

console.log(result.stdout.split("\n")[0]);
```

- [ ] **Step 2: Add release checklist**

Create `docs/release-checklist.md`:

```md
# Release Checklist

## Version

- Confirm the working tree is clean.
- Confirm commits use Conventional Commits.
- Update `package.json` version.
- Create a semantic version tag, such as `v0.1.0`.

## Verification

- Run `pnpm typecheck`.
- Run `pnpm test`.
- Run `pnpm check:mpv`.
- Run `pnpm build`.
- Import a legal/sample M3U playlist.
- Play a legal HLS stream.
- Verify external player fallback.

## Build

- On macOS, run `pnpm build:mac`.
- On Windows, run `pnpm build:win`.

## GitHub Release

- Create a GitHub Release for the version tag.
- Upload the macOS `.dmg` or `.zip` artifact from `release/`.
- Upload the Windows `.exe` installer from `release/`.
- Include release notes with user-visible changes, known limitations, and verification performed.
```

- [ ] **Step 3: Ensure release output is ignored**

Confirm `.gitignore` contains:

```gitignore
release/
```

If it does not, add that line.

- [ ] **Step 4: Run checks**

Run:

```bash
pnpm typecheck
pnpm test
pnpm build
```

Expected: all commands exit 0.

Run:

```bash
pnpm check:mpv
```

Expected: exits 0 and prints the installed mpv version if mpv is installed. If mpv is not installed, record that playback testing is blocked until mpv is installed.

- [ ] **Step 5: Commit release docs**

```bash
git add scripts/check-mpv.js docs/release-checklist.md .gitignore package.json
git commit -m "docs: add release checklist"
```

## Task 10: Final Verification For Foundation Slice

**Files:**

- Modify only files needed to fix failures discovered by these checks.

- [ ] **Step 1: Run full automated verification**

Run:

```bash
pnpm typecheck
pnpm test
pnpm build
```

Expected: all commands exit 0.

- [ ] **Step 2: Run development app**

Run:

```bash
pnpm dev:electron
```

Expected:

- Electron window opens.
- Empty-state provider setup appears.
- An M3U URL or local path can be submitted.
- Import progress appears.
- Imported channels appear in the Live TV catalog.
- Search filters channel results.
- Category chips filter channel results.
- Selecting a channel updates the detail pane.
- Play starts mpv for that channel if mpv is installed and the stream is legal/reachable.
- Player controls appear after playback starts.
- Live streams do not allow 10-second seek.
- External player command path is available through IPC.

- [ ] **Step 3: Stop the dev server**

In the terminal running `pnpm dev:electron`, press `Ctrl+C`.

Expected: Vite and Electron processes stop.

- [ ] **Step 4: Build local artifact on the current OS**

On macOS run:

```bash
pnpm build:mac
```

On Windows run:

```bash
pnpm build:win
```

Expected: installer artifacts are written under `release/`. If packaging fails because native dependency rebuilding is required for `better-sqlite3`, run `pnpm exec electron-builder install-app-deps` and repeat the build command.

- [ ] **Step 5: Commit verification fixes**

If verification required fixes, commit them:

```bash
git add .
git commit -m "fix: stabilize desktop foundation"
```

If no fixes were required, do not create an empty commit.

## Self-Review Checklist

- The plan implements the foundation slice of the approved spec.
- Xtream Codes, movies, series, episode selector, and EPG are intentionally outside this first plan and need follow-up plans.
- The plan includes TDD steps for parser, storage, playback command construction, and seek gesture behavior.
- The plan includes typed IPC, local storage, M3U import, catalog UI, managed mpv playback, external player path, icons, and manual release checklist.
- The plan uses feature-prefixed branch naming and Conventional Commits.
- There are no placeholder steps or unspecified test commands.
