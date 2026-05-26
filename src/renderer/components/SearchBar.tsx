import { Search } from "lucide-react";

interface SearchBarProps {
  query: string;
  onQueryChange(query: string): void;
}

export function SearchBar({ query, onQueryChange }: SearchBarProps) {
  return (
    <label className="search-bar">
      <Search size={18} aria-hidden="true" />
      <input
        value={query}
        onChange={(event) => onQueryChange(event.target.value)}
        placeholder="Search live channels"
        aria-label="Search live channels"
      />
    </label>
  );
}
