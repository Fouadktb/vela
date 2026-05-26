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
  const [sourceKind, setSourceKind] = useState<"url" | "file" | "xtream">("url");
  const [serverUrl, setServerUrl] = useState("");
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const isXtream = sourceKind === "xtream";
  const isSubmitDisabled =
    isSubmitting ||
    !name.trim() ||
    (isXtream ? !serverUrl.trim() || !username.trim() || !password.trim() : !source.trim());

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError(null);
    setIsSubmitting(true);

    try {
      if (isXtream) {
        await iptvApi.providers.createXtream({
          name: name.trim(),
          serverUrl: serverUrl.trim(),
          username: username.trim(),
          password: password.trim()
        });
      } else {
        await iptvApi.providers.createM3u({
          name: name.trim(),
          source: source.trim(),
          sourceKind
        });
      }
      await onCreated();
      setName("My IPTV");
      setSource("");
      setServerUrl("");
      setUsername("");
      setPassword("");
    } catch (unknownError) {
      setError(toProviderSetupErrorMessage(unknownError));
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
        <h1>{isXtream ? "Add an Xtream provider" : "Add an M3U provider"}</h1>
        <p className="setup-copy">
          {isXtream
            ? "Enter your Xtream Codes server URL, username, and password to import your catalog."
            : "Paste an M3U URL or enter a local playlist path to import live channels."}
        </p>
      </div>

      <label className="field">
        <span>Provider name</span>
        <input value={name} onChange={(event) => setName(event.target.value)} required maxLength={80} />
      </label>

      <label className="field">
        <span>Source type</span>
        <select value={sourceKind} onChange={(event) => setSourceKind(event.target.value as "url" | "file" | "xtream")}>
          <option value="url">M3U URL</option>
          <option value="xtream">Xtream Codes</option>
          <option value="file">Local file path</option>
        </select>
      </label>

      {isXtream ? (
        <>
          <label className="field">
            <span>Server URL</span>
            <input
              value={serverUrl}
              onChange={(event) => setServerUrl(event.target.value)}
              placeholder="http://example.com:8080"
              required
            />
          </label>
          <label className="field">
            <span>Username</span>
            <input value={username} onChange={(event) => setUsername(event.target.value)} required />
          </label>
          <label className="field">
            <span>Password</span>
            <input
              type="password"
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              autoComplete="current-password"
              required
            />
          </label>
        </>
      ) : (
        <label className="field">
          <span>M3U source</span>
          <input
            value={source}
            onChange={(event) => setSource(event.target.value)}
            placeholder={sourceKind === "url" ? "https://example.com/playlist.m3u" : "/Users/me/playlist.m3u"}
            required
          />
        </label>
      )}

      {error ? <div className="error" role="alert">{error}</div> : null}

      <button type="submit" disabled={isSubmitDisabled}>
        <UploadCloud size={17} aria-hidden="true" />
        <span>{isSubmitting ? "Importing" : "Import provider"}</span>
      </button>
    </form>
  );
}

function toProviderSetupErrorMessage(error: unknown): string {
  if (!(error instanceof Error)) {
    return "Provider import failed";
  }

  return error.message.replace(/^Error invoking remote method '[^']+': Error: /, "");
}
