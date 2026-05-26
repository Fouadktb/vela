import { describe, expect, it } from "vitest";
import { getSeekSecondsForDoubleClick } from "./playerGestures";

describe("getSeekSecondsForDoubleClick", () => {
  it("returns -10 seconds for seekable double clicks on the left half", () => {
    expect(getSeekSecondsForDoubleClick({ clientX: 40, left: 0, width: 100, isSeekable: true })).toBe(-10);
  });

  it("returns 10 seconds for seekable double clicks on the right half", () => {
    expect(getSeekSecondsForDoubleClick({ clientX: 60, left: 0, width: 100, isSeekable: true })).toBe(10);
  });

  it("returns 0 seconds when playback is not seekable", () => {
    expect(getSeekSecondsForDoubleClick({ clientX: 60, left: 0, width: 100, isSeekable: false })).toBe(0);
  });
});
