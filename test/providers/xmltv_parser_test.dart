import 'package:flutter_test/flutter_test.dart';
import 'package:vela/src/providers/epg/xmltv_parser.dart';

void main() {
  test(
    'filters programme windows and preserves text across channel aliases',
    () {
      final programs = const XmltvParser().parse(
        '''<?xml version="1.0"?>
<tv>
  <channel id="news"><display-name>News HD</display-name><display-name>news</display-name></channel>
  <programme channel="news" start="20261113120000 +0200" stop="20261113130000 +0200">
    <title>News &amp; Weather</title><desc>Today's &lt;headlines&gt;</desc><category>News</category>
  </programme>
  <programme channel="news" start="20261101120000 +0000" stop="20261101130000 +0000"><title>Expired</title></programme>
  <programme channel="news" start="20261201120000 +0000" stop="20261201130000 +0000"><title>Future</title></programme>
  <programme channel="news" start="20261113120000 +0000" stop="20261113110000 +0000"><title>Invalid</title></programme>
  <programme channel="news" start="20261113120000 +0000" stop="20261113130000 +0000"><title> </title></programme>
</tv>''',
        providerId: 'provider',
        now: DateTime.utc(2026, 11, 13, 10),
      );
      expect(programs, hasLength(2));
      expect(programs.map((program) => program.channelId), ['News HD', 'news']);
      for (final program in programs) {
        expect(program.title, 'News & Weather');
        expect(program.description, "Today's <headlines>");
        expect(program.category, 'News');
        expect(
          program.startAtMs,
          DateTime.utc(2026, 11, 13, 10).millisecondsSinceEpoch,
        );
        expect(
          program.endAtMs,
          DateTime.utc(2026, 11, 13, 11).millisecondsSinceEpoch,
        );
      }
    },
  );
}
