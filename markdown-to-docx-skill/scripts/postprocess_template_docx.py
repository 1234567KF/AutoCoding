#!/usr/bin/env python3
from __future__ import annotations

import copy
import os
import re
import shutil
import sys
import tempfile
import zipfile
import xml.etree.ElementTree as ET

W_NS = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
R_NS = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
PKG_REL_NS = "http://schemas.openxmlformats.org/package/2006/relationships"
VML_NS = "urn:schemas-microsoft-com:vml"
OFFICE_NS = "urn:schemas-microsoft-com:office:office"
NS = {"w": W_NS, "v": VML_NS, "o": OFFICE_NS}
ET.register_namespace("w", W_NS)
ET.register_namespace("r", R_NS)
ET.register_namespace("v", VML_NS)
ET.register_namespace("o", OFFICE_NS)

CONTENT_TYPES_NS = "http://schemas.openxmlformats.org/package/2006/content-types"
KEYMAP_REL_TYPE = "http://schemas.microsoft.com/office/2006/relationships/keyMapCustomizations"
KEYMAP_CONTENT_TYPE = "application/vnd.ms-word.keyMapCustomizations+xml"
ORDERED_LIST_BASE_LEFT = 800
BULLET_LIST_BASE_LEFT = 840
LIST_LEVEL_STEP = 420
LIST_HANGING = 420
BULLET_ABSTRACT_IDS = {"990", "991", "992"}
ORDERED_NUMFMTS = {"decimal", "lowerLetter", "upperLetter", "lowerRoman", "upperRoman"}
SPECIAL_NUMBERING_PREFIXES = ("表", "图", "代码清单")
BULLET_GLYPHS = {
    "\u2022",
    "\u25cf",
    "\u25cb",
    "\u25aa",
    "\u25a0",
    "\uF06C",
    "\uf0b7",
    "",
    "",
    "o",
    "☐",
}
BROKEN_REL_PREFIX_RE = re.compile(r"\bns\d+:id=")


def qn(tag: str) -> str:
    return f"{{{W_NS}}}{tag}"


def first(root, xpath: str):
    return root.find(xpath, NS)


def sanitize_relationship_prefixes(xml_path: str) -> None:
    if not os.path.exists(xml_path):
        return
    text = open(xml_path, "r", encoding="utf-8").read()
    if not BROKEN_REL_PREFIX_RE.search(text):
        return
    text = BROKEN_REL_PREFIX_RE.sub("r:id=", text)
    if 'xmlns:r="' not in text:
        text = text.replace("<w:document ", f'<w:document xmlns:r="{R_NS}" ', 1)
    with open(xml_path, "w", encoding="utf-8") as handle:
        handle.write(text)


def is_bullet_level(absid: str, lvl: ET.Element) -> bool:
    if absid in BULLET_ABSTRACT_IDS:
        return True
    num_fmt = lvl.find(qn("numFmt"))
    if num_fmt is not None and num_fmt.get(qn("val")) == "bullet":
        return True
    lvl_text = lvl.find(qn("lvlText"))
    if lvl_text is not None and (lvl_text.get(qn("val")) or "") in BULLET_GLYPHS:
        return True
    return False


def is_generic_ordered_level(lvl: ET.Element) -> bool:
    num_fmt = lvl.find(qn("numFmt"))
    if num_fmt is None or num_fmt.get(qn("val")) not in ORDERED_NUMFMTS:
        return False
    lvl_text = lvl.find(qn("lvlText"))
    if lvl_text is None:
        return False
    value = lvl_text.get(qn("val")) or ""
    if "%" not in value:
        return False
    if any(prefix in value for prefix in SPECIAL_NUMBERING_PREFIXES):
        return False
    return True


def style_display_name(style) -> str:
    name = first(style, "w:name")
    if name is not None and name.get(qn("val")):
        return name.get(qn("val"))
    return style.get(qn("styleId"), "")


def find_style(styles: dict[str, ET.Element], style_ids=(), style_names=()):
    for style_id in style_ids:
        style = styles.get(style_id)
        if style is not None:
            return style
    wanted_names = set(style_names)
    if wanted_names:
        for style in styles.values():
            if style_display_name(style) in wanted_names:
                return style
    return None


def matching_styles(root, style_ids=(), style_names=()):
    wanted_ids = set(style_ids)
    wanted_names = set(style_names)
    out = []
    for style in root.findall("w:style", NS):
        sid = style.get(qn("styleId"), "")
        name = style_display_name(style)
        if sid in wanted_ids or name in wanted_names:
            out.append(style)
    return out


