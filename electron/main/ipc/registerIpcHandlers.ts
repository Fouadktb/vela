import { ipcMain } from "electron";
import type { CategoryContentType } from "../../../src/shared/catalog/types.js";
import { toEpisodeView, toLiveChannelView, toMovieView, toSeriesView } from "../../../src/shared/catalog/types.js";
import { ipcChannels } from "../../../src/shared/ipc/types.js";
import type { PlayRequest, SeekRequest } from "../../../src/shared/playback/types.js";
import {
  toProviderSummary,
  validateCreateM3uProviderInput,
  validateCreateXtreamProviderInput
} from "../../../src/shared/providers/types.js";
import type { importM3uProvider } from "../imports/importM3uProvider.js";
import type {
  importXtreamLivePrograms,
  importXtreamProvider,
  importXtreamSeriesEpisodes
} from "../imports/importXtreamProvider.js";
import type { openInExternalPlayer } from "../playback/externalPlayer.js";
import type { createMpvController } from "../playback/mpvController.js";
import type { createCatalogRepository } from "../storage/catalogRepository.js";
import type { createProviderRepository } from "../storage/providerRepository.js";

interface RegisterIpcHandlersDeps {
  emitToRenderer(channel: string, payload: unknown): void;
  providerRepository: ReturnType<typeof createProviderRepository>;
  catalogRepository: ReturnType<typeof createCatalogRepository>;
  importM3uProvider: typeof importM3uProvider;
  importXtreamProvider: typeof importXtreamProvider;
  importXtreamSeriesEpisodes: typeof importXtreamSeriesEpisodes;
  importXtreamLivePrograms?: typeof importXtreamLivePrograms;
  mpvController: ReturnType<typeof createMpvController>;
  openInExternalPlayer: typeof openInExternalPlayer;
}

