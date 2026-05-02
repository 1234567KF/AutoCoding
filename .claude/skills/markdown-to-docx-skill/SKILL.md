---
name: markdown-to-docx
description: Convert one Markdown file or a top-level folder of Markdown articles into DOCX with pandoc, preserving Obsidian image embeds, shared resources folders, captions, Mermaid diagrams, and optional Word reference templates. Use when exporting Markdown to Word documents.
recommended_model: flash
---

# Skill: Markdown to DOCX

Use this skill when the user wants `.md` files exported to `.docx` with `pandoc`.

## What this skill does

- Converts one Markdown file or all top-level Markdown files in a directory.
- Creates one `.docx` per source `.md`.
- Preserves images by setting a broad `--resource-path`.
- Normalizes Obsidian image embeds like `![[image.png]]` and `![[image.png|697]]` before conversion.
- Repairs the common case where a figure caption and an Obsidian image were accidentally merged onto one line.
- Can render Markdown against a Word `.dotx`/`.docx` reference template and apply post-processing for polished Word output.
- Renders Mermaid code blocks to PNG images when Node.js and `npx` are available.

## Workflow

1. Confirm `pandoc` is installed with `pandoc --version`.
2. Inspect the source folder for Markdown files and image syntax if needed.
3. Run the bundled script from this skill folder:

```bash
SKILL_DIR="/path/to/markdown-to-docx"
"$SKILL_DIR/scripts/convert_markdown_to_docx.sh" \
  "<source-path>" \
  "<output-dir>" \
  "[resource-root]"
```

## Parameters

- `source-path`: a single `.md` file or a directory that contains `.md` files.
- `output-dir`: destination directory for generated `.docx` files.
- `resource-root` (optional): root directory that contains shared assets such as `resources/`. If omitted, the script infers likely roots from the source location.

## Template Workflow

When the user provides a Word template:

### Step 1: Convert (auto-fixes captions)

The conversion script **automatically inserts missing table/figure captions** into the normalized markdown before calling pandoc. No manual pre-check is needed — the pipeline:

1. Normalizes Obsidian embeds and markdown syntax
2. Runs `validate_captions.py fix` to auto-insert any missing `表N-M` / `图N-M` captions (derived from table headers or surrounding context)
3. Converts with pandoc + Lua style filter
4. Post-processes the docx (fonts, styles, tables, borders, headers)

You can still run a manual pre-check to preview what will be fixed:

```bash
SKILL_DIR="/path/to/markdown-to-docx"
python3 "$SKILL_DIR/scripts/validate_captions.py" \
  pre "<source-md>"
```

```bash
SKILL_DIR="/path/to/markdown-to-docx"
"$SKILL_DIR/scripts/render_markdown_with_dotx.sh" \
  "<source-md>" \
  "<output-docx>" \
  "<template-dotx-or-docx>" \
  "[book-title]" \
  "[resource-root]" \
  "[shortcut-template]"
```

This script automatically:

- Auto-inserts missing `表N-M` / `图N-M` captions (derived from table headers or surrounding context)
- Maps image blocks, figure/table captions to publisher paragraph styles via Lua filter
- Post-processes for code style, fonts (Times New Roman + 宋体), table borders, layout
- Rewrites unordered-list indentation so bullet text aligns with Chinese paragraph first-line indent instead of Word's default deep indent
- Rewrites ordered and unordered lists so the marker column aligns with the Chinese body paragraph's two-character first-line indent instead of drifting too far left
- Applies Word `keep with next` to image paragraphs and table captions so images stay with figure captions and captions stay with tables
- Removes the code-block first-line indent from the exported `Source Code` paragraph style
- Clears first-line indent inside every table cell paragraph so table content does not inherit body-text indentation
- Replaces header text with chapter title
- Suppresses template auto-numbering when headings already contain explicit chapter numbers
- Extracts figure explanations and shortens captions for editor style
- Optionally injects Word shortcut bindings from the original `.dotx` template
- Automatically preserves Word shortcut bindings when the provided template already contains `word/customizations.xml`

### Step 2: Post-check — validate generated docx

```bash
SKILL_DIR="/path/to/markdown-to-docx"
python3 "$SKILL_DIR/scripts/validate_captions.py" \
  post "<output-docx>"
```

This checks:
1. No `Compact` style paragraphs (undefined style)
2. No VML horizontal rules (`o:hr="t"`)
3. Font defaults = Times New Roman + 宋体 (not Calibri)
4. First-line indent present in Normal style
5. All tables have borders (tblBorders or tcBorders)
6. Image paragraphs (`图`) and table captions (`表题1-1`) have `keep with next`
7. Code block style has no first-line indent
8. Ordered and unordered list geometry keeps the marker column aligned with Chinese paragraph first-line indent
9. Table cell paragraphs explicitly clear first-line indent
10. Table captions (表X-Y) present and sequentially numbered
11. Figure captions (图X-Y) present and sequentially numbered

**If post-check reports ERRORs, investigate and fix.** The most common post-check error is missing captions — which means the markdown source was missing them (go back to Step 1).

Current editorial rules are tracked in:

- `references/editorial-template-rules.md`

## Notes

- The script only converts top-level `.md` files when a directory is passed.
- Source Markdown files are not modified. Normalization happens in a temporary directory.
- If the user wants recursive conversion, patch the script first instead of reimplementing the workflow ad hoc.
- If the publisher template contains `word/customizations.xml`, the render script now auto-injects those keymap customizations into the generated `.docx`. You can still pass an explicit `shortcut-template` when the shortcut source differs from the reference template.
- **MANDATORY**: Always run post-check after conversion. Never skip validation. Caption auto-fix runs automatically during conversion.
