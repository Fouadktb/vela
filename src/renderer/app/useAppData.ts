import { useCallback, useEffect, useMemo, useState } from "react";
import type { LiveChannelView } from "../../shared/catalog/types";
import type { ProviderSummary } from "../../shared/providers/types";
import { iptvApi } from "./api";

export function useAppData() {
  const [providers, setProviders] = useState<ProviderSummary[]>([]);
  const [channels, setChannels] = useState<LiveChannelView[]>([]);
  const [query, setQuery] = useState("");
  const [category, setCategory] = useState<string | null>(null);
  const [selectedChannelId, setSelectedChannelId] = useState<string | null>(null);
  const [statusMessage, setStatusMessage] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const categories = useMemo(
    () => Array.from(new Set(channels.map((channel) => channel.category).filter(Boolean))).sort((a, b) => a.localeCompare(b)),
    [channels]
  );

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

      if (progress.phase === "failed") {
        setErrorMessage(progress.message);
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
    isLoading,
    errorMessage,
    reloadChannels,
    reloadProviders
  };
}
