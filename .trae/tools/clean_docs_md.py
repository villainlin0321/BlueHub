from __future__ import annotations

import html
import re
from pathlib import Path


def _normalize_newlines(s: str) -> str:
    return s.replace("\r\n", "\n").replace("\r", "\n")


def _clean_common(s: str) -> str:
    s = _normalize_newlines(s)
    s = re.sub(r"\n<!--\s*-->\s*\n", "\n", s)
    s = s.replace("&lt;/gird&gt;", "")
    s = s.replace("<br />", "\n").replace("<br/>", "\n")

    def img_to_md(m: re.Match) -> str:
        src = m.group(1)
        bang = chr(33)
        return f"{bang}[]({src})"

    s = re.sub(r'<img\s+[^>]*src="([^"]+)"[^>]*/?>', img_to_md, s)
    return s


def _strongify(s: str) -> str:
    return s.replace("<strong>", "**").replace("</strong>", "**")


def _strip_tags_keep_breaks(s: str) -> str:
    s = _normalize_newlines(s)
    s = _strongify(s)
    s = re.sub(r"</p\s*>", "\n\n", s)
    s = re.sub(r"<p\s*>", "", s)
    s = re.sub(r"<li\s*>\s*", "- ", s)
    s = re.sub(r"</li\s*>", "\n", s)
    s = re.sub(r"</?ul\s*>", "", s)
    s = re.sub(r"</?thead\s*>", "", s)
    s = re.sub(r"</?tbody\s*>", "", s)
    s = re.sub(r"</?tr\s*>", "", s)
    s = re.sub(r"</?th\s*>", "", s)
    s = re.sub(r"</?td\s*>", "", s)
    s = re.sub(r"<colgroup\b[^>]*>.*?</colgroup>", "", s, flags=re.S)
    s = re.sub(r"<col\b[^>]*/?>", "", s)
    s = re.sub(r"<table\b[^>]*>", "", s)
    s = re.sub(r"</table\s*>", "", s)
    s = re.sub(r"<[^>]+>", "", s)
    s = html.unescape(s)
    s = re.sub(r"\n{3,}", "\n\n", s)
    return s.strip()


def _convert_numbered_bold_headings(s: str) -> str:
    lines = s.split("\n")
    out: list[str] = []
    for line in lines:
        m = re.match(r"^\*\*(\d+(?:\.\d+)*)\.\s*(.+?)\*\*\s*$", line.strip())
        if m:
            nums = m.group(1)
            title = m.group(2)
            level = nums.count(".") + 2
            level = max(2, min(6, level))
            out.append("#" * level + f" {nums}. {title}")
        else:
            out.append(line)

    s2 = "\n".join(out)
    s2 = re.sub(r"\A\*\*(.+?)\*\*\s*\n", lambda m: f"# {m.group(1).strip()}\n", s2)
    return s2


def _convert_flow_tables(s: str) -> str:
    def repl(m: re.Match) -> str:
        block = m.group(0)
        th = re.search(r"<th>([\s\S]*?)</th>", block)
        inner = th.group(1) if th else block
        cleaned = _strip_tags_keep_breaks(inner)
        if not cleaned:
            return ""
        return cleaned + "\n\n"

    s = re.sub(r"<table\b[\s\S]*?</table>\s*", repl, s)
    s = re.sub(r"\n{3,}", "\n\n", s)
    return s


def _html_cell_to_inline(cell_html: str) -> str:
    t = _normalize_newlines(cell_html)
    t = _strongify(t)
    t = re.sub(r"</p\s*>", "\n", t)
    t = re.sub(r"<p\s*>", "", t)
    t = re.sub(r"</?ul\s*>", "", t)
    t = re.sub(r"<li\s*>\s*", "", t)
    t = re.sub(r"</li\s*>", "\n", t)
    t = re.sub(r"<[^>]+>", "", t)
    t = html.unescape(t)
    lines = [ln.strip() for ln in t.split("\n") if ln.strip()]
    inline = "<br>".join(lines).replace("|", r"\|")
    return inline


def _convert_prd_user_portrait_table(s: str) -> str:
    m = re.search(r"<table\b[\s\S]*?</table>", s)
    if not m:
        return s
    block = m.group(0)

    headers = re.findall(r"<th>\s*(?:<strong>)?([^<]+?)(?:</strong>)?\s*</th>", block)
    rows = re.findall(r"<tr>\s*([\s\S]*?)\s*</tr>", block)
    body_rows: list[list[str]] = []
    for r in rows[1:]:
        cells = re.findall(r"<td>([\s\S]*?)</td>", r)
        if len(cells) != 3:
            continue
        body_rows.append([_html_cell_to_inline(c) for c in cells])

    if len(headers) >= 3 and body_rows:
        md: list[str] = []
        md.append("| " + " | ".join(h.strip() for h in headers[:3]) + " |")
        md.append("| " + " | ".join(["---"] * 3) + " |")
        for r in body_rows:
            md.append("| " + " | ".join(r) + " |")
        replacement = "\n".join(md) + "\n"
        s = s[: m.start()] + replacement + s[m.end() :]
    return s


