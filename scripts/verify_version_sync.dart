import 'dart:io';

void main() {
  final root = _repoRoot();
  final pubspec = File('${root.path}/pubspec.yaml').readAsStringSync();
  final appVersion = File(
    '${root.path}/lib/src/app/app_version.dart',
  ).readAsStringSync();

  final pubspecVersion = _firstMatch(
    pubspec,
    RegExp(
      r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+)(?:\+([0-9]+))?\s*$',
      multiLine: true,
    ),
    'pubspec.yaml version',
  );
  final dartVersion = _firstMatch(
    appVersion,
    RegExp(r"const\s+velaVersion\s*=\s*'([^']+)';"),
    'velaVersion',
  );
  final dartBuildNumber = _firstMatch(
    appVersion,
    RegExp(r"const\s+velaBuildNumber\s*=\s*'([^']+)';"),
    'velaBuildNumber',
  );

  final pubspecBuildNumber = pubspecVersion.group(2) ?? '';
  final errors = <String>[];
  if (pubspecVersion.group(1) != dartVersion.group(1)) {
    errors.add(
      'pubspec version ${pubspecVersion.group(1)} does not match '
      'velaVersion ${dartVersion.group(1)}',
    );
  }
  if (pubspecBuildNumber != dartBuildNumber.group(1)) {
    errors.add(
      'pubspec build number $pubspecBuildNumber does not match '
      'velaBuildNumber ${dartBuildNumber.group(1)}',
    );
  }

  if (errors.isNotEmpty) {
    stderr.writeln('Version metadata is out of sync:');
    for (final error in errors) {
      stderr.writeln('- $error');
    }
    exitCode = 1;
    return;
  }

  stdout.writeln(
    'Version metadata is synced: '
    '${dartVersion.group(1)}+${dartBuildNumber.group(1)}',
  );
}

Directory _repoRoot() {
  final script = Platform.script.toFilePath();
  return File(script).parent.parent;
}

RegExpMatch _firstMatch(String value, RegExp pattern, String label) {
  final match = pattern.firstMatch(value);
  if (match == null) {
    stderr.writeln('Could not read $label');
    exit(1);
  }
  return match;
}
