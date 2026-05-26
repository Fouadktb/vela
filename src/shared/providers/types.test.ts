import { describe, expect, it } from "vitest";
import {
  buildXtreamApiUrl,
  buildXtreamMovieStreamUrl,
  buildXtreamLiveStreamUrl,
  buildXtreamSeriesStreamUrl,
  buildXtreamM3uPlaylistUrl,
  validateCreateXtreamProviderInput
} from "./types.js";

describe("Xtream provider input", () => {
  it("normalizes login details and builds the live M3U playlist endpoint", () => {
    const input = validateCreateXtreamProviderInput({
      name: " Main TV ",
      serverUrl: "http://panel.example.test:8080/",
      username: "user name",
      password: "p@ss&word"
    });

    expect(input).toEqual({
      name: "Main TV",
      serverUrl: "http://panel.example.test:8080",
      username: "user name",
      password: "p@ss&word"
    });
    expect(buildXtreamM3uPlaylistUrl(input)).toBe(
      "http://panel.example.test:8080/get.php?username=user+name&password=p%40ss%26word&type=m3u_plus&output=ts"
    );
    expect(buildXtreamApiUrl(input, "get_live_streams")).toBe(
      "http://panel.example.test:8080/player_api.php?username=user+name&password=p%40ss%26word&action=get_live_streams"
    );
    expect(buildXtreamApiUrl(input, "get_series_info", { series_id: "789" })).toBe(
      "http://panel.example.test:8080/player_api.php?username=user+name&password=p%40ss%26word&action=get_series_info&series_id=789"
    );
    expect(buildXtreamLiveStreamUrl(input, "123", "ts")).toBe(
      "http://panel.example.test:8080/live/user%20name/p%40ss%26word/123.ts"
    );
    expect(buildXtreamMovieStreamUrl(input, "456", "mp4")).toBe(
      "http://panel.example.test:8080/movie/user%20name/p%40ss%26word/456.mp4"
    );
    expect(buildXtreamSeriesStreamUrl(input, "789", "mp4")).toBe(
      "http://panel.example.test:8080/series/user%20name/p%40ss%26word/789.mp4"
    );
  });

  it("rejects non-http servers and blank credentials", () => {
    expect(() =>
      validateCreateXtreamProviderInput({
        name: "Main TV",
        serverUrl: "ftp://panel.example.test",
        username: "user",
        password: "pass"
      })
    ).toThrow("Invalid Xtream provider input");

    expect(() =>
      validateCreateXtreamProviderInput({
        name: "Main TV",
        serverUrl: "https://panel.example.test",
        username: "user",
        password: " "
      })
    ).toThrow("Invalid Xtream provider input");
  });
});
