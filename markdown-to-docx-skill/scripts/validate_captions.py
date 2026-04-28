#!/usr/bin/env python3
"""Validate and auto-fix table/figure captions in markdown or docx.

Modes:
  validate_captions.py pre  <source.md>          — check only
  validate_captions.py fix  <source.md>          — auto-insert missing captions, write in-place
  validate_captions.py post <output.docx>        — check generated docx
"""
from __future__ import annotations

import re
import sys
import zipfile
import xml.etree.ElementTree as ET

W = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
EXPECTED_ORDERED_LEFT = "800"
EXPECTED_BULLET_LEFT = "840"
EXPECTED_BULLET_HANGING = "420"
EXPECTED_LIST_STEP = "420"


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _extract_chapter(lines: list[str]) -> str | None:
    for line in lines:
        m = re.match(r"^#\s+第(\d+)章", line)
        if m:
            return m.group(1)
    return None


def _qn(tag: str) -> str:
    return f"{{{W}}}{tag}"


TABLE_CAPTION_RE = re.compile(r"^\*?表[：:]?\s*(\d+)[-.]\s*(\d+)\s+\S.*\*?$")
FIGURE_CAPTION_RE = re.compile(r"^\*?图\s*(\d+)[-.]\s*(\d+)\s+\S.*\*?$")
FIGURE_CAPTION_ALT_RE = re.compile(r"^\*?图[：:]?\s*(\d+)[-.]\s*(\d+)\s+\S.*\*?$")
GENERIC_ORDERED_NUMFMTS = {"decimal", "lowerLetter", "upperLetter", "lowerRoman", "upperRoman"}
SPECIAL_NUMBERING_PREFIXES = ("表", "图", "代码清单")


def _is_generic_ordered_level(lvl: ET.Element) -> bool:
    num_fmt = lvl.find(f"{{{W}}}numFmt")
    if num_fmt is None or num_fmt.get(f"{{{W}}}val") not in GENERIC_ORDERED_NUMFMTS:
        return False
    lvl_text = lvl.find(f"{{{W}}}lvlText")
    if lvl_text is None:
        return False
    value = lvl_text.get(f"{{{W}}}val") or ""
    if "%" not in value:
        return False
    if any(prefix in value for prefix in SPECIAL_NUMBERING_PREFIXES):
        return False
    return True


def _find_table_blocks(lines: list[str]) -> list[tuple[int, int, str]]:
    """Return (start, end, header_line) for each contiguous table block."""
    blocks: list[tuple[int, int, str]] = []
    in_table = False
    table_start = 0
    header = ""
    for i, line in enumerate(lines):
        stripped = line.strip()
        if stripped.startswith("|") and "|" in stripped[1:]:
            if not in_table:
                in_table = True
                table_start = i
                header = stripped
        else:
            if in_table:
                blocks.append((table_start, i - 1, header))
                in_table = False
    if in_table:
        blocks.append((table_start, len(lines) - 1, header))
    return blocks


def _find_figure_items(lines: list[str]) -> list[tuple[int, int, str]]:
    """Return (start_line, end_line, type) for images and mermaid blocks."""
    items: list[tuple[int, int, str]] = []
    for i, line in enumerate(lines):
        if re.match(r"^!\[", line.strip()):
            items.append((i, i, "image"))
    in_code = False
    code_lang = ""
    code_start = 0
    for i, line in enumerate(lines):
        stripped = line.strip()
        if stripped.startswith("```"):
            if not in_code:
                in_code = True
                code_lang = stripped[3:].strip().lower()
                code_start = i
            else:
                if code_lang == "mermaid":
                    items.append((code_start, i, "mermaid"))
                in_code = False
                code_lang = ""
    items.sort(key=lambda x: x[0])
    return items


def _has_caption_before(lines: list[str], start: int, pattern: re.Pattern) -> tuple[bool, tuple[str, str] | None]:
    for look_back in range(1, 4):
        idx = start - look_back
        if idx < 0:
            break
        prev = lines[idx].strip()
        if prev == "":
            continue
        m = pattern.match(prev)
        if m:
            return True, (m.group(1), m.group(2))
        return False, None
    return False, None


