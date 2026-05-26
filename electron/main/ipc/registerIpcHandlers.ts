import { ipcMain } from "electron";
import { toLiveChannelView } from "../../../src/shared/catalog/types.js";
import { ipcChannels } from "../../../src/shared/ipc/types.js";
import { toProviderSummary, type CreateM3uProviderInput } from "../../../src/shared/providers/types.js";
import type { importM3uProvider } from "../imports/importM3uProvider.js";
import type { openInExternalPlayer } from "../playback/externalPlayer.js";
import type { createMpvController } from "../playback/mpvController.js";
import type { createCatalogRepository } from "../storage/catalogRepository.js";
import type { createProviderRepository } from "../storage/providerRepository.js";

interface RegisterIpcHandlersDeps {
  emitToRenderer(channel: string, payload: unknown): void;
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
      emitProgress: (progress) => deps.emitToRenderer(ipcChannels.providersImportProgress, progress)
    });
    const refreshedProvider = deps.providerRepository.get(provider.id);
    return toProviderSummary(refreshedProvider ?? provider);
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
        emitProgress: (progress) => deps.emitToRenderer(ipcChannels.providersImportProgress, progress)
      });
    }
  });

  ipcMain.handle(ipcChannels.catalogListLiveChannels, (_event, input: { query: string; category: string | null }) =>
    deps.catalogRepository.listLiveChannels(input.query, input.category).map(toLiveChannelView)
  );

  ipcMain.handle(ipcChannels.catalogToggleFavorite, (_event, input: { itemId: string; itemType: "live" }) => {
    deps.catalogRepository.toggleFavorite(input.itemId, input.itemType);
  });
}
