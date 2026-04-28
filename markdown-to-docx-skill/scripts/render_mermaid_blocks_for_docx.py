#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
import subprocess
import tempfile
from pathlib import Path


MERMAID_FENCE_RE = re.compile(r"^```\s*mermaid\b", re.IGNORECASE)


def slugify(text: str) -> str:
    slug = re.sub(r"[^0-9A-Za-z\u4e00-\u9fff._-]+", "-", text)
    slug = slug.strip("-._")
    return slug or "diagram"


def render_mermaid(
    *,
    code: str,
    out_path: Path,
    theme: str = "neutral",
    width: int = 1200,
    height: int = 900,
    scale: float = 2.0,
) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="docx-mermaid-") as tmpdir:
        tmp_mmd = Path(tmpdir) / "diagram.mmd"
        tmp_mmd.write_text(code, encoding="utf-8")
        cmd = [
            "npx",
            "-y",
            "@mermaid-js/mermaid-cli",
            "-i",
            str(tmp_mmd),
            "-o",
            str(out_path),
            "--outputFormat",
            "png",
            "--theme",
            theme,
            "--backgroundColor",
            "white",
            "--width",
            str(width),
            "--height",
            str(height),
            "--scale",
            str(scale),
            "-q",
        ]
        proc = subprocess.run(cmd, capture_output=True, text=True)
        if proc.returncode != 0:
            stderr = (proc.stderr or "").strip()
            stdout = (proc.stdout or "").strip()
            detail = stderr or stdout or str(proc.returncode)
            raise RuntimeError(f"Mermaid render failed for {out_path.name}: {detail}")


def process_markdown(md_path: Path, source_name: str, temp_resources_dir: Path) -> int:
    lines = md_path.read_text(encoding="utf-8").splitlines()
    out_lines: list[str] = []
    mermaid_count = 0
    rendered = 0
    temp_resources_dir.mkdir(parents=True, exist_ok=True)

    i = 0
    while i < len(lines):
        line = lines[i]
        if MERMAID_FENCE_RE.match(line.strip()):
            j = i + 1
            code_lines: list[str] = []
            while j < len(lines) and not lines[j].strip().startswith("```"):
                code_lines.append(lines[j])
                j += 1
            if j >= len(lines):
                raise RuntimeError(f"Unclosed mermaid block in {md_path}")

            mermaid_count += 1
            out_name = f"{slugify(Path(source_name).stem)}-mermaid-{mermaid_count:02d}.png"
            out_path = temp_resources_dir / out_name
            render_mermaid(code="\n".join(code_lines).strip() + "\n", out_path=out_path)

            out_lines.append(f"![](resources/{out_name})")
            rendered += 1
            i = j + 1
            continue

        out_lines.append(line)
        i += 1

    md_path.write_text("\n".join(out_lines) + "\n", encoding="utf-8")
    return rendered


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Render Mermaid code blocks in Markdown to PNG images for DOCX export."
    )
    parser.add_argument("markdown_path", help="Normalized Markdown file to rewrite in place.")
    parser.add_argument("source_name", help="Original Markdown basename, used for output names.")
    parser.add_argument(
        "resource_root",
        help="Compatibility argument; existing image lookup is handled by the calling script.",
    )
    parser.add_argument("temp_resources_dir", help="Temporary resources directory for generated diagrams.")
    args = parser.parse_args()

    rendered = process_markdown(
        md_path=Path(args.markdown_path),
        source_name=args.source_name,
        temp_resources_dir=Path(args.temp_resources_dir),
    )
    print(f"MERMAID_OK {Path(args.markdown_path)} rendered={rendered}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