def normalize_code_style(style) -> None:
    if style is None:
        return
    ppr = first(style, "w:pPr")
    if ppr is None:
        ppr = ET.SubElement(style, qn("pPr"))
    ind = first(ppr, "w:ind")
    if ind is None:
        ind = ET.SubElement(ppr, qn("ind"))
    ind.set(qn("firstLine"), "0")
    ind.set(qn("firstLineChars"), "0")
    for attr in ("hanging", "hangingChars", "left", "leftChars"):
        ind.attrib.pop(qn(attr), None)


def patch_styles(styles_path: str):
    tree = ET.parse(styles_path)
    root = tree.getroot()
    styles = {
        style.get(qn("styleId")): style for style in root.findall("w:style", NS)
    }
    style_name_by_id = {
        style_id: (
            name.get(qn("val")) if (name := first(style, "w:name")) is not None else style_id
        )
        for style_id, style in styles.items()
    }

    for style_id in ["2", "3", "4", "5", "6", "78", "91"]:
        style = styles.get(style_id)
        if style is None:
            continue
        ppr = first(style, "w:pPr")
        if ppr is None:
            continue
        numpr = first(ppr, "w:numPr")
        if numpr is not None:
            ppr.remove(numpr)

    source_code = find_style(
        styles,
        style_ids=("SourceCode", "93"),
        style_names=("Source Code", "SourceCode"),
    )
    template_code = find_style(
        styles,
        style_ids=("af9",),
        style_names=("代码清单",),
    )
    if source_code is not None and template_code is not None:
        existing_ppr = first(source_code, "w:pPr")
        existing_rpr = first(source_code, "w:rPr")
        if existing_ppr is not None:
            source_code.remove(existing_ppr)
        if existing_rpr is not None:
            source_code.remove(existing_rpr)

        template_ppr = first(template_code, "w:pPr")
        template_rpr = first(template_code, "w:rPr")
        if template_ppr is not None:
            source_code.append(copy.deepcopy(template_ppr))
        if template_rpr is not None:
            source_code.append(copy.deepcopy(template_rpr))

    normalize_code_style(source_code)
    normalize_code_style(template_code)

    for style in matching_styles(
        root,
        style_ids=("SourceCode", "93", "af9"),
        style_names=("Source Code", "SourceCode", "代码清单"),
    ):
        normalize_code_style(style)

    tree.write(styles_path, encoding="UTF-8", xml_declaration=True)
    return style_name_by_id


def strip_explicit_body_styles(document_path: str, style_name_by_id) -> None:
    tree = ET.parse(document_path)
    root = tree.getroot()
    removable = {"FirstParagraph", "BodyText", "Compact"}
    removable_ids = {"FirstParagraph", "BodyText", "Compact"}

    for paragraph in root.findall(".//w:p", NS):
        ppr = first(paragraph, "w:pPr")
        if ppr is None:
            continue
        pstyle = first(ppr, "w:pStyle")
        if pstyle is None:
            continue
        style_id = pstyle.get(qn("val"))
        if style_id in removable_ids or style_name_by_id.get(style_id) in removable:
            ppr.remove(pstyle)

    tree.write(document_path, encoding="UTF-8", xml_declaration=True)


def patch_header(header_path: str, header_text: str) -> None:
    tree = ET.parse(header_path)
    root = tree.getroot()
    paragraphs = root.findall("w:p", NS)
    if not paragraphs:
        return

    target = None
    for paragraph in paragraphs:
        texts = "".join(node.text or "" for node in paragraph.findall(".//w:t", NS)).strip()
        if texts:
            target = paragraph
            break

    if target is None:
        return

    for child in list(target):
        if child.tag != qn("pPr"):
            target.remove(child)

    run = ET.SubElement(target, qn("r"))
    rpr = ET.SubElement(run, qn("rPr"))
    rfonts = ET.SubElement(rpr, qn("rFonts"))
    rfonts.set(qn("hint"), "eastAsia")
    text = ET.SubElement(run, qn("t"))
    text.text = header_text

    tree.write(header_path, encoding="UTF-8", xml_declaration=True)