def _has_caption_after(lines: list[str], search_start: int, pattern: re.Pattern, alt_pattern: re.Pattern | None = None) -> tuple[bool, tuple[str, str] | None]:
    for idx in range(search_start, min(search_start + 4, len(lines))):
        nxt = lines[idx].strip()
        if nxt == "":
            continue
        m = pattern.match(nxt)
        if m:
            return True, (m.group(1), m.group(2))
        if alt_pattern:
            m2 = alt_pattern.match(nxt)
            if m2:
                return True, (m2.group(1), m2.group(2))
        return False, None
    return False, None


def _derive_table_title(lines: list[str], start: int, header: str) -> str:
    """Derive a short table title from the header row columns."""
    # Extract column names from header row: | Col1 | Col2 | ...
    cols = [c.strip() for c in header.split("|") if c.strip()]
    if len(cols) >= 2:
        return "、".join(cols[:3]) + ("等" if len(cols) > 3 else "")
    # Fallback: use preceding paragraph
    for look_back in range(1, 5):
        idx = start - look_back
        if idx < 0:
            break
        prev = lines[idx].strip()
        if prev and not prev.startswith("|") and not prev.startswith("#"):
            # Truncate to first clause
            for sep in ("：", "。", "，", "："):
                if sep in prev:
                    prev = prev[: prev.index(sep)]
                    break
            if len(prev) > 30:
                prev = prev[:30]
            return prev
    return "数据总览"


def _derive_figure_title(lines: list[str], start: int, end: int, fig_type: str) -> str:
    """Derive a short figure title from surrounding context."""
    # Look at line before
    for look_back in range(1, 5):
        idx = start - look_back
        if idx < 0:
            break
        prev = lines[idx].strip()
        if prev and not prev.startswith("```") and not prev.startswith("#"):
            # Truncate
            for sep in ("：", "。", "，"):
                if sep in prev:
                    prev = prev[: prev.index(sep)]
                    break
            if len(prev) > 30:
                prev = prev[:30]
            return prev
    return "系统架构图"


# ---------------------------------------------------------------------------
# Pre-check
# ---------------------------------------------------------------------------

def pre_check(md_path: str) -> list[str]:
    with open(md_path, encoding="utf-8") as f:
        lines = f.readlines()

    issues: list[str] = []
    chapter_num = _extract_chapter(lines) or "?"
    if chapter_num == "?":
        issues.append("WARN: Cannot extract chapter number from H1 heading")

    table_blocks = _find_table_blocks(lines)
    for idx, (start, end, header) in enumerate(table_blocks, 1):
        found, nums = _has_caption_before(lines, start, TABLE_CAPTION_RE)
        if not found:
            issues.append(
                f"ERROR: Table at line {start + 1} missing caption. "
                f"Expected: 表{chapter_num}-{idx} <title>"
            )
        else:
            if nums[0] != chapter_num:
                issues.append(f"WARN: Table at line {start + 1}: chapter {nums[0]}, expected {chapter_num}")
            if nums[1] != str(idx):
                issues.append(f"WARN: Table at line {start + 1}: 表{nums[0]}-{nums[1]}, expected seq {idx}")

    figure_items = _find_figure_items(lines)
    for idx, (start, end, fig_type) in enumerate(figure_items, 1):
        search_start = end + 1
        found, nums = _has_caption_after(lines, search_start, FIGURE_CAPTION_RE, FIGURE_CAPTION_ALT_RE)
        if not found:
            found, nums = _has_caption_before(lines, start, FIGURE_CAPTION_RE)
        if not found:
            issues.append(
                f"ERROR: {fig_type.capitalize()} at line {start + 1} missing caption. "
                f"Expected: 图{chapter_num}-{idx} <title>"
            )
        else:
            if nums[0] != chapter_num:
                issues.append(f"WARN: Figure near line {start + 1}: chapter {nums[0]}, expected {chapter_num}")
            if nums[1] != str(idx):
                issues.append(f"WARN: Figure near line {start + 1}: 图{nums[0]}-{nums[1]}, expected seq {idx}")

    if not issues:
        issues.append(
            f"OK: {len(table_blocks)} tables, {len(figure_items)} figures — "
            f"all captions present and correctly numbered"
        )
    return issues


