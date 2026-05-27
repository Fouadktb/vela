import { useEffect, useMemo, useState } from "react";
import type { CategoryContentType, CategoryView, EpisodeView, LiveProgramView } from "../../shared/catalog/types";
import { Sidebar, type AppSection } from "../components/Sidebar";
import { SearchBar } from "../components/SearchBar";
import { CategoryRail } from "../features/catalog/CategoryRail";
import { CatalogDetailPane } from "../features/catalog/CatalogDetailPane";
import { CatalogGrid, type CatalogCardItem } from "../features/catalog/CatalogGrid";
import { InAppPlayer } from "../features/playback/InAppPlayer";
import { ProviderSetup } from "../features/providers/ProviderSetup";
import { ProviderSettings } from "../features/providers/ProviderSettings";
import { iptvApi } from "./api";
import { useAppData } from "./useAppData";
import type { PlayRequest } from "../../shared/playback/types";

type CatalogItemType = "live" | "movie" | "series" | "episode";
type CatalogSectionItem = CatalogCardItem & {
  itemType: CatalogItemType;
  providerId: string;
  eyebrow: string;
  isFavorite: boolean;
  canPlay: boolean;
  canFavorite: boolean;
};

export function App() {
  const data = useAppData();
  const [activeSection, setActiveSection] = useState<AppSection>("live");
  const [selectedItemId, setSelectedItemId] = useState<string | null>(null);
  const [episodes, setEpisodes] = useState<EpisodeView[]>([]);
  const [livePrograms, setLivePrograms] = useState<LiveProgramView[]>([]);
  const [playbackRequest, setPlaybackRequest] = useState<PlayRequest | null>(null);
  const [isLoadingEpisodes, setIsLoadingEpisodes] = useState(false);
  const [isLoadingPrograms, setIsLoadingPrograms] = useState(false);
  const items = useMemo(() => buildCatalogItems(data), [data]);
  const visibleItems = useMemo(
    () => getSectionItems(activeSection, items, data.query),
    [activeSection, data.query, items]
  );
  const selectedItem = useMemo(
    () => visibleItems.find((item) => item.id === selectedItemId) ?? visibleItems[0] ?? null,
    [selectedItemId, visibleItems]
  );
  const categoryViews = getSectionCategoryViews(activeSection, data);
  const categoryContentType = getSectionCategoryContentType(activeSection);
  const title = getSectionTitle(activeSection);
  const allCategoryLabel = getAllCategoryLabel(activeSection);
  const searchPlaceholder = getSearchPlaceholder(activeSection);
  const isSettingsSection = activeSection === "settings";
  const showCategoryRail = activeSection !== "settings" && activeSection !== "recent";

  function changeSection(nextSection: AppSection) {
    setActiveSection(nextSection);
    setSelectedItemId(null);
    data.setQuery("");
    data.setCategory(null);
    if (nextSection === "recent") {
      void data.reloadRecentlyWatched();
    }
  }

  useEffect(() => {
    let isCancelled = false;

    if (selectedItem?.itemType !== "series") {
      setEpisodes([]);
      setIsLoadingEpisodes(false);
      return () => {
        isCancelled = true;
      };
    }

    setIsLoadingEpisodes(true);
    setEpisodes([]);
    iptvApi.catalog
      .listEpisodesForSeries(selectedItem.id)
      .then((nextEpisodes) => {
        if (!isCancelled) {
          setEpisodes(nextEpisodes);
        }
      })
      .catch(() => {
        if (!isCancelled) {
          setEpisodes([]);
        }
      })
      .finally(() => {
        if (!isCancelled) {
          setIsLoadingEpisodes(false);
        }
      });

    return () => {
      isCancelled = true;
    };
  }, [selectedItem?.id, selectedItem?.itemType]);

  useEffect(() => {
    let isCancelled = false;

    if (selectedItem?.itemType !== "live") {
      setLivePrograms([]);
      setIsLoadingPrograms(false);
      return () => {
        isCancelled = true;
      };
    }

    setIsLoadingPrograms(true);
    setLivePrograms([]);
    iptvApi.catalog
      .listLivePrograms(selectedItem.id)
      .then((nextPrograms) => {
        if (!isCancelled) {
          setLivePrograms(nextPrograms);
        }
      })
      .catch(() => {
        if (!isCancelled) {
          setLivePrograms([]);
        }
      })
      .finally(() => {
        if (!isCancelled) {
          setIsLoadingPrograms(false);
        }
      });

    return () => {
      isCancelled = true;
    };
  }, [selectedItem?.id, selectedItem?.itemType]);

  if (data.providers.length === 0) {
    return (
      <main className="setup-screen">
        <ProviderSetup onCreated={data.reloadAll} />
        {data.statusMessage ? <span className="status-pill setup-status">{data.statusMessage}</span> : null}
      </main>
    );
  }

  return (
    <main className="app-shell">
      <Sidebar activeSection={activeSection} onSectionChange={changeSection} />
      <section className="content">
        <header className="toolbar">
          <div>
            <p className="eyebrow">{isSettingsSection ? "Preferences" : "Catalog"}</p>
            <h1>{title}</h1>
          </div>
          {isSettingsSection ? null : (
            <SearchBar query={data.query} placeholder={searchPlaceholder} onQueryChange={data.setQuery} />
          )}
          {data.statusMessage ? <span className="status-pill">{data.statusMessage}</span> : null}
        </header>

        {data.errorMessage ? <div className="error banner">{data.errorMessage}</div> : null}

        {isSettingsSection ? (
          <ProviderSettings
            providers={data.providers}
            onCreated={data.reloadAll}
            onRefresh={async (providerId) => {
              await iptvApi.providers.refresh(providerId);
              await data.reloadAll();
            }}
            onAutoRefreshChange={async (providerId, enabled, intervalHours) => {
              await iptvApi.providers.updateAutoRefresh({ providerId, enabled, intervalHours });
              await data.reloadProviders();
            }}
            onDelete={async (providerId) => {
              await iptvApi.providers.delete(providerId);
              await data.reloadAll();
            }}
          />
        ) : (
          <>
            <div className={showCategoryRail ? "main-grid with-categories" : "main-grid"}>
              {showCategoryRail ? (
                <CategoryRail
                  allLabel={allCategoryLabel}
                  categories={categoryViews}
                  contentType={categoryContentType}
                  selectedCategory={data.category}
                  onSelect={(nextCategory) => {
                    setSelectedItemId(null);
                    data.setCategory(nextCategory);
                  }}
                  onTogglePin={(contentType, categoryName) => {
                    void data.toggleCategoryPin(contentType, categoryName);
                  }}
                  onReorderPinned={(contentType, categoryNames) => {
                    void data.reorderPinnedCategories(contentType, categoryNames);
                  }}
                />
              ) : null}
              <CatalogGrid
                items={visibleItems}
                selectedItemId={selectedItem?.id ?? null}
                isLoading={data.isLoading}
                emptyMessage={`No ${title.toLowerCase()} match the current filters.`}
                onSelect={setSelectedItemId}
              />
              <CatalogDetailPane
                item={selectedItem}
                episodes={episodes}
                livePrograms={livePrograms}
                isLoadingEpisodes={isLoadingEpisodes}
                isLoadingPrograms={isLoadingPrograms}
                onPlay={(itemId) => {
                  const item = visibleItems.find((candidate) => candidate.id === itemId);
                  if (item?.itemType === "live" || item?.itemType === "movie" || item?.itemType === "episode") {
                    setPlaybackRequest({ itemType: item.itemType, itemId });
                  }
                }}
                onPlayEpisode={(itemId) => {
                  setPlaybackRequest({ itemType: "episode", itemId });
                }}
                onToggleFavorite={async (itemId) => {
                  const item = visibleItems.find((candidate) => candidate.id === itemId);
                  if (item && item.itemType !== "episode") {
                    await iptvApi.catalog.toggleFavorite(itemId, item.itemType);
                    await reloadCurrentSection(activeSection, data);
                  }
                }}
                onRefreshProvider={async () => {
                  const providerId = selectedItem?.providerId ?? data.providers[0]?.id;
                  if (providerId) {
                    await iptvApi.providers.refresh(providerId);
                    await data.reloadAll();
                  }
                }}
              />
            </div>
          </>
        )}
      </section>
      <InAppPlayer request={playbackRequest} onClose={() => setPlaybackRequest(null)} />
    </main>
  );
}

