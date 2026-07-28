#!/usr/bin/env python3
"""
Generate MANIFEST.txt for the DMS-SI-Mix reproducibility package.

Walks the repository, records a SHA-256 hash and byte size for every file,
and writes a deterministic, sorted inventory to MANIFEST.txt at the root.

Usage, from the repository root:

    python make_manifest.py

Edit the two provenance fields below before the release.
"""

import hashlib
import os
import sys

# ----------------------------------------------------------------------
# Provenance of the reported runs. Fill these in before publishing.
# ----------------------------------------------------------------------
MATLAB_VERSION = "TODO e.g. R2024b"
CODE_REVISION = "TODO commit hash or internal revision of dms_si_mix.m used for the reported runs"
RELEASE_VERSION = "1.0.0"

SKIP_DIRS = {".git", ".github", "__pycache__", ".ipynb_checkpoints"}
SKIP_FILES = {"MANIFEST.txt"}


def sha256(path, chunk=1 << 20):
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        while True:
            block = fh.read(chunk)
            if not block:
                break
            h.update(block)
    return h.hexdigest()


def collect(root):
    entries = []
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = sorted(d for d in dirnames if d not in SKIP_DIRS)
        for name in sorted(filenames):
            if name in SKIP_FILES:
                continue
            full = os.path.join(dirpath, name)
            rel = os.path.relpath(full, root).replace(os.sep, "/")
            entries.append((rel, os.path.getsize(full), sha256(full)))
    return sorted(entries, key=lambda e: e[0])


def main():
    root = os.path.abspath(os.path.dirname(__file__) or ".")
    entries = collect(root)
    if not entries:
        sys.exit("No files found. Run this from the repository root.")

    total = sum(size for _, size, _ in entries)
    width = max(len(rel) for rel, _, _ in entries)

    lines = [
        "DMS-SI-Mix - Reproducibility Package",
        f"Release version : {RELEASE_VERSION}",
        f"MATLAB version  : {MATLAB_VERSION}",
        f"Code revision   : {CODE_REVISION}",
        "",
        "Integrity inventory. One line per file:",
        "    SHA-256   size(bytes)   path",
        "",
        "Verify a single file, e.g. on Linux/macOS:",
        "    sha256sum data/MORAP_NM/<file>",
        "or on Windows PowerShell:",
        "    Get-FileHash -Algorithm SHA256 data\\MORAP_NM\\<file>",
        "",
        f"Files: {len(entries)}   Total size: {total} bytes",
        "=" * 100,
        "",
    ]
    for rel, size, digest in entries:
        lines.append(f"{digest}  {size:>12}  {rel:<{width}}")

    out = os.path.join(root, "MANIFEST.txt")
    with open(out, "w", encoding="utf-8", newline="\n") as fh:
        fh.write("\n".join(lines) + "\n")

    print(f"Wrote {out}")
    print(f"{len(entries)} files, {total} bytes")
    if "TODO" in MATLAB_VERSION or "TODO" in CODE_REVISION:
        print("WARNING: provenance fields still contain TODO placeholders.")


if __name__ == "__main__":
    main()
