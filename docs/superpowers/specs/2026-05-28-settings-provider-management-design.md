# Settings provider management design

## Goal

Make Settings a clear provider management surface again. Users must be able to edit existing playlists/providers, including Xtream server URL, username, password, M3U URL, local file path, provider name, enabled state, and auto-refresh interval.

## Current issue

The current Settings provider cards are built from provider health data. That health stream intentionally redacts source and credential fields, so Settings can show provider status but cannot edit full provider connection details. The add-provider form is also embedded permanently in the right rail, which makes the page feel crowded and makes editing existing providers unclear.

## Design

Settings uses a two-pane provider management layout:

- Left pane: list configured providers using health data for status, counts, last refresh, and refresh state.
- Right pane: selected provider editor using full, non-redacted provider details from the repository.
- Add provider appears as an explicit mode/action, not as a permanently embedded form.
- Data and diagnostics remain available below the editor in a compact operations section.

## Provider editor behavior

The selected provider editor supports:

- editing display name
- editing provider source by provider type
- editing Xtream username and password
- changing auto-refresh interval
- toggling provider enabled state
- saving without changing provider id
- saving and refreshing immediately
- refreshing, clearing catalog, clearing recent history, and deleting

Provider health cards should not expose secrets. Full provider data is only loaded into the selected editor.

## Verification

Run formatting, `flutter analyze`, and a macOS build. Manual smoke path: open Settings, select a provider, confirm source/credentials fields are present, save, refresh, switch to Add provider mode, and return to the edited provider.
