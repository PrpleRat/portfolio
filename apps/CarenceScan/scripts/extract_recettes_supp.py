#!/usr/bin/env python3
"""Extract recettes_supplementaires.json from agent transcript."""
import json
import re
from pathlib import Path

TRANSCRIPT = Path(__file__).resolve().parents[2] / ".cursor" / "projects" / "d-CURSOR-BOS-main" / "agent-transcripts" / "2fd7b6ef-1ab5-4d5c-9d7c-747092192327" / "2fd7b6ef-1ab5-4d5c-9d7c-747092192327.jsonl"
OUT = Path(__file__).resolve().parent.parent / "CarenceScan" / "Resources" / "recettes_supplementaires.json"

# Fallback: transcript in cursor projects folder from user_info
ALT = Path(r"C:\Users\jouet\.cursor\projects\d-CURSOR-BOS-main\agent-transcripts\2fd7b6ef-1ab5-4d5c-9d7c-747092192327\2fd7b6ef-1ab5-4d5c-9d7c-747092192327.jsonl")


def main():
    path = ALT if ALT.exists() else TRANSCRIPT
    text = ""
    for line in path.read_text(encoding="utf-8").splitlines():
        if "recettes_supplementaires" in line and "boeuf_brocoli_gingembre" in line:
            obj = json.loads(line)
            text = obj["message"]["content"][0]["text"]
            break
    if not text:
        raise SystemExit("Could not find recettes in transcript")

    m = re.search(r'(\{\s*"recettes_supplementaires"\s*:\s*\[.*?\]\s*\})', text, re.DOTALL)
    if not m:
        raise SystemExit("Regex failed")
    data = json.loads(m.group(1))
    OUT.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Wrote {len(data['recettes_supplementaires'])} recipes to {OUT}")


if __name__ == "__main__":
    main()
