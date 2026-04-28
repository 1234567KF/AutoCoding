#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage:
  convert_markdown_to_docx.sh <source-path> <output-dir> [resource-root]

Arguments:
  source-path    A single .md file or a directory containing .md files
  output-dir     Destination directory for generated .docx files
  resource-root  Optional root directory for shared assets such as resources/
EOF
  exit 1
}

[[ $# -lt 2 || $# -gt 3 ]] && usage

if ! command -v pandoc >/dev/null 2>&1; then
  echo "Error: pandoc is not installed or not in PATH." >&2
  exit 1
fi

SOURCE_PATH="$1"
OUTPUT_DIR="$2"

if [[ -f "$SOURCE_PATH" ]]; then
  SOURCE_DIR="$(cd "$(dirname "$SOURCE_PATH")" && pwd -P)"
elif [[ -d "$SOURCE_PATH" ]]; then
  SOURCE_DIR="$(cd "$SOURCE_PATH" && pwd -P)"
else
  echo "Error: source path not found: $SOURCE_PATH" >&2
  exit 1
fi

SOURCE_PARENT="$(cd "$SOURCE_DIR/.." && pwd -P)"
RESOURCE_ROOT="${3:-$SOURCE_PARENT}"

mkdir -p "$OUTPUT_DIR"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

normalize_markdown() {
  local input_file="$1"
  local output_file="$2"

  perl -0pe '
    s{^图：([^\n!]+)!\[\[([^]|]+)\|[0-9]+\]\]}{![](<$2>)\n\n*图：$1*}mg;
    s{!\[\[([^]|]+)\|[0-9]+\]\]}{![](<$1>)}g;
    s{!\[\[([^]|]+)\]\]}{![](<$1>)}g;
  ' "$input_file" > "$output_file"
}

collect_sources() {
  if [[ -f "$SOURCE_PATH" ]]; then
    printf '%s\n' "$SOURCE_PATH"
    return
  fi

  find "$SOURCE_PATH" -maxdepth 1 -type f -name '*.md' | sort
}

convert_one() {
  local src_file="$1"
  local base_name normalized_file output_file src_dir resource_path

  base_name="$(basename "$src_file" .md)"
  normalized_file="$TMP_DIR/$base_name.md"
  output_file="$OUTPUT_DIR/$base_name.docx"
  src_dir="$(cd "$(dirname "$src_file")" && pwd -P)"
  resource_path="$src_dir:$SOURCE_DIR:$SOURCE_PARENT:$RESOURCE_ROOT:$RESOURCE_ROOT/resources"

  normalize_markdown "$src_file" "$normalized_file"

  pandoc "$normalized_file" \
    -f markdown \
    -t docx \
    --resource-path="$resource_path" \
    -o "$output_file"

  printf 'OK\t%s\n' "$output_file"
}

converted_count=0

while IFS= read -r src_file; do
  [[ -n "$src_file" ]] || continue
  convert_one "$src_file"
  converted_count=$((converted_count + 1))
done < <(collect_sources)

if [[ "$converted_count" -eq 0 ]]; then
  echo "Error: no Markdown files found to convert." >&2
  exit 1
fi

printf 'Converted %d file(s) into %s\n' "$converted_count" "$OUTPUT_DIR"
