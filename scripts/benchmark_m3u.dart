import 'dart:io';

import 'package:vela/src/providers/m3u/m3u_parser.dart';

/// Run with `dart run scripts/benchmark_m3u.dart [series-count]`.
/// Reports the median of five runs after warmup; no network or database involved.
void main(List<String> arguments) {
  final seriesCount = arguments.isEmpty ? 10000 : int.parse(arguments.single);
  if (seriesCount < 1) throw ArgumentError.value(seriesCount, 'series-count');
  final playlist = StringBuffer('#EXTM3U\n');
  for (var index = 0; index < seriesCount; index += 1) {
    for (var episode = 1; episode <= 5; episode += 1) {
      playlist
        ..writeln('#EXTINF:-1 group-title="Series",Show $index S01E0$episode')
        ..writeln('https://example.test/series/$index/$episode.mp4');
    }
  }
  final input = playlist.toString();
  const parser = M3uParser();
  parser.parse(input, providerId: 'benchmark');
  final elapsed = <int>[];
  for (var iteration = 0; iteration < 5; iteration += 1) {
    final stopwatch = Stopwatch()..start();
    final result = parser.parse(input, providerId: 'benchmark');
    stopwatch.stop();
    if (result.snapshot.items.length != seriesCount ||
        result.snapshot.episodes.length != seriesCount * 5) {
      throw StateError('Benchmark catalog lost series or episodes');
    }
    elapsed.add(stopwatch.elapsedMicroseconds);
  }
  elapsed.sort();
  stdout.writeln(
    '${seriesCount * 5} episodes, $seriesCount series: '
    '${(elapsed[2] / 1000).toStringAsFixed(1)} ms median',
  );
}
