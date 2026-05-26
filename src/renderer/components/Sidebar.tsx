import { Clock, Heart, MonitorPlay, Settings, Tv, Video } from "lucide-react";

export type AppSection = "live" | "movies" | "series" | "favorites" | "recent" | "settings";

interface SidebarProps {
  activeSection: AppSection;
  onSectionChange(section: AppSection): void;
}

export function Sidebar({ activeSection, onSectionChange }: SidebarProps) {
  return (
    <aside className="sidebar">
      <div className="brand">
        <span className="brand-mark">IP</span>
        <span>IPTV Player</span>
      </div>
      <nav className="sidebar-nav" aria-label="Main navigation">
        <button
          className={activeSection === "live" ? "nav-item active" : "nav-item"}
          type="button"
          aria-current={activeSection === "live" ? "page" : undefined}
          onClick={() => onSectionChange("live")}
        >
          <Tv size={18} aria-hidden="true" />
          <span>Live TV</span>
        </button>
        <button
          className={activeSection === "favorites" ? "nav-item active" : "nav-item"}
          type="button"
          aria-current={activeSection === "favorites" ? "page" : undefined}
          onClick={() => onSectionChange("favorites")}
        >
          <Heart size={18} aria-hidden="true" />
          <span>Favorites</span>
        </button>
        <button
          className={activeSection === "recent" ? "nav-item active" : "nav-item"}
          type="button"
          aria-current={activeSection === "recent" ? "page" : undefined}
          onClick={() => onSectionChange("recent")}
        >
          <Clock size={18} aria-hidden="true" />
          <span>Recently Watched</span>
        </button>
        <button
          className={activeSection === "movies" ? "nav-item active" : "nav-item"}
          type="button"
          aria-current={activeSection === "movies" ? "page" : undefined}
          onClick={() => onSectionChange("movies")}
        >
          <Video size={18} aria-hidden="true" />
          <span>Movies</span>
        </button>
        <button
          className={activeSection === "series" ? "nav-item active" : "nav-item"}
          type="button"
          aria-current={activeSection === "series" ? "page" : undefined}
          onClick={() => onSectionChange("series")}
        >
          <MonitorPlay size={18} aria-hidden="true" />
          <span>Series</span>
        </button>
        <button
          className={activeSection === "settings" ? "nav-item active" : "nav-item"}
          type="button"
          aria-current={activeSection === "settings" ? "page" : undefined}
          onClick={() => onSectionChange("settings")}
        >
          <Settings size={18} aria-hidden="true" />
          <span>Settings</span>
        </button>
      </nav>
    </aside>
  );
}
