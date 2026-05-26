import type {
  Episode,
  LiveChannel,
  Movie,
  RecentlyWatchedItemView,
  Series
} from "../../../src/shared/catalog/types.js";
import type { SqliteDatabase } from "./database.js";

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

interface MovieRow {
  id: string;
  provider_id: string;
  title: string;
  poster_url: string | null;
  category: string;
  year: number | null;
  rating: string | null;
  stream_json: string;
  last_seen_at: string;
  is_favorite: 0 | 1;
}

interface SeriesRow {
  id: string;
  provider_id: string;
  title: string;
  poster_url: string | null;
  category: string;
  last_seen_at: string;
  is_favorite: 0 | 1;
}

interface EpisodeRow {
  id: string;
  provider_id: string;
  series_id: string;
  season_number: number;
  episode_number: number;
  title: string;
  duration_seconds: number | null;
  progress_seconds: number;
  stream_json: string;
  last_seen_at: string;
}

interface RecentlyWatchedRow {
  id: string;
  item_type: "live" | "movie" | "episode";
  provider_id: string;
  title: string;
  subtitle: string;
  artwork_url: string | null;
  last_watched_at: string;
}

export function createCatalogRepository(db: SqliteDatabase) {
  const upsertLiveChannelStatement = db.prepare(`
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
  const upsertMovieStatement = db.prepare(`
    INSERT INTO movies (
      id, provider_id, title, poster_url, category, year, rating, stream_json, last_seen_at, stale
    ) VALUES (
      @id, @providerId, @title, @posterUrl, @category, @year, @rating, @streamJson, @lastSeenAt, 0
    )
    ON CONFLICT(id) DO UPDATE SET
      title = excluded.title,
      poster_url = excluded.poster_url,
      category = excluded.category,
      year = excluded.year,
      rating = excluded.rating,
      stream_json = excluded.stream_json,
      last_seen_at = excluded.last_seen_at,
      stale = 0
  `);
  const upsertSeriesStatement = db.prepare(`
    INSERT INTO series (
      id, provider_id, title, poster_url, category, last_seen_at, stale
    ) VALUES (
      @id, @providerId, @title, @posterUrl, @category, @lastSeenAt, 0
    )
    ON CONFLICT(id) DO UPDATE SET
      title = excluded.title,
      poster_url = excluded.poster_url,
      category = excluded.category,
      last_seen_at = excluded.last_seen_at,
      stale = 0
  `);
  const upsertEpisodeStatement = db.prepare(`
    INSERT INTO episodes (
      id, provider_id, series_id, season_number, episode_number, title, duration_seconds, progress_seconds, stream_json, last_seen_at, stale
    ) VALUES (
      @id, @providerId, @seriesId, @seasonNumber, @episodeNumber, @title, @durationSeconds, @progressSeconds, @streamJson, @lastSeenAt, 0
    )
    ON CONFLICT(id) DO UPDATE SET
      series_id = excluded.series_id,
      season_number = excluded.season_number,
      episode_number = excluded.episode_number,
      title = excluded.title,
      duration_seconds = excluded.duration_seconds,
      stream_json = excluded.stream_json,
      last_seen_at = excluded.last_seen_at,
      stale = 0
  `);

  const runLiveChannelUpserts = (channels: LiveChannel[]) => {
    for (const item of channels) {
      upsertLiveChannelStatement.run({
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
  };
  const runMovieUpserts = (movies: Movie[]) => {
    for (const item of movies) {
      upsertMovieStatement.run({
        id: item.id,
        providerId: item.providerId,
        title: item.title,
        posterUrl: item.posterUrl,
        category: item.category,
        year: item.year,
        rating: item.rating,
        streamJson: JSON.stringify(item.stream),
        lastSeenAt: item.lastSeenAt
      });
    }
  };
  const runSeriesUpserts = (seriesItems: Series[]) => {
    for (const item of seriesItems) {
      upsertSeriesStatement.run({
        id: item.id,
        providerId: item.providerId,
        title: item.title,
        posterUrl: item.posterUrl,
        category: item.category,
        lastSeenAt: item.lastSeenAt
      });
    }
  };
  const runEpisodeUpserts = (episodes: Episode[], lastSeenAt: string) => {
    for (const item of episodes) {
      upsertEpisodeStatement.run({
        id: item.id,
        providerId: item.providerId,
        seriesId: item.seriesId,
        seasonNumber: item.seasonNumber,
        episodeNumber: item.episodeNumber,
        title: item.title,
        durationSeconds: item.durationSeconds,
        progressSeconds: item.progressSeconds,
        streamJson: JSON.stringify(item.stream),
        lastSeenAt
      });
    }
  };

  return {
    upsertLiveChannels(channels: LiveChannel[]): void {
      const transaction = db.transaction((items: LiveChannel[]) => {
        runLiveChannelUpserts(items);
      });

      transaction(channels);
    },
    replaceLiveChannelsForProvider(providerId: string, channels: LiveChannel[]): void {
      const transaction = db.transaction((items: LiveChannel[]) => {
        for (const item of items) {
          if (item.providerId !== providerId) {
            throw new Error("Cannot replace live channels across providers");
          }
        }

        db.prepare("UPDATE live_channels SET stale = 1 WHERE provider_id = ?").run(providerId);
        runLiveChannelUpserts(items);
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
          AND (lower(name) LIKE ? OR lower(category) LIKE ?)
          AND (? IS NULL OR category = ?)
        ORDER BY is_favorite DESC, name ASC
      `).all(normalizedQuery, normalizedQuery, category, category) as LiveChannelRow[];

      return rows.map(toLiveChannel);
    },
    listLiveCategories(): string[] {
      const rows = db.prepare(`
        SELECT category
        FROM live_channels
        WHERE stale = 0
          AND trim(category) <> ''
        GROUP BY category
        ORDER BY lower(category) ASC
      `).all() as Array<{ category: string }>;

      return rows.map((row) => row.category);
    },
    replaceMoviesForProvider(providerId: string, movies: Movie[]): void {
      const transaction = db.transaction((items: Movie[]) => {
        for (const item of items) {
          if (item.providerId !== providerId) {
            throw new Error("Cannot replace movies across providers");
          }
        }

        db.prepare("UPDATE movies SET stale = 1 WHERE provider_id = ?").run(providerId);
        runMovieUpserts(items);
      });

      transaction(movies);
    },
    listMovies(query: string, category: string | null): Movie[] {
      const normalizedQuery = `%${query.trim().toLowerCase()}%`;
      const rows = db.prepare(`
        SELECT
          movies.*,
          CASE WHEN favorites.item_id IS NULL THEN 0 ELSE 1 END AS is_favorite
        FROM movies
        LEFT JOIN favorites
          ON favorites.item_id = movies.id
          AND favorites.item_type = 'movie'
        WHERE stale = 0
          AND (lower(title) LIKE ? OR lower(category) LIKE ?)
          AND (? IS NULL OR category = ?)
        ORDER BY is_favorite DESC, title ASC
      `).all(normalizedQuery, normalizedQuery, category, category) as MovieRow[];

      return rows.map(toMovie);
    },
    listMovieCategories(): string[] {
      return listCategories("movies");
    },
    getMovie(itemId: string): Movie | null {
      const row = db.prepare(`
        SELECT
          movies.*,
          CASE WHEN favorites.item_id IS NULL THEN 0 ELSE 1 END AS is_favorite
        FROM movies
        LEFT JOIN favorites
          ON favorites.item_id = movies.id
          AND favorites.item_type = 'movie'
        WHERE movies.id = ?
          AND stale = 0
      `).get(itemId) as MovieRow | undefined;

      return row ? toMovie(row) : null;
    },
    replaceSeriesForProvider(providerId: string, seriesItems: Series[]): void {
      const transaction = db.transaction((items: Series[]) => {
        for (const item of items) {
          if (item.providerId !== providerId) {
            throw new Error("Cannot replace series across providers");
          }
        }

        db.prepare("UPDATE series SET stale = 1 WHERE provider_id = ?").run(providerId);
        runSeriesUpserts(items);
      });

      transaction(seriesItems);
    },
    listSeries(query: string, category: string | null): Series[] {
      const normalizedQuery = `%${query.trim().toLowerCase()}%`;
      const rows = db.prepare(`
        SELECT
          series.*,
          CASE WHEN favorites.item_id IS NULL THEN 0 ELSE 1 END AS is_favorite
        FROM series
        LEFT JOIN favorites
          ON favorites.item_id = series.id
          AND favorites.item_type = 'series'
        WHERE stale = 0
          AND (lower(title) LIKE ? OR lower(category) LIKE ?)
          AND (? IS NULL OR category = ?)
        ORDER BY is_favorite DESC, title ASC
      `).all(normalizedQuery, normalizedQuery, category, category) as SeriesRow[];

      return rows.map(toSeries);
    },
    listSeriesCategories(): string[] {
      return listCategories("series");
    },
    getSeries(itemId: string): Series | null {
      const row = db.prepare(`
        SELECT
          series.*,
          CASE WHEN favorites.item_id IS NULL THEN 0 ELSE 1 END AS is_favorite
        FROM series
        LEFT JOIN favorites
          ON favorites.item_id = series.id
          AND favorites.item_type = 'series'
        WHERE series.id = ?
          AND stale = 0
      `).get(itemId) as SeriesRow | undefined;

      return row ? toSeries(row) : null;
    },
    replaceEpisodesForSeries(providerId: string, seriesId: string, episodes: Episode[]): void {
      const transaction = db.transaction((items: Episode[]) => {
        for (const item of items) {
          if (item.providerId !== providerId || item.seriesId !== seriesId) {
            throw new Error("Cannot replace episodes across providers or series");
          }
        }

        db.prepare("UPDATE episodes SET stale = 1 WHERE provider_id = ? AND series_id = ?").run(providerId, seriesId);
        runEpisodeUpserts(items, new Date().toISOString());
      });

      transaction(episodes);
    },
    listEpisodesForSeries(seriesId: string): Episode[] {
      const rows = db.prepare(`
        SELECT *
        FROM episodes
        WHERE series_id = ?
          AND stale = 0
        ORDER BY season_number ASC, episode_number ASC, lower(title) ASC
      `).all(seriesId) as EpisodeRow[];

      return rows.map(toEpisode);
    },
    getEpisode(itemId: string): Episode | null {
      const row = db.prepare(`
        SELECT *
        FROM episodes
        WHERE id = ?
          AND stale = 0
      `).get(itemId) as EpisodeRow | undefined;

      return row ? toEpisode(row) : null;
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
          AND stale = 0
      `).get(itemId) as LiveChannelRow | undefined;

      return row ? toLiveChannel(row) : null;
    },
    toggleFavorite(itemId: string, itemType: "live" | "movie" | "series"): void {
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
    markRecentlyWatched(itemId: string, itemType: "live" | "movie" | "episode"): void {
      db.prepare(`
        INSERT INTO recently_watched (item_id, item_type, last_watched_at)
        VALUES (?, ?, ?)
        ON CONFLICT(item_id, item_type) DO UPDATE SET last_watched_at = excluded.last_watched_at
      `).run(itemId, itemType, new Date().toISOString());
    },
    listRecentlyWatched(): RecentlyWatchedItemView[] {
      const rows = db.prepare(`
        SELECT
          live_channels.id AS id,
          'live' AS item_type,
          live_channels.provider_id AS provider_id,
          live_channels.name AS title,
          coalesce(nullif(trim(live_channels.category), ''), 'Uncategorized') AS subtitle,
          live_channels.logo_url AS artwork_url,
          recently_watched.last_watched_at AS last_watched_at
        FROM recently_watched
        JOIN live_channels
          ON live_channels.id = recently_watched.item_id
          AND recently_watched.item_type = 'live'
          AND live_channels.stale = 0

        UNION ALL

        SELECT
          movies.id AS id,
          'movie' AS item_type,
          movies.provider_id AS provider_id,
          movies.title AS title,
          trim(
            coalesce(nullif(trim(movies.category), ''), '') ||
            CASE
              WHEN movies.year IS NULL THEN ''
              WHEN trim(movies.category) = '' THEN CAST(movies.year AS TEXT)
              ELSE ' | ' || movies.year
            END ||
            CASE
              WHEN movies.rating IS NULL OR trim(movies.rating) = '' THEN ''
              WHEN trim(movies.category) = '' AND movies.year IS NULL THEN 'Rating ' || movies.rating
              ELSE ' | Rating ' || movies.rating
            END
          ) AS subtitle,
          movies.poster_url AS artwork_url,
          recently_watched.last_watched_at AS last_watched_at
        FROM recently_watched
        JOIN movies
          ON movies.id = recently_watched.item_id
          AND recently_watched.item_type = 'movie'
          AND movies.stale = 0

        UNION ALL

        SELECT
          episodes.id AS id,
          'episode' AS item_type,
          episodes.provider_id AS provider_id,
          episodes.title AS title,
          'S' || episodes.season_number || ' E' || episodes.episode_number || ' | ' || coalesce(series.title, 'Series') AS subtitle,
          series.poster_url AS artwork_url,
          recently_watched.last_watched_at AS last_watched_at
        FROM recently_watched
        JOIN episodes
          ON episodes.id = recently_watched.item_id
          AND recently_watched.item_type = 'episode'
          AND episodes.stale = 0
        LEFT JOIN series
          ON series.id = episodes.series_id

        ORDER BY last_watched_at DESC
        LIMIT 300
      `).all() as RecentlyWatchedRow[];

      return rows.map(toRecentlyWatchedItemView);
    }
  };

  function listCategories(tableName: "movies" | "series"): string[] {
    const rows = db.prepare(`
      SELECT category
      FROM ${tableName}
      WHERE stale = 0
        AND trim(category) <> ''
      GROUP BY category
      ORDER BY lower(category) ASC
    `).all() as Array<{ category: string }>;

    return rows.map((row) => row.category);
  }
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

function toMovie(row: MovieRow): Movie {
  return {
    type: "movie",
    id: row.id,
    providerId: row.provider_id,
    title: row.title,
    posterUrl: row.poster_url,
    category: row.category,
    year: row.year,
    rating: row.rating,
    stream: JSON.parse(row.stream_json) as Movie["stream"],
    lastSeenAt: row.last_seen_at,
    isFavorite: row.is_favorite === 1
  };
}

function toSeries(row: SeriesRow): Series {
  return {
    type: "series",
    id: row.id,
    providerId: row.provider_id,
    title: row.title,
    posterUrl: row.poster_url,
    category: row.category,
    lastSeenAt: row.last_seen_at,
    isFavorite: row.is_favorite === 1
  };
}

function toEpisode(row: EpisodeRow): Episode {
  return {
    type: "episode",
    id: row.id,
    providerId: row.provider_id,
    seriesId: row.series_id,
    seasonNumber: row.season_number,
    episodeNumber: row.episode_number,
    title: row.title,
    durationSeconds: row.duration_seconds,
    progressSeconds: row.progress_seconds,
    stream: JSON.parse(row.stream_json) as Episode["stream"]
  };
}

function toRecentlyWatchedItemView(row: RecentlyWatchedRow): RecentlyWatchedItemView {
  return {
    id: row.id,
    itemType: row.item_type,
    providerId: row.provider_id,
    title: row.title,
    subtitle: row.subtitle,
    artworkUrl: row.artwork_url,
    lastWatchedAt: row.last_watched_at
  };
}