# ---------------------------------------------------------------------------
# Auto-fix
# ---------------------------------------------------------------------------

def auto_fix(md_path: str) -> list[str]:
    """Insert missing captions into markdown. Returns log of changes."""
    with open(md_path, encoding="utf-8") as f:
        lines = f.readlines()

    chapter_num = _extract_chapter(lines) or "0"
    log: list[str] = []

    # We need to process from bottom to top so that line insertions
    # don't shift indices of items not yet processed.

    # Collect all items that need fixing
    insertions: list[tuple[int, str]] = []  # (line_index, caption_text)

    # --- Tables: caption goes BEFORE the table ---
    table_blocks = _find_table_blocks(lines)
    for idx, (start, end, header) in enumerate(table_blocks, 1):
        found, _ = _has_caption_before(lines, start, TABLE_CAPTION_RE)
        if not found:
            title = _derive_table_title(lines, start, header)
            caption = f"表{chapter_num}-{idx} {title}"
            insertions.append((start, caption))
            log.append(f"FIXED: Inserted '{caption}' before line {start + 1}")

    # --- Figures: caption goes AFTER the figure ---
    figure_items = _find_figure_items(lines)
    for idx, (start, end, fig_type) in enumerate(figure_items, 1):
        search_start = end + 1
        found, _ = _has_caption_after(lines, search_start, FIGURE_CAPTION_RE, FIGURE_CAPTION_ALT_RE)
        if not found:
            found, _ = _has_caption_before(lines, start, FIGURE_CAPTION_RE)
        if not found:
            title = _derive_figure_title(lines, start, end, fig_type)
            caption = f"图{chapter_num}-{idx} {title}"
            insert_at = end + 1
            insertions.append((insert_at, caption))
            log.append(f"FIXED: Inserted '{caption}' after line {end + 1}")

    if not insertions:
        log.append("OK: No missing captions to fix")
        return log

    # Sort by line index descending so insertions don't shift each other
    insertions.sort(key=lambda x: x[0], reverse=True)

    for insert_at, caption in insertions:
        # Insert: blank line + caption + blank line
        new_lines = ["\n", caption + "\n", "\n"]
        lines[insert_at:insert_at] = new_lines

    with open(md_path, "w", encoding="utf-8") as f:
        f.writelines(lines)

    log.append(f"DONE: {len(insertions)} captions inserted into {md_path}")
    return log


# ---------------------------------------------------------------------------
# Post-check
# ---------------------------------------------------------------------------

