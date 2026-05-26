import { RefreshCw, Trash2 } from "lucide-react";
import { useState } from "react";
import type { ProviderSummary } from "../../../shared/providers/types";
import { ProviderSetup } from "./ProviderSetup";

interface ProviderSettingsProps {
  providers: ProviderSummary[];
  onCreated(): Promise<void>;
  onRefresh(providerId: string): Promise<void>;
  onDelete(providerId: string): Promise<void>;
}

export function ProviderSettings({ providers, onCreated, onRefresh, onDelete }: ProviderSettingsProps) {
  const [pendingProviderId, setPendingProviderId] = useState<string | null>(null);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  async function runProviderAction(providerId: string, action: () => Promise<void>) {
    setErrorMessage(null);
    setPendingProviderId(providerId);
    try {
      await action();
    } catch (error) {
      setErrorMessage(error instanceof Error ? error.message : "Provider action failed");
    } finally {
      setPendingProviderId(null);
    }
  }

  function requestDelete(provider: ProviderSummary) {
    const shouldDelete = window.confirm(
      `Delete ${provider.name}? This removes its imported catalog, favorites, and recently watched items.`
    );
    if (shouldDelete) {
      void runProviderAction(provider.id, () => onDelete(provider.id));
    }
  }

  return (
    <div className="settings-layout">
      <section className="settings-panel">
        <div className="settings-panel-heading">
          <p className="eyebrow">Providers</p>
          <h2>{providers.length} configured</h2>
        </div>
        {errorMessage ? <div className="error banner">{errorMessage}</div> : null}
        <div className="provider-list">
          {providers.map((provider) => (
            <article className="provider-row" key={provider.id}>
              <div>
                <strong>{provider.name}</strong>
                <span>{provider.type === "xtream" ? "Xtream Codes" : "M3U playlist"}</span>
                <small>{provider.lastRefreshAt ? `Last refresh ${formatProviderDate(provider.lastRefreshAt)}` : "Not refreshed yet"}</small>
              </div>
              <div className="provider-actions">
                <button
                  className="icon-button"
                  type="button"
                  title="Refresh provider"
                  aria-label={`Refresh ${provider.name}`}
                  disabled={pendingProviderId === provider.id}
                  onClick={() => void runProviderAction(provider.id, () => onRefresh(provider.id))}
                >
                  <RefreshCw size={17} aria-hidden="true" />
                </button>
                <button
                  className="icon-button danger"
                  type="button"
                  title="Delete provider"
                  aria-label={`Delete ${provider.name}`}
                  disabled={pendingProviderId === provider.id}
                  onClick={() => requestDelete(provider)}
                >
                  <Trash2 size={17} aria-hidden="true" />
                </button>
              </div>
            </article>
          ))}
        </div>
      </section>

      <section className="settings-panel setup-panel">
        <ProviderSetup onCreated={onCreated} />
      </section>
    </div>
  );
}

function formatProviderDate(value: string): string {
  return new Intl.DateTimeFormat(undefined, {
    dateStyle: "medium",
    timeStyle: "short"
  }).format(new Date(value));
}