def resolve_default_header(extracted_dir: str):
    doc_path = os.path.join(extracted_dir, "word", "document.xml")
    rels_path = os.path.join(extracted_dir, "word", "_rels", "document.xml.rels")
    doc_tree = ET.parse(doc_path)
    doc_root = doc_tree.getroot()
    sect = first(doc_root, ".//w:body/w:sectPr")
    if sect is None:
        return None

    default_rid = None
    for header_ref in sect.findall("w:headerReference", NS):
        if header_ref.get(qn("type")) == "default":
            default_rid = header_ref.get(f"{{{R_NS}}}id")
            break

    if not default_rid:
        return None

    rel_tree = ET.parse(rels_path)
    rel_root = rel_tree.getroot()
    for rel in rel_root.findall(f"{{{PKG_REL_NS}}}Relationship"):
        if rel.get("Id") == default_rid:
            target = rel.get("Target")
            if target:
                return os.path.join(extracted_dir, "word", target)
    return None


def next_rid(rel_root) -> str:
    max_id = 0
    for rel in rel_root.findall(f"{{{PKG_REL_NS}}}Relationship"):
        rel_id = rel.get("Id", "")
        if rel_id.startswith("rId"):
            try:
                max_id = max(max_id, int(rel_id[3:]))
            except ValueError:
                continue
    return f"rId{max_id + 1}"


def inject_keymap_customizations(extracted_dir: str, shortcut_template_path: str | None) -> None:
    if not shortcut_template_path or not os.path.exists(shortcut_template_path):
        return

    with zipfile.ZipFile(shortcut_template_path) as template_archive:
        if "word/customizations.xml" not in template_archive.namelist():
            return
        customizations_bytes = template_archive.read("word/customizations.xml")

    word_dir = os.path.join(extracted_dir, "word")
    os.makedirs(word_dir, exist_ok=True)
    with open(os.path.join(word_dir, "customizations.xml"), "wb") as handle:
        handle.write(customizations_bytes)

    rels_path = os.path.join(word_dir, "_rels", "document.xml.rels")
    rel_tree = ET.parse(rels_path)
    rel_root = rel_tree.getroot()

    keymap_rel = None
    for rel in rel_root.findall(f"{{{PKG_REL_NS}}}Relationship"):
        if rel.get("Type") == KEYMAP_REL_TYPE:
            keymap_rel = rel
            break

    if keymap_rel is None:
        keymap_rel = ET.SubElement(rel_root, f"{{{PKG_REL_NS}}}Relationship")
        keymap_rel.set("Id", next_rid(rel_root))
    keymap_rel.set("Type", KEYMAP_REL_TYPE)
    keymap_rel.set("Target", "customizations.xml")
    rel_tree.write(rels_path, encoding="UTF-8", xml_declaration=True)

    content_types_path = os.path.join(extracted_dir, "[Content_Types].xml")
    ct_tree = ET.parse(content_types_path)
    ct_root = ct_tree.getroot()
    override_tag = f"{{{CONTENT_TYPES_NS}}}Override"
    override = None
    for node in ct_root.findall(override_tag):
        if node.get("PartName") == "/word/customizations.xml":
            override = node
            break
    if override is None:
        override = ET.SubElement(ct_root, override_tag)
        override.set("PartName", "/word/customizations.xml")
    override.set("ContentType", KEYMAP_CONTENT_TYPE)
    ct_tree.write(content_types_path, encoding="UTF-8", xml_declaration=True)


def remove_horizontal_rules(document_path: str) -> None:
    tree = ET.parse(document_path)
    root = tree.getroot()
    hr_tag = f"{{{OFFICE_NS}}}hr"
    parent_map = {child: parent for parent in root.iter() for child in parent}
    for paragraph in root.findall(".//" + qn("p")):
        for pict in paragraph.findall(".//" + qn("pict")):
            for rect in pict.findall(f".//{{{VML_NS}}}rect"):
                if rect.get(hr_tag) == "t":
                    parent = parent_map.get(paragraph)
                    if parent is not None:
                        parent.remove(paragraph)
                    break
    tree.write(document_path, encoding="UTF-8", xml_declaration=True)