export function registerIpcHandlers(deps: RegisterIpcHandlersDeps): void {
  ipcMain.handle(ipcChannels.providersList, () => deps.providerRepository.list().map(toProviderSummary));

  ipcMain.handle(ipcChannels.providersCreateM3u, async (_event, rawInput: unknown) => {
    const input = validateCreateM3uProviderInput(rawInput);
    const provider = deps.providerRepository.createM3u(input);
    try {
      await deps.importM3uProvider(provider, {
        providerRepository: deps.providerRepository,
        catalogRepository: deps.catalogRepository,
        emitProgress: (progress) => deps.emitToRenderer(ipcChannels.providersImportProgress, progress)
      });
    } catch (error) {
      deps.providerRepository.delete(provider.id);
      throw error;
    }
    const refreshedProvider = deps.providerRepository.get(provider.id);
    return toProviderSummary(refreshedProvider ?? provider);
  });

  ipcMain.handle(ipcChannels.providersCreateXtream, async (_event, rawInput: unknown) => {
    const input = validateCreateXtreamProviderInput(rawInput);
    const provider = deps.providerRepository.createXtream(input);
    try {
      await deps.importXtreamProvider(provider, {
        providerRepository: deps.providerRepository,
        catalogRepository: deps.catalogRepository,
        emitProgress: (progress) => deps.emitToRenderer(ipcChannels.providersImportProgress, progress)
      });
    } catch (error) {
      deps.providerRepository.delete(provider.id);
      throw error;
    }
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
    } else if (provider.type === "xtream") {
      await deps.importXtreamProvider(provider, {
        providerRepository: deps.providerRepository,
        catalogRepository: deps.catalogRepository,
        emitProgress: (progress) => deps.emitToRenderer(ipcChannels.providersImportProgress, progress)
      });
    }
  });

  ipcMain.handle(ipcChannels.providersDelete, (_event, providerId: string) => {
    deps.providerRepository.delete(providerId);
  });

  ipcMain.handle(ipcChannels.catalogListLiveChannels, (_event, input: { query: string; category: string | null }) =>
    deps.catalogRepository.listLiveChannels(input.query, input.category).map(toLiveChannelView)
  );

  ipcMain.handle(ipcChannels.catalogListLiveCategories, () => deps.catalogRepository.listLiveCategories());

  ipcMain.handle(ipcChannels.catalogListCategoryViews, (_event, rawContentType: unknown) =>
    deps.catalogRepository.listCategoryViews(toCategoryContentType(rawContentType))
  );

  ipcMain.handle(
    ipcChannels.catalogToggleCategoryPin,
    (_event, input: { contentType: unknown; category: unknown }) => {
      const category = toCategoryName(input.category);
      if (!category) {
        return;
      }
      deps.catalogRepository.toggleCategoryPin(toCategoryContentType(input.contentType), category);
    }
  );

  ipcMain.handle(
    ipcChannels.catalogReorderPinnedCategories,
    (_event, input: { contentType: unknown; categories: unknown }) => {
      const categories = Array.isArray(input.categories)
        ? input.categories.map(toCategoryName).filter((category): category is string => category !== null)
        : [];
      deps.catalogRepository.reorderPinnedCategories(toCategoryContentType(input.contentType), categories);
    }
  );

  ipcMain.handle(ipcChannels.catalogListLivePrograms, async (_event, channelId: string) => {
    const channel = deps.catalogRepository.getLiveChannel(channelId);
    if (!channel) {
      throw new Error(`Live channel not found: ${channelId}`);
    }

    let programs = deps.catalogRepository.listLiveProgramsForChannel(channel.id);
    if (programs.length === 0 && deps.importXtreamLivePrograms) {
      const provider = deps.providerRepository.get(channel.providerId);
      if (provider?.type === "xtream") {
        await deps.importXtreamLivePrograms(provider, channel, {
          catalogRepository: deps.catalogRepository
        });
        programs = deps.catalogRepository.listLiveProgramsForChannel(channel.id);
      }
    }

    return programs;
  });

  ipcMain.handle(ipcChannels.catalogListMovies, (_event, input: { query: string; category: string | null }) =>
    deps.catalogRepository.listMovies(input.query, input.category).map(toMovieView)
  );

  ipcMain.handle(ipcChannels.catalogListMovieCategories, () => deps.catalogRepository.listMovieCategories());

  ipcMain.handle(ipcChannels.catalogListSeries, (_event, input: { query: string; category: string | null }) =>
    deps.catalogRepository.listSeries(input.query, input.category).map(toSeriesView)
  );

  ipcMain.handle(ipcChannels.catalogListSeriesCategories, () => deps.catalogRepository.listSeriesCategories());

  ipcMain.handle(ipcChannels.catalogListEpisodesForSeries, async (_event, seriesId: string) => {
    const series = deps.catalogRepository.getSeries(seriesId);
    if (!series) {
      throw new Error(`Series not found: ${seriesId}`);
    }

    let episodes = deps.catalogRepository.listEpisodesForSeries(series.id);
    if (episodes.length === 0) {
      const provider = deps.providerRepository.get(series.providerId);
      if (provider?.type === "xtream") {
        await deps.importXtreamSeriesEpisodes(provider, series, {
          catalogRepository: deps.catalogRepository
        });
        episodes = deps.catalogRepository.listEpisodesForSeries(series.id);
      }
    }

    return episodes.map(toEpisodeView);
  });

  ipcMain.handle(ipcChannels.catalogListRecentlyWatched, () => deps.catalogRepository.listRecentlyWatched());

  ipcMain.handle(ipcChannels.catalogToggleFavorite, (_event, input: { itemId: string; itemType: "live" | "movie" | "series" }) => {
    deps.catalogRepository.toggleFavorite(input.itemId, input.itemType);
  });

  ipcMain.handle(ipcChannels.playbackPlay, async (_event, request: PlayRequest) => {
    await deps.mpvController.play(request);
    emitPlaybackState(deps);
  });

  ipcMain.handle(ipcChannels.playbackPause, async () => {
    await deps.mpvController.pause();
    emitPlaybackState(deps);
  });

  ipcMain.handle(ipcChannels.playbackStop, async () => {
    await deps.mpvController.stop();
    emitPlaybackState(deps);
  });

  ipcMain.handle(ipcChannels.playbackSeek, async (_event, request: SeekRequest) => {
    await deps.mpvController.seek(request);
    emitPlaybackState(deps);
  });

  ipcMain.handle(ipcChannels.playbackSelectAudioTrack, async (_event, trackId: number) => {
    await deps.mpvController.selectAudioTrack(trackId);
    emitPlaybackState(deps);
  });

  ipcMain.handle(ipcChannels.playbackSelectSubtitleTrack, async (_event, trackId: number | null) => {
    await deps.mpvController.selectSubtitleTrack(trackId);
    emitPlaybackState(deps);
  });

  ipcMain.handle(ipcChannels.playbackOpenExternal, async (_event, request: PlayRequest) => {
    await deps.openInExternalPlayer(request, deps.catalogRepository);
  });

  ipcMain.handle(ipcChannels.playbackGetState, () => deps.mpvController.getState());
}

function toCategoryContentType(value: unknown): CategoryContentType {
  if (value === "live" || value === "movie" || value === "series") {
    return value;
  }

  throw new Error("Invalid category content type");
}

function toCategoryName(value: unknown): string | null {
  if (typeof value !== "string") {
    return null;
  }

  const trimmed = value.trim();
  return trimmed || null;
}

function emitPlaybackState(deps: RegisterIpcHandlersDeps): void {
  deps.emitToRenderer(ipcChannels.playbackState, deps.mpvController.getState());
}
