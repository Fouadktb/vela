import { Clock, Heart, MonitorPlay, Settings, Tv, Video } from "lucide-react";

const disabledSections = [
  { label: "Movies", icon: Video },
  { label: "Series", icon: MonitorPlay },
  { label: "Favorites", icon: Heart },
  { label: "Recently Watched", icon: Clock },
  { label: "Settings", icon: Settings }
] as const;

export function Sidebar() {
  return (
    <aside className="sidebar">
      <div className="brand">
        <span className="brand-mark">IP</span>
        <span>IPTV Player</span>
      </div>
      <nav className="sidebar-nav" aria-label="Main navigation">
        <button className="nav-item active" type="button" aria-current="page">
          <Tv size={18} aria-hidden="true" />
          <span>Live TV</span>
        </button>
        {disabledSections.map(({ label, icon: Icon }) => (
          <button className="nav-item" type="button" disabled key={label}>
            <Icon size={18} aria-hidden="true" />
            <span>{label}</span>
          </button>
        ))}
      </nav>
    </aside>
  );
}
