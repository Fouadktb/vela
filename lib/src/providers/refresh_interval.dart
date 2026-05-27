const int maxRefreshIntervalHours = 168;

String refreshIntervalHoursText(int minutes) {
  final hours = minutes / 60;
  if (hours == hours.roundToDouble()) {
    return hours.round().toString();
  }
  return hours.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
}

int? parseRefreshIntervalHours(String value) {
  final hours = double.tryParse(value.trim().replaceAll(',', '.'));
  if (hours == null || hours <= 0 || hours > maxRefreshIntervalHours) {
    return null;
  }
  return (hours * 60).round().clamp(1, maxRefreshIntervalHours * 60);
}

String? validateRefreshIntervalHours(String? value) {
  final parsed = parseRefreshIntervalHours(value ?? '');
  if (parsed == null) {
    return 'Enter hours between 1 and $maxRefreshIntervalHours';
  }
  return null;
}
