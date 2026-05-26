import type { FormEvent } from "react";
import { useState } from "react";
import { Radio, UploadCloud } from "lucide-react";
import { iptvApi } from "../../app/api";

interface ProviderSetupProps {
  onCreated(): Promise<void>;
}

export function ProviderSetup({ onCreated }: ProviderSetupProps) {
  const [name, setName] = useState("My IPTV");
  const [source, setSource] = useState("");
  const [sourceKind, setSourceKind] = useState<"url" | "file">("url");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError(null);
    setIsSubmitting(true);

    try {
      await iptvApi.providers.createM3u({
        name: name.trim(),
        source: source.trim(),
        sourceKind
      });
      await onCreated();
    } catch (unknownError) {
      setError(unknownError instanceof Error ? unknownError.message : "Provider import failed");
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <form className="provider-setup" onSubmit={submit}>
      <div className="setup-icon" aria-hidden="true">
        <Radio size={22} />
      </div>
      <div>
        <p className="eyebrow">Provider setup</p>
        <h1>Add an M3U provider</h1>
        <p className="setup-copy">Paste an M3U URL or enter a local playlist path to import live channels.</p>
      </div>

      <label className="field">
        <span>Provider name</span>
        <input value={name} onChange={(event) => setName(event.target.value)} required maxLength={80} />
      </label>

      <label className="field">
        <span>Source type</span>
        <select value={sourceKind} onChange={(event) => setSourceKind(event.target.value as "url" | "file")}>
          <option value="url">M3U URL</option>
          <option value="file">Local file path</option>
        </select>
      </label>

      <label className="field">
        <span>M3U source</span>
        <input
          value={source}
          onChange={(event) => setSource(event.target.value)}
          placeholder={sourceKind === "url" ? "https://example.com/playlist.m3u" : "/Users/me/playlist.m3u"}
          required
        />
      </label>

      {error ? <div className="error" role="alert">{error}</div> : null}

      <button type="submit" disabled={isSubmitting || !name.trim() || !source.trim()}>
        <UploadCloud size={17} aria-hidden="true" />
        <span>{isSubmitting ? "Importing" : "Import provider"}</span>
      </button>
    </form>
  );
}
