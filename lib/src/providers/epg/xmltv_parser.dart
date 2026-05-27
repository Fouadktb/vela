import 'package:xml/xml.dart';

import '../../catalog/catalog_models.dart';

class XmltvParser {
  const XmltvParser();

  List<EpgProgramInput> parse(
    String input, {
    required String providerId,
    required DateTime now,
    Duration pastWindow = const Duration(hours: 3),
    Duration futureWindow = const Duration(days: 7),
  }) {
    final document = XmlDocument.parse(input);
    final fromMs = now.subtract(pastWindow).millisecondsSinceEpoch;
    final toMs = now.add(futureWindow).millisecondsSinceEpoch;
    final programs = <EpgProgramInput>[];

    for (final node in document.findAllElements('programme')) {
      final channelId = node.getAttribute('channel')?.trim();
      final startAt = _xmltvDate(node.getAttribute('start'));
      final endAt = _xmltvDate(node.getAttribute('stop'));
      final title = _childText(node, 'title');
      if (channelId == null ||
          channelId.isEmpty ||
          startAt == null ||
          endAt == null ||
          endAt.millisecondsSinceEpoch <= startAt.millisecondsSinceEpoch ||
          endAt.millisecondsSinceEpoch < fromMs ||
          startAt.millisecondsSinceEpoch > toMs ||
          title == null ||
          title.isEmpty) {
        continue;
      }

      programs.add(
        EpgProgramInput(
          providerId: providerId,
          channelId: channelId,
          startAtMs: startAt.millisecondsSinceEpoch,
          endAtMs: endAt.millisecondsSinceEpoch,
          title: title,
          description: _childText(node, 'desc'),
          category: _childText(node, 'category'),
        ),
      );
    }

    programs.sort((a, b) {
      final channelCompare = a.channelId.compareTo(b.channelId);
      if (channelCompare != 0) return channelCompare;
      return a.startAtMs.compareTo(b.startAtMs);
    });
    return programs;
  }
}

String? _childText(XmlElement element, String name) {
  final child = element.findElements(name).firstOrNull;
  final text = child?.innerText.trim();
  return text == null || text.isEmpty ? null : text;
}

DateTime? _xmltvDate(String? value) {
  final clean = value?.trim();
  if (clean == null || clean.length < 14) {
    return null;
  }
  final match = RegExp(
    r'^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})(?:\s*([+-])(\d{2})(\d{2}))?',
  ).firstMatch(clean);
  if (match == null) {
    return null;
  }

  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final hour = int.parse(match.group(4)!);
  final minute = int.parse(match.group(5)!);
  final second = int.parse(match.group(6)!);
  var date = DateTime.utc(year, month, day, hour, minute, second);
  final sign = match.group(7);
  final offsetHours = int.tryParse(match.group(8) ?? '');
  final offsetMinutes = int.tryParse(match.group(9) ?? '');
  if (sign != null && offsetHours != null && offsetMinutes != null) {
    final offset = Duration(hours: offsetHours, minutes: offsetMinutes);
    date = sign == '+' ? date.subtract(offset) : date.add(offset);
  }
  return date.toLocal();
}
