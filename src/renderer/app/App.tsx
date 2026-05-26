import { useEffect, useMemo, useState } from "react";
import type { EpisodeView } from "../../shared/catalog/types";
import { Sidebar, type AppSection } from "../components/Sidebar";
import { SearchBar } from "../components/SearchBar";
import { CatalogDetailPane } from "../features/catalog/CatalogDetailPane";
import { CatalogGrid, type CatalogCardItem } from "../features/catalog/CatalogGrid";
import { PlayerControls } from "../features/playback/PlayerControls";
import { ProviderSetup } from "../features/providers/ProviderSetup";
import { ProviderSettings } from "../features/providers/ProviderSettings";
import { iptvApi } from "./api";
import { useAppData } from "./useAppData";

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
  const [isLoadingEpisodes, setIsLoadingEpisodes] = useState(false);
  const items = useMemo(() => buildCatalogItems(data), [data]);
  const visibleItems = useMemo(
    () => getSectionItems(activeSection, items, data.query),
    [activeSection, data.query, items]
  );
  const selectedItem = useMemo(
    () => visibleItems.find((item) => item.id === selectedItemId) ?? visibleItems[0] ?? null,
    [selectedItemId, visibleItems]
  );
  const categories = getSectionCategories(activeSection, data);
  const title = getSectionTitle(activeSection);
  const allCategoryLabel = getAllCategoryLabel(activeSection);
  const searchPlaceholder = getSearchPlaceholder(activeSection);
  const isSettingsSection = activeSection === "settings";
  const showCategorySelect = activeSection !== "settings" && activeSection !== "recent";

  function changeSection(nextSection: AppSection) {
    setActiveSection(nextSection);
    setSelectedItemId(null);
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
            onDelete={async (providerId) => {
              await iptvApi.providers.delete(providerId);
              await data.reloadAll();
            }}
          />
        ) : (
          <>
            {showCategorySelect ? (
              <label className="category-select">
                <span>Category</span>
                <select
                  value={data.category ?? ""}
                  onChange={(event) => data.setCategory(event.target.value || null)}
                >
                  <option value="">{allCategoryLabel}</option>
                  {categories.map((category) => (
                    <option key={category} value={category}>
                      {category || "Uncategorized"}
                    </option>
                  ))}
                </select>
              </label>
            ) : null}

            <div className="main-grid">
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
                isLoadingEpisodes={isLoadingEpisodes}
                onPlay={(itemId) => {
                  const item = visibleItems.find((candidate) => candidate.id === itemId);
                  if (item?.itemType === "live" || item?.itemType === "movie" || item?.itemType === "episode") {
                    void iptvApi.playback.play({ itemType: item.itemType, itemId });
                  }
                }}
                onPlayEpisode={(itemId) => {
                  void iptvApi.playback.play({ itemType: "episode", itemId });
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
      <PlayerControls />
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

function getSectionCategories(section: AppSection, data: ReturnType<typeof useAppData>): string[] {
  if (section === "movies") {
    return data.movieCategories;
  }
  if (section === "series") {
    return data.seriesCategories;
  }
  if (section === "favorites") {
    return Array.from(new Set([...data.categories, ...data.movieCategories, ...data.seriesCategories])).sort((a, b) =>
      a.localeCompare(b)
    );
  }
  if (section === "recent" || section === "settings") {
    return [];
  }

  return data.categories;
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
