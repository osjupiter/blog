#!/usr/bin/env python3
"""Generate the top-level index.html from articles/*/index.html.

Each article lives in its own directory under articles/ and must contain an
index.html with a <title> tag. A <p class="subtitle"> is used as the summary
if present. Dates come from git history (first/last commit touching the dir).
"""

import html
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ARTICLES_DIR = ROOT / "articles"
OUTPUT = ROOT / "index.html"
SITEMAP = ROOT / "sitemap.xml"
BASE_URL = "https://osjupiter.github.io/blog/"
SITE_TITLE = "osjupiter — articles"
SITE_DESCRIPTION = "Notes on storage, kernels, and things measured rather than assumed."

TITLE_RE = re.compile(r"<title>(.*?)</title>", re.S)
SUBTITLE_RE = re.compile(r'<p class="subtitle">(.*?)</p>', re.S)


def git(*args: str) -> list[str]:
    return subprocess.run(
        ["git", *args], cwd=ROOT, capture_output=True, text=True,
    ).stdout.split("\n")


def git_dates(path: Path) -> tuple[str, str]:
    """Return (first, last) commit dates for a path, YYYY-MM-DD.

    Articles imported via `git subtree add` keep their original history on the
    merge's second parent, where files sit at the repo root — so a plain
    path-filtered log would only see the import commit. Collect dates from
    non-merge commits touching the path, plus the full history behind any
    subtree merge, and take the min/max.
    """
    rel = str(path.relative_to(ROOT))
    dates = []
    for line in git("log", "--format=%as %P", "--", rel):
        if not line.strip():
            continue
        date, *parents = line.split()
        if len(parents) < 2:
            dates.append(date)
        else:  # subtree merge: use the imported branch's own dates instead
            dates += [d for d in git("log", "--format=%as", parents[1]) if d]
    if not dates:
        return "", ""
    return min(dates), max(dates)


def collect_articles() -> list[dict]:
    articles = []
    for index in sorted(ARTICLES_DIR.glob("*/index.html")):
        text = index.read_text(encoding="utf-8")
        title_m = TITLE_RE.search(text)
        subtitle_m = SUBTITLE_RE.search(text)
        published, updated = git_dates(index.parent)
        articles.append({
            "slug": index.parent.name,
            "has_ja": (index.parent / "index.ja.html").exists(),
            "title": title_m.group(1).strip() if title_m else index.parent.name,
            "subtitle": re.sub(r"<[^>]+>", "", subtitle_m.group(1)).strip() if subtitle_m else "",
            "published": published,
            "updated": updated,
        })
    articles.sort(key=lambda a: a["published"], reverse=True)
    return articles


PAGE = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{site_title}</title>
<meta name="description" content="{site_description}">
<meta name="google-site-verification" content="dKigbZzDLch6rL1o7eUh-98cCvlEwuZ9z-53trMzxSE">
<link rel="canonical" href="{base_url}">
<meta property="og:site_name" content="osjupiter">
<meta property="og:title" content="{site_title}">
<meta property="og:description" content="{site_description}">
<meta property="og:type" content="website">
<meta property="og:url" content="{base_url}">
<meta name="twitter:card" content="summary">
<style>
:root {{
  --bg: #0c0c0c;
  --bg2: #151515;
  --fg: #d4d4d4;
  --fg2: #888;
  --accent: #0af;
}}
* {{ margin: 0; padding: 0; box-sizing: border-box; }}
body {{ background: var(--bg); color: var(--fg); font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif; line-height: 1.7; }}
.container {{ max-width: 860px; margin: 0 auto; padding: 40px 24px; }}
h1 {{ font-size: 1.6em; color: #fff; margin-bottom: 4px; font-family: 'JetBrains Mono', 'Fira Code', monospace; }}
h1 .prompt {{ color: var(--accent); }}
.tagline {{ color: var(--fg2); margin-bottom: 48px; }}
a {{ color: var(--accent); text-decoration: none; }}
a:hover {{ text-decoration: underline; }}
.article {{ display: block; background: var(--bg2); border: 1px solid #222; border-radius: 6px; padding: 20px 24px; margin-bottom: 20px; transition: border-color 0.15s; }}
.article:hover {{ border-color: var(--accent); }}
.article h2 {{ font-size: 1.15em; margin-bottom: 6px; }}
.article h2 a {{ color: #eee; }}
.article p {{ color: var(--fg2); font-size: 0.95em; margin-bottom: 10px; }}
.article .meta {{ color: #555; font-size: 0.8em; font-family: 'JetBrains Mono', 'Fira Code', monospace; }}
.article .meta a {{ color: #888; }}
footer {{ margin-top: 64px; color: #555; font-size: 0.85em; border-top: 1px solid #222; padding-top: 16px; }}
</style>
</head>
<body>
<div class="container">
<h1><span class="prompt">$</span> osjupiter</h1>
<p class="tagline">{site_description}</p>
{items}
<footer><a href="https://github.com/osjupiter">github.com/osjupiter</a></footer>
</div>
</body>
</html>
"""

ITEM = """<div class="article">
<h2><a href="articles/{slug}/">{title}</a></h2>
<p>{subtitle}</p>
<div class="meta">{dates}{ja_link}</div>
</div>"""


def write_sitemap(articles: list[dict]) -> None:
    urls = [(BASE_URL, max((a["updated"] for a in articles), default=""))]
    for a in articles:
        urls.append((f"{BASE_URL}articles/{a['slug']}/", a["updated"]))
        if a["has_ja"]:
            urls.append((f"{BASE_URL}articles/{a['slug']}/index.ja.html", a["updated"]))
    entries = "\n".join(
        f"<url><loc>{html.escape(loc)}</loc>"
        + (f"<lastmod>{lastmod}</lastmod>" if lastmod else "")
        + "</url>"
        for loc, lastmod in urls
    )
    SITEMAP.write_text(
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'
        f"{entries}\n</urlset>\n",
        encoding="utf-8",
    )


def main() -> None:
    articles = collect_articles()
    items = []
    for a in articles:
        dates = a["published"]
        if a["updated"] and a["updated"] != a["published"]:
            dates += f" (updated {a['updated']})"
        ja_link = ""
        if a["has_ja"]:
            ja_link = (f' · <a href="articles/{html.escape(a["slug"], quote=True)}'
                       '/index.ja.html">日本語</a>')
        items.append(ITEM.format(
            slug=html.escape(a["slug"], quote=True),
            title=html.escape(a["title"]),
            subtitle=html.escape(a["subtitle"]),
            dates=html.escape(dates),
            ja_link=ja_link,
        ))
    OUTPUT.write_text(PAGE.format(
        items="\n".join(items),
        site_title=html.escape(SITE_TITLE),
        site_description=html.escape(SITE_DESCRIPTION),
        base_url=html.escape(BASE_URL, quote=True),
    ), encoding="utf-8")
    write_sitemap(articles)
    print(f"Wrote {OUTPUT} and {SITEMAP} ({len(articles)} articles)")


if __name__ == "__main__":
    main()
