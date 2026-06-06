import 'provider_models.dart';
import 'refresh_interval.dart';

class ProviderInputValidation {
  const ProviderInputValidation({
    required this.input,
    required this.missingFields,
  });

  final ProviderInput input;
  final List<String> missingFields;

  bool get isValid => missingFields.isEmpty;

  String get message {
    if (missingFields.isEmpty) {
      return '';
    }
    return 'Fill in ${missingFields.join(', ')} before importing.';
  }
}

ProviderInputValidation validateProviderInput(ProviderInput input) {
  final normalized = normalizeProviderInput(input);
  final missing = <String>[];

  if (normalized.name.trim().isEmpty) {
    missing.add('provider name');
  }

  switch (normalized.type) {
    case ProviderType.xtream:
      if (normalized.serverUrl?.trim().isEmpty != false) {
        missing.add('server URL');
      }
      if (normalized.username?.trim().isEmpty != false) {
        missing.add('username');
      }
      if (normalized.password?.trim().isEmpty != false) {
        missing.add('password');
      }
    case ProviderType.m3uUrl:
      if (normalized.m3uUrl?.trim().isEmpty != false) {
        missing.add('M3U URL');
      }
    case ProviderType.m3uFile:
      if (normalized.localFilePath?.trim().isEmpty != false) {
        missing.add('M3U file');
      }
  }

  return ProviderInputValidation(input: normalized, missingFields: missing);
}

ProviderInput normalizeProviderInput(ProviderInput input) {
  final name = input.name.trim();
  final interval = _validRefreshInterval(input.refreshIntervalMinutes);
  return ProviderInput(
    id: input.id?.trim().isEmpty == true ? null : input.id?.trim(),
    name: name,
    type: input.type,
    serverUrl: input.type == ProviderType.xtream
        ? _normalizeUrl(input.serverUrl)
        : null,
    username: input.type == ProviderType.xtream
        ? _normalizeText(input.username)
        : null,
    password: input.type == ProviderType.xtream
        ? _normalizeText(input.password)
        : null,
    m3uUrl: input.type == ProviderType.m3uUrl
        ? _normalizeUrl(input.m3uUrl)
        : null,
    localFilePath: input.type == ProviderType.m3uFile
        ? _normalizeText(input.localFilePath)
        : null,
    isEnabled: input.isEnabled,
    refreshEnabled: input.refreshEnabled,
    refreshIntervalMinutes: interval,
  );
}

String? _normalizeText(String? value) {
  final clean = value?.trim();
  return clean == null || clean.isEmpty ? null : clean;
}

String? _normalizeUrl(String? value) {
  final clean = _normalizeText(value);
  if (clean == null) {
    return null;
  }
  final uri = Uri.tryParse(clean);
  if (uri == null || !uri.hasScheme) {
    return clean;
  }
  return uri.toString();
}

int _validRefreshInterval(int minutes) {
  for (final option in refreshIntervalOptions) {
    if (option.minutes == minutes) {
      return minutes;
    }
  }
  return defaultRefreshIntervalMinutes;
}
