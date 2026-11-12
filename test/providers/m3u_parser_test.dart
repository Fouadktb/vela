import 'package:flutter_test/flutter_test.dart';
import 'package:vela/src/catalog/catalog_models.dart';
import 'package:vela/src/providers/m3u/m3u_parser.dart';

void main() {
  const parser = M3uParser();

  test('handles BOM, quoted commas, CRLF and classic CR line endings', () {
    for (final separator in ['\n', '\r\n', '\r']) {
      final result = parser.parse(
        [
          '\uFEFF#EXTM3U',
          '#EXTINF:-1 tvg-id="news" tvg-name="News, World" group-title="Live, News",Fallback',
          'https://example.test/live/news.ts',
        ].join(separator),
        providerId: 'provider',
      );
      expect(result.diagnostics, isEmpty);
      expect(result.entries.single.title, 'News, World');
      expect(result.entries.single.categoryName, 'Live, News');
      expect(result.snapshot.items.single.id, 'provider:live:news');
    }
  });

  test(
    'deduplicates series while preserving all episodes and first artwork',
    () {
      final result = parser.parse('''#EXTM3U
#EXTINF:-1 tvg-logo="first.png" group-title="Shows",Example S01E01
https://example.test/series/1.mp4
#EXTINF:-1 tvg-logo="second.png" group-title="Shows",Example S01E02
https://example.test/series/2.mp4
#EXTINF:-1 group-title="Shows",Example S02E01
https://example.test/series/3.mp4
#EXTINF:-1 group-title="Live",News
https://example.test/live/1.ts
''', providerId: 'provider');
      final snapshot = result.snapshot;
      expect(snapshot.items, hasLength(2));
      expect(snapshot.items.first.id, 'provider:series:example');
      expect(snapshot.items.first.artworkUrl, 'first.png');
      expect(snapshot.series, hasLength(1));
      expect(snapshot.seasons, hasLength(2));
      expect(snapshot.episodes, hasLength(3));
      expect(snapshot.episodes.map((episode) => episode.episodeNumber), [
        1,
        2,
        1,
      ]);
      expect(snapshot.items.last.contentType, CatalogContentType.live);
    },
  );

  test('large mixed catalogs retain unique series and complete episodes', () {
    final playlist = StringBuffer('#EXTM3U\n');
    // Mixed live entries used to lengthen a linear catalog scan on every episode.
    for (var index = 0; index < 4000; index += 1) {
      playlist
        ..writeln('#EXTINF:-1,News $index')
        ..writeln('https://example.test/live/$index.ts');
    }
    for (var series = 0; series < 2000; series += 1) {
      for (var episode = 1; episode <= 3; episode += 1) {
        playlist
          ..writeln('#EXTINF:-1,Show $series S01E0$episode')
          ..writeln('https://example.test/series/$series/$episode.mp4');
      }
    }
    final result = parser.parse(playlist.toString(), providerId: 'provider');
    expect(result.diagnostics, isEmpty);
    expect(result.entries, hasLength(10000));
    expect(result.snapshot.items, hasLength(6000));
    expect(result.snapshot.series, hasLength(2000));
    expect(result.snapshot.seasons, hasLength(2000));
    expect(result.snapshot.episodes, hasLength(6000));
    expect(
      result.snapshot.items.map((item) => item.id).toSet(),
      hasLength(6000),
    );
  });

  test(
    'stream parsing matches text parsing and keeps duplicate IDs distinct',
    () async {
      const playlist = '''#EXTM3U
#EXTINF:-1 tvg-id="same",News
https://example.test/live/1.ts
#EXTINF:-1 tvg-id="same",News
https://example.test/live/2.ts
#EXTINF:-1,Missing URL''';
      final text = parser.parse(playlist, providerId: 'provider');
      final streamed = await parser.parseStream(
        Stream.fromIterable(playlist.split('\n')),
        providerId: 'provider',
      );
      expect(text.entries.map((entry) => entry.id), [
        'provider:live:same',
        'provider:live:same-2',
      ]);
      expect(
        streamed.entries.map((entry) => entry.id),
        text.entries.map((entry) => entry.id),
      );
      expect(streamed.diagnostics.single.line, text.diagnostics.single.line);
      expect(
        streamed.diagnostics.single.message,
        'EXTINF entry has no following stream URL',
      );
    },
  );
}
