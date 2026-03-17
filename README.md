# Personal Psychological Equalizer — Vite Site

This repository contains a small single-page app built with Vite that reproduces the "Personal Psychological Equalizer" UI with sliders, validation rules, and PDF export.

Quick start

1. Install deps

```bash
npm install
```

2. Run dev server

```bash
npm run dev
```

3. Build

```bash
npm run build
```

Deploy

- Cloudflare Pages: connect the repo, set build command `npm run build` and publish directory `dist`.
- GitHub Pages: build and serve `dist` (you can use `gh-pages` or a GitHub Actions workflow to publish `dist` to `gh-pages`).

Notes

- PDF export uses `jspdf`.
- The app is intentionally small and framework-free to keep the bundle minimal.
