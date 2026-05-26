#!/usr/bin/env node

import { spawnSync } from 'node:child_process';

const result = spawnSync('mpv', ['--version'], {
  encoding: 'utf8',
});

if (result.error) {
  if (result.error.code === 'ENOENT') {
    console.error(
      'mpv is not installed or is not available on PATH. Install mpv before testing local playback.',
    );
    process.exit(1);
  }

  console.error(`Failed to run mpv --version: ${result.error.message}`);
  process.exit(1);
}

if (result.status !== 0) {
  console.error(`mpv --version failed with exit code ${result.status ?? 'unknown'}.`);

  if (result.stdout) {
    console.error('\nstdout:');
    console.error(result.stdout.trimEnd());
  }

  if (result.stderr) {
    console.error('\nstderr:');
    console.error(result.stderr.trimEnd());
  }

  process.exit(result.status ?? 1);
}

const versionLine = result.stdout.split(/\r?\n/).find((line) => line.trim().length > 0);

if (!versionLine) {
  console.error('mpv --version succeeded but did not print a version line.');
  process.exit(1);
}

console.log(versionLine);