function buildCatalogItems(data: ReturnType<typeof useAppData>) {
  const live: CatalogSectionItem[] = data.channels.map((channel) => ({
    id: channel.id,
    itemType: "live",
    providerId: channel.providerId,
    title: channel.name,
    subtitle: channel.category || "Uncategorized",
    artworkUrl: channel.logoUrl,
    eyebrow: "Live channel",
    isFavorite: channel.isFavorite,
    canPlay: true,
    canFavorite: true
  }));
  const movies: CatalogSectionItem[] = data.movies.map((movie) => ({
    id: movie.id,
    itemType: "movie",
    providerId: movie.providerId,
    title: movie.title,
    subtitle: [movie.category, movie.year ? String(movie.year) : null, movie.rating ? `Rating ${movie.rating}` : null]
      .filter(Boolean)
      .join(" | "),
    artworkUrl: movie.posterUrl,
    eyebrow: "Movie",
    isFavorite: movie.isFavorite,
    canPlay: true,
    canFavorite: true
  }));
  const series: CatalogSectionItem[] = data.series.map((item) => ({
    id: item.id,
    itemType: "series",
    providerId: item.providerId,
    title: item.title,
    subtitle: item.category || "Uncategorized",
    artworkUrl: item.posterUrl,
    eyebrow: "Series",
    isFavorite: item.isFavorite,
    canPlay: false,
    canFavorite: true
  }));
  const recent: CatalogSectionItem[] = data.recentlyWatched.map((item) => ({
    id: item.id,
    itemType: item.itemType,
    providerId: item.providerId,
    title: item.title,
    subtitle: item.subtitle,
    artworkUrl: item.artworkUrl,
    eyebrow: item.itemType === "live" ? "Live channel" : item.itemType === "movie" ? "Movie" : "Episode",
    isFavorite: false,
    canPlay: true,
    canFavorite: false
  }));

  return { live, movies, series, recent };
}

