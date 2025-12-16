from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from analysis import analyze_pdf


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Fixed-rule PDF recommendation analyzer")
    parser.add_argument("input", type=str, help="Input JSON file with parsed PDF fields")
    parser.add_argument("--pretty", action="store_true", help="Pretty-print JSON output")
    args = parser.parse_args(argv)

    input_path = Path(args.input)
    if not input_path.exists():
        print(f"Input not found: {input_path}", file=sys.stderr)
        return 2

    with input_path.open("r", encoding="utf-8") as f:
        data = json.load(f)

    result = analyze_pdf(data)

    def _write_json(obj: dict) -> None:
        text = json.dumps(obj, ensure_ascii=False, indent=2 if args.pretty else None)
        try:
            if hasattr(sys.stdout, "reconfigure"):
                sys.stdout.reconfigure(encoding="utf-8")
            print(text)
        except Exception:
            # Fallback for consoles that can't encode Unicode in the current codepage
            sys.stdout.buffer.write(text.encode("utf-8"))
            sys.stdout.buffer.write(b"\n")

    _write_json(result)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())


