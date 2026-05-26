import { useCallback, useEffect, useMemo, useState } from "react";
import type {
  CategoryContentType,
  CategoryView,
  LiveChannelView,
  MovieView,
  RecentlyWatchedItemView,
  SeriesView
} from "../../shared/catalog/types";
import type { ProviderSummary } from "../../shared/providers/types";
import { iptvApi } from "./api";

export function useAppData() {
  const [providers, setProviders] = useState<ProviderSummary[]>([]);
  const [channels, setChannels] = useState<LiveChannelView[]>([]);
  const [movies, setMovies] = useState<MovieView[]>([]);
  const [series, setSeries] = useState<SeriesView[]>([]);
  const [recentlyWatched, setRecentlyWatched] = useState<RecentlyWatchedItemView[]>([]);
  const [categories, setCategories] = useState<string[]>([]);
  const [movieCategories, setMovieCategories] = useState<string[]>([]);
  const [seriesCategories, setSeriesCategories] = useState<string[]>([]);
  const [categoryViews, setCategoryViews] = useState<CategoryView[]>([]);
  const [movieCategoryViews, setMovieCategoryViews] = useState<CategoryView[]>([]);
  const [seriesCategoryViews, setSeriesCategoryViews] = useState<CategoryView[]>([]);
  const [query, setQuery] = useState("");
  const [category, setCategory] = useState<string | null>(null);
  const [selectedChannelId, setSelectedChannelId] = useState<string | null>(null);
  const [statusMessage, setStatusMessage] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const selectedChannel = useMemo(
    () => channels.find((channel) => channel.id === selectedChannelId) ?? channels[0] ?? null,
    [channels, selectedChannelId]
  );

  const reloadProviders = useCallback(async () => {
    try {
      setErrorMessage(null);
      const nextProviders = await iptvApi.providers.list();
      setProviders(nextProviders);
    } catch (unknownError) {
      setErrorMessage(unknownError instanceof Error ? unknownError.message : "Unable to load providers");
    }
  }, []);

  const reloadChannels = useCallback(async () => {
    setIsLoading(true);
    try {
      setErrorMessage(null);
      const nextChannels = await iptvApi.catalog.listLiveChannels(query, category);
      setChannels(nextChannels);
      setSelectedChannelId((current) =>
        current && nextChannels.some((channel) => channel.id === current) ? current : nextChannels[0]?.id ?? null
      );
    } catch (unknownError) {
      setErrorMessage(unknownError instanceof Error ? unknownError.message : "Unable to load channels");
    } finally {
      setIsLoading(false);
    }
  }, [category, query]);

  const reloadCategories = useCallback(async () => {
    try {
      setErrorMessage(null);
      const nextCategories = await iptvApi.catalog.listCategoryViews("live");
      setCategoryViews(nextCategories);
      setCategories(nextCategories.map((item) => item.name));
    } catch (unknownError) {
      setErrorMessage(unknownError instanceof Error ? unknownError.message : "Unable to load live categories");
    }
  }, []);

  const reloadMovies = useCallback(async () => {
    try {
      setErrorMessage(null);
      setMovies(await iptvApi.catalog.listMovies(query, category));
    } catch (unknownError) {
      setErrorMessage(unknownError instanceof Error ? unknownError.message : "Unable to load movies");
    }
  }, [category, query]);

  const reloadMovieCategories = useCallback(async () => {
    try {
      setErrorMessage(null);
      const nextCategories = await iptvApi.catalog.listCategoryViews("movie");
      setMovieCategoryViews(nextCategories);
      setMovieCategories(nextCategories.map((item) => item.name));
    } catch (unknownError) {
      setErrorMessage(unknownError instanceof Error ? unknownError.message : "Unable to load movie categories");
    }
  }, []);

  const reloadSeries = useCallback(async () => {
    try {
      setErrorMessage(null);
      setSeries(await iptvApi.catalog.listSeries(query, category));
    } catch (unknownError) {
      setErrorMessage(unknownError instanceof Error ? unknownError.message : "Unable to load series");
    }
  }, [category, query]);

  const reloadSeriesCategories = useCallback(async () => {
    try {
      setErrorMessage(null);
      const nextCategories = await iptvApi.catalog.listCategoryViews("series");
      setSeriesCategoryViews(nextCategories);
      setSeriesCategories(nextCategories.map((item) => item.name));
    } catch (unknownError) {
      setErrorMessage(unknownError instanceof Error ? unknownError.message : "Unable to load series categories");
    }
  }, []);

  const reloadCategoryViews = useCallback(
    async (contentType: CategoryContentType) => {
      if (contentType === "movie") {
        await reloadMovieCategories();
        return;
      }
      if (contentType === "series") {
        await reloadSeriesCategories();
        return;
      }

      await reloadCategories();
    },
    [reloadCategories, reloadMovieCategories, reloadSeriesCategories]
  );

  const toggleCategoryPin = useCallback(
    async (contentType: CategoryContentType, categoryName: string) => {
      await iptvApi.catalog.toggleCategoryPin(contentType, categoryName);
      await reloadCategoryViews(contentType);
    },
    [reloadCategoryViews]
  );

  const reorderPinnedCategories = useCallback(
    async (contentType: CategoryContentType, categoryNames: string[]) => {
      await iptvApi.catalog.reorderPinnedCategories(contentType, categoryNames);
      await reloadCategoryViews(contentType);
    },
    [reloadCategoryViews]
  );

  const reloadRecentlyWatched = useCallback(async () => {
    try {
      setErrorMessage(null);
      setRecentlyWatched(await iptvApi.catalog.listRecentlyWatched());
    } catch (unknownError) {
      setErrorMessage(unknownError instanceof Error ? unknownError.message : "Unable to load recently watched");
    }
  }, []);

  const reloadAll = useCallback(async () => {
    await Promise.all([
      reloadProviders(),
      reloadCategories(),
      reloadChannels(),
      reloadMovieCategories(),
      reloadMovies(),
      reloadSeriesCategories(),
      reloadSeries(),
      reloadRecentlyWatched()
    ]);
  }, [
    reloadCategories,
    reloadChannels,
    reloadMovieCategories,
    reloadMovies,
    reloadProviders,
    reloadRecentlyWatched,
    reloadSeries,
    reloadSeriesCategories
  ]);

  useEffect(() => {
    void reloadProviders();
  }, [reloadProviders]);

  useEffect(() => {
    void reloadChannels();
  }, [reloadChannels]);

  useEffect(() => {
    void reloadCategories();
  }, [reloadCategories]);

  useEffect(() => {
    void reloadMovies();
  }, [reloadMovies]);

  useEffect(() => {
    void reloadMovieCategories();
  }, [reloadMovieCategories]);

  useEffect(() => {
    void reloadSeries();
  }, [reloadSeries]);

  useEffect(() => {
    void reloadSeriesCategories();
  }, [reloadSeriesCategories]);

  useEffect(() => {
    void reloadRecentlyWatched();
  }, [reloadRecentlyWatched]);

  useEffect(() => {
    return iptvApi.providers.onImportProgress((progress) => {
      setStatusMessage(progress.message);

      if (progress.phase === "complete") {
        void reloadAll();
      }

      if (progress.phase === "failed") {
        setErrorMessage(progress.message);
      }
    });
  }, [
    reloadAll
  ]);

  return {
    providers,
    channels,
    movies,
    series,
    recentlyWatched,
    categories,
    movieCategories,
    seriesCategories,
    categoryViews,
    movieCategoryViews,
    seriesCategoryViews,
    query,
    setQuery,
    category,
    setCategory,
    selectedChannel,
    setSelectedChannelId,
    statusMessage,
    isLoading,
    errorMessage,
    reloadCategories,
    reloadChannels,
    reloadMovieCategories,
    reloadMovies,
    reloadProviders,
    reloadAll,
    reloadRecentlyWatched,
    reloadSeriesCategories,
    reloadSeries,
    reloadCategoryViews,
    reorderPinnedCategories,
    toggleCategoryPin
  };
}