def _convert_prd_roadmap_table(s: str) -> str:
    anchor = re.search(
        r"(?:\*\*|#{1,6}\s*)1\.3\.\s*产品路线图\s*\(Roadmap\)(?:\*\*)?",
        s,
    )
    if not anchor:
        return s

    after = s[anchor.end() :]
    start_in_after = after.find("<table")
    if start_in_after < 0:
        return s

    def find_matching_table_end(text: str, start: int) -> int:
        tag_re = re.compile(r"</?table\b", flags=re.I)
        depth = 0
        for m in tag_re.finditer(text, start):
            if text[m.start() : m.start() + 2] == "</":
                depth -= 1
                if depth == 0:
                    end_tag = re.search(r"</table\s*>", text[m.start() :], flags=re.I)
                    if not end_tag:
                        return -1
                    return m.start() + end_tag.end()
            else:
                depth += 1
        return -1

    end_in_after = find_matching_table_end(after, start_in_after)
    if end_in_after < 0:
        return s

    table_block = after[start_in_after:end_in_after]

    nested_tables: list[str] = []
    pos = 0
    th_table_re = re.compile(r"<th>\s*<table\b", flags=re.I)
    while True:
        m = th_table_re.search(table_block, pos)
        if not m:
            break
        nested_start = table_block.find("<table", m.start())
        nested_end = find_matching_table_end(table_block, nested_start)
        if nested_start < 0 or nested_end < 0:
            break
        nested_tables.append(table_block[nested_start:nested_end])
        pos = nested_end

    sections: list[tuple[str, list[str]]] = []
    for nb in nested_tables:
        inner = re.search(r"<th>([\s\S]*?)</th>", nb, flags=re.I)
        content = inner.group(1) if inner else nb
        cleaned = _strip_tags_keep_breaks(content).replace("\n\n", "\n")
        lines = [ln.strip() for ln in cleaned.split("\n") if ln.strip()]
        if not lines:
            continue
        title = lines[0].strip("*").strip()
        bullets: list[str] = []
        for ln in lines[1:]:
            bullets.append(ln if ln.startswith("- ") else "- " + ln)
        sections.append((title, bullets))

    if not sections:
        return s

    md_parts: list[str] = []
    for title, bullets in sections:
        md_parts.append(f"### {title}")
        md_parts.extend(bullets)
        md_parts.append("")
    replacement = "\n".join(md_parts).rstrip() + "\n"

    start = anchor.end() + start_in_after
    end = anchor.end() + end_in_after
    s = s[:start] + "\n\n" + replacement + s[end:]
    return s


def _fix_markdown_table_row_wrapping(s: str) -> str:
    lines = s.split("\n")
    out: list[str] = []
    i = 0
    while i < len(lines):
        line = lines[i]
        if line.startswith("| 角色 |") and i + 1 < len(lines):
            out.append(line)
            i += 1
            out.append(lines[i])
            i += 1
            while i < len(lines):
                if not lines[i].startswith("|"):
                    if lines[i].strip() == "":
                        out.append(lines[i])
                        i += 1
                        break
                    i += 1
                    continue
                row = lines[i]
                i += 1
                while i < len(lines) and not lines[i].startswith("|") and lines[i].strip() != "":
                    row += "<br>" + lines[i].strip()
                    i += 1
                out.append(row)
                if i < len(lines) and lines[i].strip() == "":
                    out.append(lines[i])
                    i += 1
                    break
            continue
        out.append(line)
        i += 1
    return "\n".join(out)


def _finalize(s: str) -> str:
    s = _clean_common(s)
    s = _convert_numbered_bold_headings(s)
    s = re.sub(r"\n{3,}", "\n\n", s)
    return s.strip() + "\n"


def main() -> None:
    prd = Path("/Users/xinren/BlueHub/docs/prd/出海签证与招聘平台产品需求文档 (PRD)-.md")
    flow = Path("/Users/xinren/BlueHub/docs/prd/欧洲蓝领签证服务平台关键流程白板集.md")

    flow_text = flow.read_text(encoding="utf-8")
    flow_text = _clean_common(flow_text)
    flow_text = _convert_flow_tables(flow_text)
    flow_text = _convert_numbered_bold_headings(flow_text)
    flow_text = re.sub(r"\n{3,}", "\n\n", flow_text).strip() + "\n"
    flow.write_text(flow_text, encoding="utf-8")

    prd_text = prd.read_text(encoding="utf-8")
    prd_text = _clean_common(prd_text)
    prd_text = _convert_prd_user_portrait_table(prd_text)
    prd_text = _convert_prd_roadmap_table(prd_text)
    prd_text = _fix_markdown_table_row_wrapping(prd_text)
    prd_text = _convert_numbered_bold_headings(prd_text)
    prd_text = re.sub(r"\n{3,}", "\n\n", prd_text).strip() + "\n"
    prd.write_text(prd_text, encoding="utf-8")


if __name__ == "__main__":
    main()
