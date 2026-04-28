#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage:
  render_markdown_with_dotx.sh <source-md> <output-docx> <template-dotx-or-docx> [book-title] [resource-root] [shortcut-template]
EOF
  exit 1
}

[[ $# -lt 3 || $# -gt 6 ]] && usage

SOURCE_MD="$1"
OUTPUT_DOCX="$2"
TEMPLATE_DOC="$3"
BOOK_TITLE="${4:-}"
SHORTCUT_TEMPLATE="${6:-}"
SOURCE_NAME="$(basename "$SOURCE_MD")"

if [[ ! -f "$SOURCE_MD" ]]; then
  echo "Error: source markdown not found: $SOURCE_MD" >&2
  exit 1
fi

if [[ ! -f "$TEMPLATE_DOC" ]]; then
  echo "Error: template file not found: $TEMPLATE_DOC" >&2
  exit 1
fi

if ! command -v pandoc >/dev/null 2>&1; then
  echo "Error: pandoc is not installed or not in PATH." >&2
  exit 1
fi

template_has_keymap_customizations() {
  python3 - "$1" <<'PY'
import sys
import zipfile

try:
    with zipfile.ZipFile(sys.argv[1]) as zf:
        raise SystemExit(0 if "word/customizations.xml" in zf.namelist() else 1)
except Exception:
    raise SystemExit(1)
PY
}

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
SOURCE_DIR="$(cd "$(dirname "$SOURCE_MD")" && pwd -P)"
SOURCE_PARENT="$(cd "$SOURCE_DIR/.." && pwd -P)"
RESOURCE_ROOT="${5:-$SOURCE_PARENT}"

if [[ -z "$SHORTCUT_TEMPLATE" ]] && template_has_keymap_customizations "$TEMPLATE_DOC"; then
  SHORTCUT_TEMPLATE="$TEMPLATE_DOC"
fi

mkdir -p "$(dirname "$OUTPUT_DOCX")"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

NORMALIZED_MD="$TMP_DIR/normalized.md"
TMP_RESOURCES_DIR="$TMP_DIR/resources"

perl -0pe '
  s{^图：([^\n!]+)!\[\[([^]|]+)\|[0-9]+\]\]}{![](<$2>)\n\n图：$1}mg;
  s{!\[\[([^]|]+)\|[0-9]+\]\]}{![](<$1>)}g;
  s{!\[\[([^]|]+)\]\]}{![](<$1>)}g;
  s{^\*([图表]：[^\n*]+)\*$}{$1}mg;
  s{(?m)^(!\[[^\n]*\]\([^\n]+\))$}{\n$1\n}g;
  s{(?m)^([图表]：[^\n]+)$}{\n$1\n}g;
  s{(?m)^(\*\*[^\n*]+\*\*)$}{\n$1\n}g;
  s{^---$}{}mg;
  s{^(#{3,})\s+\d+\.\d+(?:\.\d+)?\s+(小结|可执行清单)}{$1 $2}mg;
  s{\n{3,}}{\n\n}g;
' "$SOURCE_MD" > "$NORMALIZED_MD"

python3 "$SCRIPT_DIR/render_mermaid_blocks_for_docx.py" \
  "$NORMALIZED_MD" \
  "$SOURCE_NAME" \
  "$RESOURCE_ROOT" \
  "$TMP_RESOURCES_DIR"

# Auto-fix missing table/figure captions before conversion
python3 "$SCRIPT_DIR/validate_captions.py" fix "$NORMALIZED_MD"

CHAPTER_TITLE="$(sed -n 's/^# //p' "$NORMALIZED_MD" | head -n 1)"
CHAPTER_PREFIX="$(printf '%s\n' "$CHAPTER_TITLE" | perl -ne 'print "$1\n" if /(第[0-9]+章)/')"

HEADER_TEXT="${CHAPTER_TITLE:-Markdown Export}"
if [[ -n "$BOOK_TITLE" ]]; then
  HEADER_TEXT="《${BOOK_TITLE}》"
fi
if [[ -n "$BOOK_TITLE" && -n "$CHAPTER_PREFIX" ]]; then
  HEADER_TEXT="${HEADER_TEXT}${CHAPTER_PREFIX}"
fi

RESOURCE_PATH="$TMP_DIR:$TMP_RESOURCES_DIR:$SOURCE_DIR:$SOURCE_PARENT:$RESOURCE_ROOT:$RESOURCE_ROOT/resources"

pandoc "$NORMALIZED_MD" \
  -f markdown \
  -t docx \
  --reference-doc="$TEMPLATE_DOC" \
  --lua-filter="$SCRIPT_DIR/template_style_filter.lua" \
  --resource-path="$RESOURCE_PATH" \
  -o "$OUTPUT_DOCX"

"$SCRIPT_DIR/postprocess_template_docx.py" "$OUTPUT_DOCX" "$TEMPLATE_DOC" "$HEADER_TEXT" "$SHORTCUT_TEMPLATE"

printf 'OK\t%s\n' "$OUTPUT_DOCX"
