const int defaultRefreshIntervalMinutes = 24 * 60;

class RefreshIntervalOption {
  const RefreshIntervalOption({required this.minutes, required this.label});

  final int minutes;
  final String label;
}

const refreshIntervalOptions = [
  RefreshIntervalOption(minutes: 60, label: 'Every hour'),
  RefreshIntervalOption(minutes: 3 * 60, label: 'Every 3 hours'),
  RefreshIntervalOption(minutes: 6 * 60, label: 'Every 6 hours'),
  RefreshIntervalOption(minutes: 12 * 60, label: 'Every 12 hours'),
  RefreshIntervalOption(minutes: 24 * 60, label: 'Every day'),
  RefreshIntervalOption(minutes: 2 * 24 * 60, label: 'Every 2 days'),
  RefreshIntervalOption(minutes: 3 * 24 * 60, label: 'Every 3 days'),
  RefreshIntervalOption(minutes: 7 * 24 * 60, label: 'Every week'),
];

int supportedRefreshIntervalMinutes(int minutes) {
  if (refreshIntervalOptions.any((option) => option.minutes == minutes)) {
    return minutes;
  }
  return defaultRefreshIntervalMinutes;
}

String refreshIntervalLabel(int minutes) {
  for (final option in refreshIntervalOptions) {
    if (option.minutes == minutes) {
      return option.label;
    }
  }
  return refreshIntervalLabel(defaultRefreshIntervalMinutes);
}
