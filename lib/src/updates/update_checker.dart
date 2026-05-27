import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

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
  });

  final String currentVersion;
  final String latestVersion;
  final String releaseUrl;
  final bool hasUpdate;
  final DateTime checkedAt;
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
    if (tag == null || tag.trim().isEmpty) {
      throw const UpdateCheckException('Latest release has no version tag');
    }

    return UpdateStatus(
      currentVersion: velaVersion,
      latestVersion: tag,
      releaseUrl: releaseUrl,
      hasUpdate: compareReleaseVersions(tag, velaReleaseTag) > 0,
      checkedAt: DateTime.now(),
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

Future<void> openExternalUrl(String url) async {
  if (Platform.isMacOS) {
    await Process.run('open', [url]);
    return;
  }
  if (Platform.isWindows) {
    await Process.run('rundll32', ['url.dll,FileProtocolHandler', url]);
    return;
  }
  await Process.run('xdg-open', [url]);
}