function getSectionItems(
  section: AppSection,
  items: ReturnType<typeof buildCatalogItems>,
  query: string
): CatalogSectionItem[] {
  if (section === "movies") {
    return items.movies;
  }
  if (section === "series") {
    return items.series;
  }
  if (section === "favorites") {
    return [...items.live, ...items.movies, ...items.series].filter((item) => item.isFavorite);
  }
  if (section === "recent") {
    return filterItemsByQuery(items.recent, query);
  }

  return items.live;
}

function getSectionCategoryViews(section: AppSection, data: ReturnType<typeof useAppData>): CategoryView[] {
  if (section === "movies") {
    return data.movieCategoryViews;
  }
  if (section === "series") {
    return data.seriesCategoryViews;
  }
  if (section === "favorites") {
    return mergeCategoryViews([...data.categoryViews, ...data.movieCategoryViews, ...data.seriesCategoryViews]);
  }
  if (section === "recent" || section === "settings") {
    return [];
  }

  return data.categoryViews;
}

function getSectionCategoryContentType(section: AppSection): CategoryContentType | null {
  if (section === "movies") {
    return "movie";
  }
  if (section === "series") {
    return "series";
  }
  if (section === "live") {
    return "live";
  }

  return null;
}

function mergeCategoryViews(categoryViews: CategoryView[]): CategoryView[] {
  const merged = new Map<string, CategoryView>();

  for (const category of categoryViews) {
    const existing = merged.get(category.name);
    if (!existing) {
      merged.set(category.name, { ...category, contentType: "live", isPinned: false, sortOrder: null });
      continue;
    }

    merged.set(category.name, {
      ...existing,
      itemCount: existing.itemCount + category.itemCount
    });
  }

  return Array.from(merged.values()).sort((a, b) => a.name.localeCompare(b.name));
}

function getSectionTitle(section: AppSection): string {
  if (section === "movies") {
    return "Movies";
  }
  if (section === "series") {
    return "Series";
  }
  if (section === "favorites") {
    return "Favorites";
  }
  if (section === "recent") {
    return "Recently Watched";
  }
  if (section === "settings") {
    return "Settings";
  }

  return "Live TV";
}

function getAllCategoryLabel(section: AppSection): string {
  if (section === "movies") {
    return "All movies";
  }
  if (section === "series") {
    return "All series";
  }
  if (section === "favorites") {
    return "All favorites";
  }
  if (section === "recent") {
    return "All recently watched";
  }

  return "All live channels";
}

function getSearchPlaceholder(section: AppSection): string {
  if (section === "movies") {
    return "Search movies";
  }
  if (section === "series") {
    return "Search series";
  }
  if (section === "favorites") {
    return "Search favorites";
  }
  if (section === "recent") {
    return "Search recently watched";
  }

  return "Search live channels";
}

async function reloadCurrentSection(section: AppSection, data: ReturnType<typeof useAppData>): Promise<void> {
  if (section === "movies") {
    await data.reloadMovies();
  } else if (section === "series") {
    await data.reloadSeries();
  } else if (section === "recent") {
    await data.reloadRecentlyWatched();
  } else {
    await data.reloadChannels();
    await data.reloadMovies();
    await data.reloadSeries();
  }
}

function filterItemsByQuery(items: CatalogSectionItem[], query: string): CatalogSectionItem[] {
  const normalizedQuery = query.trim().toLowerCase();
  if (!normalizedQuery) {
    return items;
  }

  return items.filter((item) =>
    `${item.title} ${item.subtitle} ${item.eyebrow}`.toLowerCase().includes(normalizedQuery)
  );
}