def patch_doc_defaults(extracted_dir: str, template_path: str) -> None:
    styles_path = os.path.join(extracted_dir, "word", "styles.xml")
    if not os.path.exists(styles_path) or not os.path.exists(template_path):
        return
    tmpl_tmp = tempfile.mkdtemp(prefix="tmpl-defaults-")
    try:
        with zipfile.ZipFile(template_path) as archive:
            archive.extractall(tmpl_tmp)
        tmpl_styles_path = os.path.join(tmpl_tmp, "word", "styles.xml")
        if not os.path.exists(tmpl_styles_path):
            return
        tmpl_tree = ET.parse(tmpl_styles_path)
        tmpl_root = tmpl_tree.getroot()
        tmpl_defaults = tmpl_root.find(qn("docDefaults"))
        if tmpl_defaults is None:
            return
        gen_tree = ET.parse(styles_path)
        gen_root = gen_tree.getroot()
        gen_defaults = gen_root.find(qn("docDefaults"))
        if gen_defaults is not None:
            gen_root.remove(gen_defaults)
        new_defaults = copy.deepcopy(tmpl_defaults)
        rfonts = new_defaults.find(f".//{qn('rFonts')}")
        if rfonts is not None:
            for attr in ("ascii", "hAnsi"):
                if rfonts.get(qn(attr)) == "Calibri":
                    rfonts.set(qn(attr), "Times New Roman")
        gen_root.insert(0, new_defaults)
        gen_tree.write(styles_path, encoding="UTF-8", xml_declaration=True)
    finally:
        shutil.rmtree(tmpl_tmp, ignore_errors=True)


def patch_tables(document_path: str) -> None:
    tree = ET.parse(document_path)
    root = tree.getroot()
    for tbl in root.findall(".//" + qn("tbl")):
        tbl_pr = tbl.find(qn("tblPr"))
        if tbl_pr is None:
            continue
        tbl_style = tbl_pr.find(qn("tblStyle"))
        if tbl_style is not None:
            tbl_style.set(qn("val"), "24")
        tbl_layout = tbl_pr.find(qn("tblLayout"))
        if tbl_layout is not None:
            tbl_layout.set(qn("type"), "autofit")
        tbl_w = tbl_pr.find(qn("tblW"))
        if tbl_w is not None:
            tbl_pr.remove(tbl_w)
        existing_borders = tbl_pr.find(qn("tblBorders"))
        if existing_borders is not None:
            tbl_pr.remove(existing_borders)
        borders = ET.SubElement(tbl_pr, qn("tblBorders"))
        for side in ("top", "left", "bottom", "right", "insideH", "insideV"):
            border = ET.SubElement(borders, qn(side))
            border.set(qn("val"), "single")
            border.set(qn("color"), "000000")
            border.set(qn("sz"), "4")
            border.set(qn("space"), "0")
    tree.write(document_path, encoding="UTF-8", xml_declaration=True)


def patch_numbering(extracted_dir: str) -> None:
    numbering_path = os.path.join(extracted_dir, "word", "numbering.xml")
    if not os.path.exists(numbering_path):
        return
    tree = ET.parse(numbering_path)
    root = tree.getroot()
    for absnum in root.findall(qn("abstractNum")):
        absid = absnum.get(qn("abstractNumId"), "")
        for lvl in absnum.findall(qn("lvl")):
            bullet_level = is_bullet_level(absid, lvl)
            ordered_level = is_generic_ordered_level(lvl)
            if not bullet_level and not ordered_level:
                continue
            if bullet_level:
                # Unify bullet glyphs and font so list symbols render consistently in Word.
                num_fmt = lvl.find(qn("numFmt"))
                if num_fmt is None:
                    num_fmt = ET.SubElement(lvl, qn("numFmt"))
                if num_fmt.get(qn("val")) != "bullet":
                    num_fmt.set(qn("val"), "bullet")
                lvl_text = lvl.find(qn("lvlText"))
                if lvl_text is None:
                    lvl_text = ET.SubElement(lvl, qn("lvlText"))
                lvl_text.set(qn("val"), "\uF06C")
                rpr = lvl.find(qn("rPr"))
                if rpr is None:
                    rpr = ET.SubElement(lvl, qn("rPr"))
                rfonts = rpr.find(qn("rFonts"))
                if rfonts is None:
                    rfonts = ET.SubElement(rpr, qn("rFonts"))
                rfonts.set(qn("ascii"), "Wingdings")
                rfonts.set(qn("hAnsi"), "Wingdings")
                rfonts.set(qn("hint"), "default")
            ppr = lvl.find(qn("pPr"))
            if ppr is None:
                ppr = ET.SubElement(lvl, qn("pPr"))
            ind = ppr.find(qn("ind"))
            if ind is None:
                ind = ET.SubElement(ppr, qn("ind"))
            try:
                level = int(lvl.get(qn("ilvl"), "0"))
            except ValueError:
                level = 0
            if bullet_level:
                left = BULLET_LIST_BASE_LEFT + (level * LIST_LEVEL_STEP)
            else:
                left = ORDERED_LIST_BASE_LEFT + (level * LIST_LEVEL_STEP)
            ind.set(qn("left"), str(left))
            ind.set(qn("hanging"), str(LIST_HANGING))
            for attr in ("leftChars", "hangingChars", "firstLine", "firstLineChars"):
                ind.attrib.pop(qn(attr), None)
    tree.write(numbering_path, encoding="UTF-8", xml_declaration=True)


