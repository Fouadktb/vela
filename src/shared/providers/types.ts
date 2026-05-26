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