def post_check(docx_path: str) -> list[str]:
    VML = "urn:schemas-microsoft-com:vml"
    O = "urn:schemas-microsoft-com:office:office"

    issues: list[str] = []

    with zipfile.ZipFile(docx_path) as z:
        doc = ET.fromstring(z.read("word/document.xml"))
        styles = ET.fromstring(z.read("word/styles.xml"))
        numbering = ET.fromstring(z.read("word/numbering.xml"))

    style_name_by_id: dict[str, str] = {}
    style_by_name: dict[str, ET.Element] = {}
    for style in styles.findall(f"{{{W}}}style"):
        sid = style.get(f"{{{W}}}styleId")
        name_el = style.find(f"{{{W}}}name")
        name = name_el.get(f"{{{W}}}val") if name_el is not None else sid
        if sid:
            style_name_by_id[sid] = name
        if name:
            style_by_name[name] = style

    # 1. Compact style
    compact = sum(
        1
        for p in doc.findall(f".//{{{W}}}p")
        if (ppr := p.find(f"{{{W}}}pPr")) is not None
        and (ps := ppr.find(f"{{{W}}}pStyle")) is not None
        and ps.get(f"{{{W}}}val") == "Compact"
    )
    if compact > 0:
        issues.append(f"ERROR: {compact} paragraphs with undefined 'Compact' style")

    # 2. VML horizontal rules
    hr = sum(
        1
        for r in doc.findall(f".//{{{VML}}}rect")
        if r.get(f"{{{O}}}hr") == "t"
    )
    if hr > 0:
        issues.append(f"ERROR: {hr} VML horizontal rules (ugly dividers)")

    # 3. Fonts
    defaults = styles.find(f"{{{W}}}docDefaults")
    if defaults is not None:
        rf = defaults.find(f".//{{{W}}}rFonts")
        if rf is not None:
            ascii_f = rf.get(f"{{{W}}}ascii", "?")
            ea_f = rf.get(f"{{{W}}}eastAsia", "?")
            if ascii_f == "Calibri":
                issues.append("WARN: docDefaults ascii font is Calibri, expected Times New Roman")
            if ea_f != "宋体":
                issues.append(f"WARN: docDefaults eastAsia font is {ea_f}, expected 宋体")

    # 4. First-line indent (Normal style or docDefaults)
    has_indent = False
    for style in styles.findall(f"{{{W}}}style"):
        name_el = style.find(f"{{{W}}}name")
        if name_el is not None and name_el.get(f"{{{W}}}val") == "Normal":
            ppr = style.find(f"{{{W}}}pPr")
            if ppr is not None:
                ind = ppr.find(f"{{{W}}}ind")
                if ind is not None and ind.get(f"{{{W}}}firstLine"):
                    has_indent = True
            break
    if not has_indent and defaults is not None:
        ppr_d = defaults.find(f".//{{{W}}}pPrDefault")
        if ppr_d is not None:
            ppr = ppr_d.find(f"{{{W}}}pPr")
            if ppr is not None:
                ind = ppr.find(f"{{{W}}}ind")
                if ind is not None and ind.get(f"{{{W}}}firstLine"):
                    has_indent = True
    if not has_indent:
        issues.append("WARN: No first-line indent in Normal style or docDefaults")

    # 5. Table borders
    tables = doc.findall(f".//{{{W}}}tbl")
    tables_no_borders = 0
    for tbl in tables:
        tpr = tbl.find(f"{{{W}}}tblPr")
        has_tbl_borders = tpr is not None and tpr.find(f"{{{W}}}tblBorders") is not None
        has_cell_borders = any(
            tc.find(f"{{{W}}}tcPr") is not None
            and tc.find(f"{{{W}}}tcPr").find(f"{{{W}}}tcBorders") is not None
            for tc in tbl.findall(f".//{{{W}}}tc")
        )
        if not has_tbl_borders and not has_cell_borders:
            tables_no_borders += 1
    if tables_no_borders > 0:
        issues.append(f"ERROR: {tables_no_borders}/{len(tables)} tables missing borders")

    # 6. Keep-with-next for figure images and table captions
    image_keep_next_missing = 0
    table_caption_keep_next_missing = 0
    for p in doc.findall(f".//{{{W}}}p"):
        ppr = p.find(f"{{{W}}}pPr")
        if ppr is None:
            continue
        ps = ppr.find(f"{{{W}}}pStyle")
        sid = ps.get(f"{{{W}}}val") if ps is not None else None
        style_name = style_name_by_id.get(sid, sid or "")
        has_keep_next = ppr.find(f"{{{W}}}keepNext") is not None
        if style_name == "图" and not has_keep_next:
            image_keep_next_missing += 1
        if style_name == "表题1-1" and not has_keep_next:
            table_caption_keep_next_missing += 1
    if image_keep_next_missing > 0:
        issues.append(f"ERROR: {image_keep_next_missing} image paragraphs missing keep-with-next")
    if table_caption_keep_next_missing > 0:
        issues.append(f"ERROR: {table_caption_keep_next_missing} table captions missing keep-with-next")

    # 7. Code block first-line indent
    code_style = None
    for style_name in ("Source Code", "SourceCode", "代码清单"):
        candidate = style_by_name.get(style_name)
        if candidate is not None:
            code_style = candidate
            break
    if code_style is not None:
        ppr = code_style.find(f"{{{W}}}pPr")
        if ppr is not None:
            ind = ppr.find(f"{{{W}}}ind")
            if ind is None:
                issues.append("ERROR: Code block style is missing explicit zero first-line indent override")
            else:
                if ind.get(f"{{{W}}}firstLine") != "0" or ind.get(f"{{{W}}}firstLineChars") != "0":
                    issues.append("ERROR: Code block style still has first-line indentation")
                if ind.get(f"{{{W}}}hanging") or ind.get(f"{{{W}}}hangingChars"):
                    issues.append("ERROR: Code block style still has hanging indentation")

    # 8. List indentation should align with Chinese body-text first-line indent
    bullet_indent_issues = 0
    ordered_indent_issues = 0
    num_to_abs: dict[str, str] = {}
    abstract_lookup: dict[str, ET.Element] = {}
    for num in numbering.findall(f"{{{W}}}num"):
        num_id = num.get(f"{{{W}}}numId")
        abs_el = num.find(f"{{{W}}}abstractNumId")
        abs_id = abs_el.get(f"{{{W}}}val") if abs_el is not None else None
        if num_id and abs_id:
            num_to_abs[num_id] = abs_id
    for absnum in numbering.findall(f"{{{W}}}abstractNum"):
        abs_id = absnum.get(f"{{{W}}}abstractNumId")
        if abs_id:
            abstract_lookup[abs_id] = absnum

    for p in doc.findall(f".//{{{W}}}p"):
        ppr = p.find(f"{{{W}}}pPr")
        if ppr is None:
            continue
        numpr = ppr.find(f"{{{W}}}numPr")
        if numpr is None:
            continue
        num_id_el = numpr.find(f"{{{W}}}numId")
        ilvl_el = numpr.find(f"{{{W}}}ilvl")
        if num_id_el is None:
            continue
        abs_id = num_to_abs.get(num_id_el.get(f"{{{W}}}val", ""))
        if not abs_id:
            continue
        absnum = abstract_lookup.get(abs_id)
        if absnum is None:
            continue
        ilvl = ilvl_el.get(f"{{{W}}}val", "0") if ilvl_el is not None else "0"
        try:
            ilvl_num = int(ilvl)
        except ValueError:
            ilvl_num = 0
        lvl = absnum.find(f"{{{W}}}lvl[@{{{W}}}ilvl='{ilvl}']")
        if lvl is None:
            continue
        ind = lvl.find(f"{{{W}}}pPr/{{{W}}}ind")
        num_fmt = lvl.find(f"{{{W}}}numFmt")
        is_bullet = num_fmt is not None and num_fmt.get(f"{{{W}}}val") == "bullet"
        is_ordered = _is_generic_ordered_level(lvl)
        if not is_bullet and not is_ordered:
            continue
        if ind is None:
            if is_bullet:
                bullet_indent_issues += 1
            else:
                ordered_indent_issues += 1
            continue
        if is_bullet:
            expected_left = str(int(EXPECTED_BULLET_LEFT) + ilvl_num * int(EXPECTED_LIST_STEP))
            if (
                ind.get(f"{{{W}}}left") != expected_left
                or ind.get(f"{{{W}}}hanging") != EXPECTED_BULLET_HANGING
            ):
                bullet_indent_issues += 1
        else:
            expected_left = str(int(EXPECTED_ORDERED_LEFT) + ilvl_num * int(EXPECTED_LIST_STEP))
            if (
                ind.get(f"{{{W}}}left") != expected_left
                or ind.get(f"{{{W}}}hanging") != EXPECTED_BULLET_HANGING
            ):
                ordered_indent_issues += 1
    if bullet_indent_issues > 0:
        issues.append(
            "ERROR: "
            f"{bullet_indent_issues} bullet list paragraphs still use over-indented list geometry "
            f"(expected left={EXPECTED_BULLET_LEFT}, hanging={EXPECTED_BULLET_HANGING})"
        )
    if ordered_indent_issues > 0:
        issues.append(
            "ERROR: "
            f"{ordered_indent_issues} ordered list paragraphs still use over-indented list geometry "
            f"(expected left={EXPECTED_ORDERED_LEFT}, hanging={EXPECTED_BULLET_HANGING})"
        )

    # 9. Table cell paragraphs should not inherit body first-line indent
    table_cell_indent_issues = 0
    for tc in doc.findall(f".//{{{W}}}tc"):
        for p in tc.findall(f"{{{W}}}p"):
            ppr = p.find(f"{{{W}}}pPr")
            ind = ppr.find(f"{{{W}}}ind") if ppr is not None else None
            if ind is None:
                table_cell_indent_issues += 1
                continue
            if ind.get(f"{{{W}}}firstLine") not in ("0", None) or ind.get(f"{{{W}}}firstLineChars") not in ("0", None):
                table_cell_indent_issues += 1
    if table_cell_indent_issues > 0:
        issues.append(f"ERROR: {table_cell_indent_issues} table cell paragraphs still inherit first-line indentation")

    # 10. Table and figure captions
    all_texts = []
    for p in doc.findall(f".//{{{W}}}p"):
        text = "".join(t.text or "" for t in p.findall(f".//{{{W}}}t"))
        if text.strip():
            all_texts.append(text.strip())

    table_captions = [t for t in all_texts if re.match(r"^表\s*\d+[-.]\d+\s+\S", t)]
    figure_captions = [t for t in all_texts if re.match(r"^图\s*\d+[-.]\d+\s+\S", t)]

    if len(tables) > 0 and len(table_captions) == 0:
        issues.append(f"ERROR: {len(tables)} tables found but 0 table captions (表X-Y)")
    elif len(tables) > len(table_captions):
        issues.append(f"WARN: {len(tables)} tables but only {len(table_captions)} table captions")

    for kind, captions in [("表", table_captions), ("图", figure_captions)]:
        nums = []
        for cap in captions:
            m = re.match(rf"^{kind}\s*(\d+)[-.]\s*(\d+)", cap)
            if m:
                nums.append((int(m.group(1)), int(m.group(2))))
        if nums:
            chapter = nums[0][0]
            for i, (ch, seq) in enumerate(nums, 1):
                if ch != chapter:
                    issues.append(f"WARN: {kind} caption #{i} has chapter {ch}, expected {chapter}")
                if seq != i:
                    issues.append(f"WARN: {kind} caption #{i} is {kind}{ch}-{seq}, expected {kind}{chapter}-{i}")

    if not issues:
        issues.append(
            f"OK: {len(tables)} tables, {len(table_captions)} table captions, "
            f"{len(figure_captions)} figure captions — all checks passed"
        )
    return issues


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> int:
    if len(sys.argv) != 3 or sys.argv[1] not in ("pre", "post", "fix"):
        print(
            "Usage:\n"
            "  validate_captions.py pre  <source.md>   — check only\n"
            "  validate_captions.py fix  <source.md>   — auto-insert missing captions\n"
            "  validate_captions.py post <output.docx>  — check generated docx",
            file=sys.stderr,
        )
        return 1

    mode = sys.argv[1]
    path = sys.argv[2]

    if mode == "pre":
        results = pre_check(path)
    elif mode == "fix":
        results = auto_fix(path)
    else:
        results = post_check(path)

    has_error = False
    for line in results:
        if line.startswith("ERROR"):
            has_error = True
        print(line)

    return 1 if has_error else 0


if __name__ == "__main__":
    raise SystemExit(main())
