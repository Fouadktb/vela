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
