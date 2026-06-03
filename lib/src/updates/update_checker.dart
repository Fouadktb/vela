import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../app/app_version.dart';

final updateStatusProvider = FutureProvider<UpdateStatus>((ref) {
  return const GitHubUpdateChecker().check();
});

class UpdateStatus {
  const UpdateStatus({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseUrl,
    required this.hasUpdate,
    required this.checkedAt,
    this.androidApkUrl,
  });

  final String currentVersion;
  final String latestVersion;
  final String releaseUrl;
  final bool hasUpdate;
  final DateTime checkedAt;
  final String? androidApkUrl;
}

class GitHubUpdateChecker {
  const GitHubUpdateChecker();

  static final Uri _latestReleaseUri = Uri.https(
    'api.github.com',
    '/repos/$velaRepositoryOwner/$velaRepositoryName/releases/latest',
  );

  Future<UpdateStatus> check() async {
    final response = await http.get(
      _latestReleaseUri,
      headers: const {
        'Accept': 'application/vnd.github+json',
        'User-Agent': 'Vela/$velaVersion',
      },
    );

    if (response.statusCode != 200) {
      throw UpdateCheckException('GitHub returned HTTP ${response.statusCode}');
    }

    final body = jsonDecode(response.body);
    if (body is! Map<String, Object?>) {
      throw const UpdateCheckException('GitHub returned an invalid response');
    }

    final tag = body['tag_name'] as String?;
    final releaseUrl = body['html_url'] as String? ?? velaReleasesUrl;
    final androidApkUrl = _androidTvApkUrl(body['assets']);
    if (tag == null || tag.trim().isEmpty) {
      throw const UpdateCheckException('Latest release has no version tag');
    }

    return UpdateStatus(
      currentVersion: velaVersion,
      latestVersion: tag,
      releaseUrl: releaseUrl,
      hasUpdate: compareReleaseVersions(tag, velaReleaseTag) > 0,
      checkedAt: DateTime.now(),
      androidApkUrl: androidApkUrl,
    );
  }
}

class UpdateCheckException implements Exception {
  const UpdateCheckException(this.message);

  final String message;

  @override
  String toString() => message;
}

int compareReleaseVersions(String left, String right) {
  final leftParts = _releaseVersionParts(left);
  final rightParts = _releaseVersionParts(right);
  final length = leftParts.length > rightParts.length
      ? leftParts.length
      : rightParts.length;

  for (var index = 0; index < length; index += 1) {
    final leftValue = index < leftParts.length ? leftParts[index] : 0;
    final rightValue = index < rightParts.length ? rightParts[index] : 0;
    if (leftValue != rightValue) {
      return leftValue.compareTo(rightValue);
    }
  }
  return 0;
}

List<int> _releaseVersionParts(String value) {
  final normalized = value
      .trim()
      .replaceFirst(RegExp('^[vV]'), '')
      .split(RegExp(r'[-+]'))
      .first;
  return normalized
      .split('.')
      .map((part) => int.tryParse(part) ?? 0)
      .toList(growable: false);
}

String? _androidTvApkUrl(Object? assets) {
  if (assets is! List<Object?>) {
    return null;
  }

  for (final asset in assets) {
    if (asset is! Map<Object?, Object?>) {
      continue;
    }

    final name = asset['name'];
    final downloadUrl = asset['browser_download_url'];
    if (name is! String || downloadUrl is! String) {
      continue;
    }

    final normalizedName = name.toLowerCase();
    if (!normalizedName.endsWith('.apk') ||
        !normalizedName.contains('android-tv')) {
      continue;
    }

    final trimmedDownloadUrl = downloadUrl.trim();
    if (trimmedDownloadUrl.isEmpty) {
      continue;
    }
    return trimmedDownloadUrl;
  }

  return null;
}

Future<void> openExternalUrl(String url) async {
  final uri = Uri.tryParse(url.trim());
  if (uri == null || !_isValidExternalUrl(uri)) {
    throw const UpdateCheckException('Invalid update URL');
  }

  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      throw UpdateCheckException('Failed to open update URL: $url');
    }
  } on UpdateCheckException {
    rethrow;
  } catch (error) {
    throw UpdateCheckException('Failed to open update URL: $error');
  }
}

bool _isValidExternalUrl(Uri uri) {
  if (!uri.hasScheme) {
    return false;
  }

  final scheme = uri.scheme.toLowerCase();
  if ((scheme == 'http' || scheme == 'https') && uri.host.isEmpty) {
    return false;
  }
  return true;
}
