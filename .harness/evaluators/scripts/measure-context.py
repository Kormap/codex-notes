#!/usr/bin/env python3
"""Measure this repository's documented discovery model, not a live Codex prompt."""

import argparse
import hashlib
import json
from pathlib import Path


def measure(root, mode):
    source_path = root / "AGENTS.md"
    source = source_path.read_text(encoding="utf-8")
    override_path = root / "AGENTS.override.md"
    entry_path = override_path if override_path.is_file() else source_path
    initial = []
    if mode in ("global-only", "global-repo"):
        initial.append(source_path)
    if mode in ("global-repo", "repo-only"):
        initial.append(entry_path)
    additional = []
    if source_path not in initial:
        # The repository override explicitly instructs reading its linked source.
        if "[AGENTS.md](AGENTS.md)" not in entry_path.read_text(encoding="utf-8"):
            raise ValueError("repository override has no explicit source link")
        additional.append(source_path)
    metadata = []
    skill_paths = sorted(root.glob("skills/*/SKILL.md"))
    for path in skill_paths:
        lines = path.read_text(encoding="utf-8").splitlines()
        if not lines or lines[0] != "---":
            raise ValueError("skill frontmatter is missing")
        for line in lines[1:]:
            if line == "---":
                break
            if line.startswith(("name:", "description:")):
                metadata.append(line)
    startup_chars = sum(len(p.read_text(encoding="utf-8")) for p in initial)
    additional_chars = sum(len(p.read_text(encoding="utf-8")) for p in additional)
    return {
        "mode": mode,
        "measurement": "documented discovery model; Unicode characters; not tokenizer or agent execution",
        "initial_documents": [p.name for p in initial],
        "additional_source_reads": [p.name for p in additional],
        "source_occurrences": initial.count(source_path) + len(additional),
        "startup_chars": startup_chars,
        "additional_source_chars": additional_chars,
        "source_ready_chars": startup_chars + additional_chars,
        "source_sha256": hashlib.sha256(source_path.read_bytes()).hexdigest(),
        "skill_count": len(skill_paths),
        "skill_name_description_chars": len("\n".join(metadata)),
        "excluded": "skill paths, selected skill bodies, README, tools and external skills",
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("root", type=Path)
    parser.add_argument("mode", choices=("global-only", "global-repo", "repo-only"))
    args = parser.parse_args()
    try:
        result = measure(args.root.resolve(), args.mode)
    except (OSError, ValueError) as error:
        parser.exit(1, f"context measurement failed: {error}\n")
    print(json.dumps(result, ensure_ascii=False, sort_keys=True))


if __name__ == "__main__":
    main()
