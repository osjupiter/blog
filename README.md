# blog

Self-contained HTML articles, one directory each, with an auto-generated index.

## Layout

```
articles/<slug>/index.html   # one article = one directory (images, js, data all live inside)
scripts/build_index.py       # generates the top-level index.html + sitemap.xml
index.html                   # generated — do not edit by hand
sitemap.xml                  # generated — do not edit by hand
```

## Adding an article

1. Create `articles/<slug>/` with an `index.html`. The index generator reads
   its `<title>` and the first `<p class="subtitle">`, and takes published /
   updated dates from git history.
   For SEO, also give each article a `<meta name="description">`, a
   `<link rel="canonical">` pointing at
   `https://osjupiter.github.io/blog/articles/<slug>/`, and Open Graph tags
   (copy the head of an existing article).
2. Commit and push. The GitHub Actions workflow rebuilds `index.html` and
   deploys everything to GitHub Pages.

To preview locally:

```sh
python3 scripts/build_index.py
python3 -m http.server
```

## History

`articles/block-trace-viz` and `articles/era-differential-backup` were
imported from their original repositories with full history via
`git subtree add`.
