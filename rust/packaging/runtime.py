#!/usr/bin/env python3
"""Download hash-pinned native runtime and stage only required runtime binaries."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tarfile
import tempfile
import urllib.request

HERE = Path(__file__).resolve().parent
LOCK = json.loads((HERE / 'runtime-lock.json').read_text())


def sha256(path):
    digest = hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(block)
    return digest.hexdigest()


def download(platform, cache):
    spec = LOCK[platform]
    cache.mkdir(parents=True, exist_ok=True)
    archive = cache / spec['url'].rsplit('/', 1)[1]
    if archive.exists() and sha256(archive) == spec['sha256']:
        return archive
    request = urllib.request.Request(spec['url'], headers={'User-Agent': 'Vela-runtime-packager'})
    temporary = archive.with_suffix(archive.suffix + '.partial')
    try:
        with urllib.request.urlopen(request, timeout=120) as source, temporary.open('wb') as dest:
            shutil.copyfileobj(source, dest)
        actual = sha256(temporary)
        if actual != spec['sha256']:
            raise RuntimeError(f'Runtime SHA256 mismatch: expected {spec["sha256"]}, got {actual}')
        temporary.replace(archive)
    finally:
        temporary.unlink(missing_ok=True)
    return archive


def dependencies(binary):
    output = subprocess.check_output(['otool', '-L', str(binary)], text=True)
    result = set()
    for line in output.splitlines():
        stripped = line.strip()
        if ' (compatibility version' not in stripped:
            continue
        dependency = stripped.split(' (compatibility version', 1)[0]
        match = re.match(r'@rpath/([^/]+)\.framework/', dependency)
        if match:
            result.add(match[1])
        elif not dependency.startswith(('/System/Library/', '/usr/lib/')):
            raise RuntimeError(f'Unpackaged dynamic dependency in {binary}: {dependency}')
    return result


def macos(archive, destination):
    with tempfile.TemporaryDirectory(prefix='vela-runtime-') as temp:
        with tarfile.open(archive) as tar:
            tar.extractall(temp, filter='data')
        frameworks = {p.stem: p for p in Path(temp).glob('*/*.xcframework/macos-arm64_x86_64/*.framework')}
        queue, required = ['Mpv'], set()
        while queue:
            name = queue.pop()
            if name in required:
                continue
            if name not in frameworks:
                raise RuntimeError(f'Missing transitive runtime framework: {name}')
            required.add(name)
            queue.extend(dependencies(frameworks[name] / name) - required)
        for name in sorted(required):
            target = destination / f'{name}.framework'
            if target.exists():
                shutil.rmtree(target)
            shutil.copytree(frameworks[name], target, symlinks=True)
        return sorted(f'{name}.framework' for name in required)


def windows(archive, destination):
    with tempfile.TemporaryDirectory(prefix='vela-runtime-') as temp:
        seven = shutil.which('7z') or shutil.which('7zz')
        if not seven:
            candidate = Path(os.environ.get('ProgramFiles', 'C:/Program Files')) / '7-Zip/7z.exe'
            if candidate.is_file():
                seven = str(candidate)
        if not seven:
            raise RuntimeError('Install 7-Zip (7z.exe) to unpack the pinned Windows runtime')
        subprocess.run([seven, 'x', '-y', f'-o{temp}', str(archive)], check=True, stdout=subprocess.DEVNULL)
        dlls = list(Path(temp).rglob('libmpv-2.dll'))
        if len(dlls) != 1:
            raise RuntimeError('Expected exactly one libmpv-2.dll in runtime archive')
        shutil.copy2(dlls[0], destination / 'libmpv-2.dll')
        # This distribution is one statically linked DLL; ANGLE/SwiftShader are
        # not needed by the native WGL renderer (hardware decode uses copy-back).
        return ['libmpv-2.dll']


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('platform', choices=LOCK)
    parser.add_argument('--destination', required=True, type=Path)
    parser.add_argument('--cache', type=Path, default=HERE.parent / 'target/runtime-cache')
    args = parser.parse_args()
    archive = download(args.platform, args.cache)
    args.destination.mkdir(parents=True, exist_ok=True)
    files = globals()[args.platform](archive, args.destination)
    manifest = dict(LOCK[args.platform], files=files)
    (args.destination / 'runtime-manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print(f'Staged {args.platform} runtime ({len(files)} binaries) to {args.destination}')


if __name__ == '__main__':
    main()
