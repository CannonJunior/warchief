#!/usr/bin/env python3
"""
Generate source tree JSON for Warchief project.

Scans project directory and generates a JSON file containing:
- Directory structure with files
- Line counts for source files
- File sizes
- Project statistics

Usage:
    python generate_source_tree.py [--root PATH] [--output PATH] [--project-name NAME]
"""

import argparse
import json
import os
from datetime import datetime
from pathlib import Path
from typing import Any

# Directories to exclude from scanning
EXCLUDE_DIRS = {
    '.git', '.dart_tool', '.idea', 'build', 'node_modules',
    '__pycache__', '.venv', 'venv', '.gradle', '.pub-cache',
    'coverage', '.flutter-plugins', 'android', 'ios', 'linux',
    'macos', 'windows', 'ephemeral'
}

# Files to exclude
EXCLUDE_FILES = {
    '.DS_Store', 'Thumbs.db', '.flutter-plugins',
    '.flutter-plugins-dependencies', 'pubspec.lock',
    '.packages', '.metadata'
}

# Extensions to count lines for
LINE_COUNT_EXTENSIONS = {
    '.dart', '.py', '.js', '.ts', '.html', '.css', '.scss',
    '.json', '.yaml', '.yml', '.md', '.txt', '.sh', '.xml',
    '.gradle', '.toml', '.mojo'
}

# Special files to count lines for (no extension)
LINE_COUNT_FILES = {
    'Makefile', 'Dockerfile', 'CLAUDE.md', 'README.md',
    'pubspec.yaml', 'analysis_options.yaml'
}

# File type icons (unicode)
FILE_ICONS = {
    '.dart': '\U0001F3AF',  # dart target
    '.py': '\U0001F40D',    # snake
    '.mojo': '\U0001F525',  # fire
    '.js': '\U0001F4C4',    # page
    '.ts': '\U0001F4C4',    # page
    '.html': '\U0001F310',  # globe
    '.css': '\U0001F3A8',   # palette
    '.scss': '\U0001F3A8',  # palette
    '.json': '\U0001F4CB',  # clipboard
    '.yaml': '\U0001F4CB',  # clipboard
    '.yml': '\U0001F4CB',   # clipboard
    '.md': '\U0001F4DD',    # memo
    '.sh': '\U00002328',    # keyboard
    '.xml': '\U0001F4C4',   # page
    '.svg': '\U0001F5BC',   # framed picture
    '.png': '\U0001F5BC',   # framed picture
    '.jpg': '\U0001F5BC',   # framed picture
    '.gif': '\U0001F5BC',   # framed picture
}


def should_exclude_dir(name: str) -> bool:
    """Check if directory should be excluded."""
    return name in EXCLUDE_DIRS or name.startswith('.')


def should_exclude_file(name: str) -> bool:
    """Check if file should be excluded."""
    if name in EXCLUDE_FILES:
        return True
    # Exclude binary and compiled files
    ext = Path(name).suffix.lower()
    if ext in {'.pyc', '.pyo', '.class', '.o', '.so', '.dylib', '.exe'}:
        return True
    return False


def count_lines(file_path: Path) -> int:
    """Count lines in a file."""
    try:
        with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
            return sum(1 for _ in f)
    except Exception:
        return 0


def should_count_lines(file_path: Path) -> bool:
    """Check if we should count lines for this file."""
    if file_path.name in LINE_COUNT_FILES:
        return True
    return file_path.suffix.lower() in LINE_COUNT_EXTENSIONS


def get_file_icon(file_path: Path) -> str:
    """Get icon for file type."""
    ext = file_path.suffix.lower()
    return FILE_ICONS.get(ext, '\U0001F4C4')  # default: page


def build_tree(path: Path, root_path: Path) -> dict[str, Any] | None:
    """Recursively build tree structure for a path."""
    name = path.name
    rel_path = str(path.relative_to(root_path.parent))

    if path.is_file():
        if should_exclude_file(name):
            return None

        try:
            size = path.stat().st_size
        except OSError:
            size = 0

        node = {
            'name': name,
            'type': 'file',
            'path': rel_path,
            'size': size,
            'extension': path.suffix.lower(),
            'icon': get_file_icon(path),
        }

        if should_count_lines(path):
            node['lines'] = count_lines(path)

        return node

    elif path.is_dir():
        if should_exclude_dir(name):
            return None

        children = []
        for child in sorted(path.iterdir(), key=lambda p: (p.is_file(), p.name.lower())):
            child_node = build_tree(child, root_path)
            if child_node:
                children.append(child_node)

        # Only include non-empty directories
        if not children:
            return None

        return {
            'name': name,
            'type': 'directory',
            'path': rel_path,
            'children': children,
        }

    return None


def calculate_totals(tree: dict[str, Any]) -> dict[str, int]:
    """Calculate totals from tree structure."""
    totals = {
        'files': 0,
        'directories': 0,
        'lines': 0,
        'size': 0,
    }

    def traverse(node: dict[str, Any]):
        if node['type'] == 'file':
            totals['files'] += 1
            totals['size'] += node.get('size', 0)
            totals['lines'] += node.get('lines', 0)
        elif node['type'] == 'directory':
            totals['directories'] += 1
            for child in node.get('children', []):
                traverse(child)

    traverse(tree)
    return totals


def find_project_root(start_path: Path) -> Path:
    """Find project root by looking for marker files."""
    markers = ['pubspec.yaml', 'package.json', 'pyproject.toml', '.git']
    current = start_path.resolve()

    while current != current.parent:
        for marker in markers:
            if (current / marker).exists():
                return current
        current = current.parent

    return start_path.resolve()


def main():
    parser = argparse.ArgumentParser(description='Generate source tree JSON')
    parser.add_argument('--root', type=str, help='Project root directory')
    parser.add_argument('--output', type=str, help='Output JSON file path')
    parser.add_argument('--project-name', type=str, help='Project name')
    args = parser.parse_args()

    # Determine root path
    if args.root:
        root_path = Path(args.root).resolve()
    else:
        root_path = find_project_root(Path.cwd())

    # Determine project name
    project_name = args.project_name or root_path.name

    # Determine output path
    if args.output:
        output_path = Path(args.output)
    else:
        output_path = root_path / 'assets' / 'data' / 'source-tree.json'

    # Ensure output directory exists
    output_path.parent.mkdir(parents=True, exist_ok=True)

    print(f"Scanning: {root_path}")
    print(f"Project: {project_name}")

    # Build tree
    tree = build_tree(root_path, root_path)
    if not tree:
        print("Error: Could not build tree")
        return 1

    # Calculate totals
    totals = calculate_totals(tree)

    # Build output structure
    output = {
        'generated_at': datetime.now().isoformat(),
        'project_name': project_name,
        'root': str(root_path),
        'totals': totals,
        'tree': tree,
    }

    # Write JSON
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(output, f, indent=2, ensure_ascii=False)

    print(f"Output: {output_path}")
    print(f"Files: {totals['files']}, Directories: {totals['directories']}")
    print(f"Lines: {totals['lines']:,}, Size: {totals['size'] / 1024:.1f} KB")

    return 0


if __name__ == '__main__':
    exit(main())