def ensure_keep_next(ppr) -> None:
    keep_next = first(ppr, "w:keepNext")
    if keep_next is None:
        keep_next = ET.SubElement(ppr, qn("keepNext"))
    keep_next.set(qn("val"), "1")


def set_zero_first_line_indent(ppr) -> None:
    ind = first(ppr, "w:ind")
    if ind is None:
        ind = ET.SubElement(ppr, qn("ind"))
    ind.set(qn("firstLine"), "0")
    ind.set(qn("firstLineChars"), "0")
    for attr in ("hanging", "hangingChars"):
        ind.attrib.pop(qn(attr), None)


def patch_layout_constraints(document_path: str, style_name_by_id) -> None:
    tree = ET.parse(document_path)
    root = tree.getroot()
    code_style_names = {"Source Code", "SourceCode", "代码清单"}
    keep_next_style_names = {"图", "表题1-1"}

    for paragraph in root.findall(".//" + qn("p")):
        ppr = first(paragraph, "w:pPr")
        if ppr is None:
            ppr = ET.Element(qn("pPr"))
            paragraph.insert(0, ppr)

        pstyle = first(ppr, "w:pStyle")
        style_name = ""
        if pstyle is not None:
            style_name = style_name_by_id.get(pstyle.get(qn("val")), "")

        if style_name in keep_next_style_names:
            ensure_keep_next(ppr)

        if style_name in code_style_names:
            ind = first(ppr, "w:ind")
            if ind is not None:
                for attr in ("firstLine", "firstLineChars", "hanging", "hangingChars"):
                    ind.attrib.pop(qn(attr), None)
                if not ind.attrib:
                    ppr.remove(ind)

    for cell in root.findall(".//" + qn("tc")):
        for paragraph in cell.findall(qn("p")):
            ppr = first(paragraph, "w:pPr")
            if ppr is None:
                ppr = ET.Element(qn("pPr"))
                paragraph.insert(0, ppr)
            set_zero_first_line_indent(ppr)

    tree.write(document_path, encoding="UTF-8", xml_declaration=True)


def main() -> int:
    if len(sys.argv) not in {4, 5}:
        print(
            "Usage: postprocess_template_docx.py <docx-path> <template-path> <header-text> [shortcut-template]",
            file=sys.stderr,
        )
        return 1

    docx_path = sys.argv[1]
    template_path = sys.argv[2]
    header_text = sys.argv[3]
    shortcut_template = sys.argv[4] if len(sys.argv) == 5 else None

    if not os.path.exists(docx_path):
        print(f"Error: file not found: {docx_path}", file=sys.stderr)
        return 1

    temp_dir = tempfile.mkdtemp(prefix="template-docx-")
    try:
        with zipfile.ZipFile(docx_path) as archive:
            archive.extractall(temp_dir)

        styles_path = os.path.join(temp_dir, "word", "styles.xml")
        document_path = os.path.join(temp_dir, "word", "document.xml")
        sanitize_relationship_prefixes(document_path)
        style_name_by_id = {}
        if os.path.exists(styles_path):
            style_name_by_id = patch_styles(styles_path)
            if os.path.exists(document_path):
                strip_explicit_body_styles(document_path, style_name_by_id)

        if os.path.exists(document_path):
            remove_horizontal_rules(document_path)
            patch_tables(document_path)
            patch_layout_constraints(document_path, style_name_by_id)

        patch_doc_defaults(temp_dir, template_path)
        patch_numbering(temp_dir)

        default_header = resolve_default_header(temp_dir)
        if default_header and os.path.exists(default_header):
            patch_header(default_header, header_text)
        inject_keymap_customizations(temp_dir, shortcut_template)

        rebuilt = docx_path + ".tmp"
        with zipfile.ZipFile(rebuilt, "w", zipfile.ZIP_DEFLATED) as archive:
            for root, _, files in os.walk(temp_dir):
                for filename in files:
                    full_path = os.path.join(root, filename)
                    rel_path = os.path.relpath(full_path, temp_dir)
                    archive.write(full_path, rel_path)
        shutil.move(rebuilt, docx_path)
        return 0
    finally:
        shutil.rmtree(temp_dir, ignore_errors=True)


if __name__ == "__main__":
    raise SystemExit(main())
