import { Sidebar } from "../components/Sidebar";
import { SearchBar } from "../components/SearchBar";
import { LiveCatalog } from "../features/live/LiveCatalog";
import { LiveDetailPane } from "../features/live/LiveDetailPane";
import { ProviderSetup } from "../features/providers/ProviderSetup";
import { iptvApi } from "./api";
import { useAppData } from "./useAppData";

export function App() {
  const data = useAppData();

  if (data.providers.length === 0) {
    return (
      <main className="setup-screen">
        <ProviderSetup onCreated={data.reloadProviders} />
        {data.statusMessage ? <span className="status-pill setup-status">{data.statusMessage}</span> : null}
      </main>
    );
  }

  return (
    <main className="app-shell">
      <Sidebar />
      <section className="content">
        <header className="toolbar">
          <div>
            <p className="eyebrow">Catalog</p>
            <h1>Live TV</h1>
          </div>
          <SearchBar query={data.query} onQueryChange={data.setQuery} />
          {data.statusMessage ? <span className="status-pill">{data.statusMessage}</span> : null}
        </header>

        {data.errorMessage ? <div className="error banner">{data.errorMessage}</div> : null}

        <div className="category-row" aria-label="Live channel categories">
          <button className={data.category === null ? "chip active" : "chip"} type="button" onClick={() => data.setCategory(null)}>
            All
          </button>
          {data.categories.map((category) => (
            <button
              className={data.category === category ? "chip active" : "chip"}
              key={category}
              type="button"
              title={category}
              onClick={() => data.setCategory(category)}
            >
              {category || "Uncategorized"}
            </button>
          ))}
        </div>

        <div className="main-grid">
          <LiveCatalog
            channels={data.channels}
            selectedChannelId={data.selectedChannel?.id ?? null}
            isLoading={data.isLoading}
            onSelect={data.setSelectedChannelId}
          />
          <LiveDetailPane
            channel={data.selectedChannel}
            onPlay={(channel) => iptvApi.playback.play({ itemType: "live", itemId: channel.id })}
            onToggleFavorite={async (channel) => {
              await iptvApi.catalog.toggleFavorite(channel.id, "live");
              await data.reloadChannels();
            }}
            onRefresh={async () => {
              const provider = data.providers[0];
              if (provider) {
                await iptvApi.providers.refresh(provider.id);
              }
            }}
          />
        </div>
      </section>
    </main>
  );
}
