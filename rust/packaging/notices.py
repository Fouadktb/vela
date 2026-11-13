#!/usr/bin/env python3
"""Collect resolved Cargo package and embedded font notices without inferring licenses."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess

HERE = Path(__file__).resolve().parent
RUST_ROOT = HERE.parent
ROOT = RUST_ROOT.parent
PREFIXES = ('LICENSE', 'LICENCE', 'COPYING', 'NOTICE', 'UNLICENSE')


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def package_notices(package, destination):
    root = Path(package['manifest_path']).resolve().parent
    candidates = set()
    declared = package.get('license_file')
    if declared:
        path = Path(declared)
        if not path.is_absolute():
            path = root / path
        path = path.resolve()
        if path.is_file() and path.is_relative_to(root):
            candidates.add(path)
    for path in root.rglob('*'):
        if path.is_file() and path.name.upper().startswith(PREFIXES):
            resolved = path.resolve()
            if resolved.is_relative_to(root):
                candidates.add(resolved)
    files = []
    for path in sorted(candidates):
        relative = path.relative_to(root)
        target = destination / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(path, target)
        files.append({'path': relative.as_posix(), 'sha256': digest(path)})
    return files


def collect(destination, targets):
    destination.mkdir(parents=True, exist_ok=True)
    packages = {}
    workspace = set()
    for target in targets:
        command = ['cargo', 'metadata', '--manifest-path', str(RUST_ROOT / 'Cargo.toml'),
                   '--locked', '--format-version', '1', '--filter-platform', target]
        metadata = json.loads(subprocess.check_output(command, text=True))
        workspace.update(metadata['workspace_members'])
        resolved = {node['id'] for node in metadata['resolve']['nodes']}
        for package in metadata['packages']:
            if package['id'] in resolved:
                packages[package['id']] = package
    index = []
    combined = [
        'Vela Rust dependency notices\n',
        'This document records Cargo metadata and license/notice files present in\n'
        'the resolved crate sources. Declared expressions are reported verbatim;\n'
        'no license text or classification has been invented for missing files.\n'
        'Original copied notices and Cargo.lock accompany this document.\n',
    ]
    for package_id, package in sorted(packages.items(), key=lambda pair: (pair[1]['name'], pair[1]['version'], pair[0])):
        if package_id in workspace:
            continue
        name, version = package['name'], package['version']
        slug = f'{name}-{version}-{hashlib.sha256(package_id.encode()).hexdigest()[:8]}'
        notices = package_notices(package, destination / 'cargo' / slug)
        source = package.get('source')
        crate_url = f'https://crates.io/crates/{name}/{version}' if source and source.startswith('registry+') else source
        entry = {
            'name': name, 'version': version, 'source': source,
            'package_url': crate_url, 'repository': package.get('repository'),
            'declared_license': package.get('license'),
            'declared_license_file': Path(package['license_file']).name if package.get('license_file') else None,
            'notices_directory': f'cargo/{slug}', 'notice_files': notices,
        }
        index.append(entry)
        combined.append(f'\n{"=" * 72}\n{name} {version}\n')
        combined.append(f'Package source: {crate_url or "not declared"}\n')
        combined.append(f'Repository: {package.get("repository") or "not declared"}\n')
        combined.append(f'Declared license expression: {package.get("license") or "not declared"}\n')
        if not notices:
            combined.append('No LICENSE/COPYING/NOTICE text file was present in this cached crate.\n')
        for notice in notices:
            combined.append(f'\n--- Original notice: {notice["path"]} ---\n')
            copied = destination / 'cargo' / slug / notice['path']
            combined.append(copied.read_bytes().decode('utf-8', errors='replace').rstrip() + '\n')
    fonts = destination / 'fonts'
    fonts.mkdir(exist_ok=True)
    font_index = []
    for path in sorted((RUST_ROOT / 'assets/fonts').glob('*.txt')):
        # The fonts directory contains license/notice texts under both LICENSE
        # and OFL names. Preserve every .txt file rather than guessing its license.
        shutil.copyfile(path, fonts / path.name)
        font_index.append({'path': f'fonts/{path.name}', 'sha256': digest(path)})
    readme = RUST_ROOT / 'assets/fonts/README.md'
    if readme.exists():
        shutil.copyfile(readme, fonts / 'README.md')
    shutil.copyfile(RUST_ROOT / 'Cargo.lock', destination / 'Cargo.lock')
    (destination / 'CARGO_NOTICES.txt').write_text(''.join(combined), encoding='utf-8')
    (destination / 'cargo-notices.json').write_text(json.dumps({
        'targets': targets, 'cargo_lock_sha256': digest(RUST_ROOT / 'Cargo.lock'),
        'packages': index, 'fonts': font_index,
    }, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
    print(f'Collected {len(index)} resolved Cargo package records and {len(font_index)} font licenses to {destination}')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--destination', required=True, type=Path)
    parser.add_argument('--target', required=True, action='append', dest='targets')
    args = parser.parse_args()
    collect(args.destination, args.targets)


if __name__ == '__main__':
    main()
