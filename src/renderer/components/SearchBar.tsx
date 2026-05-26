import { Search } from "lucide-react";

interface SearchBarProps {
  query: string;
  placeholder: string;
  onQueryChange(query: string): void;
}

export function SearchBar({ query, placeholder, onQueryChange }: SearchBarProps) {
  return (
    <label className="search-bar">
      <Search size={18} aria-hidden="true" />
      <input
        value={query}
        onChange={(event) => onQueryChange(event.target.value)}
        placeholder={placeholder}
        aria-label={placeholder}
      />
    </label>
  );
}
