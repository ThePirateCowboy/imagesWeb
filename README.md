# 🎨 WebAssets / imagesWeb  
**Author:** Ben Harding  
**Purpose:** Host and version-control web image assets (e.g., ReadyMag thumbnails, website banners, portfolio images).  
**Repo URL:** https://github.com/ThePirateCowboy/imagesWeb  

---

## 🧭 Overview
This repo acts as a lightweight CDN for my ReadyMag portfolio and other web projects.

It stores all image assets in version control and makes them publicly accessible through GitHub — either via:

- **Raw GitHub URLs** (instant access, for setup/testing)
- **GitHub Pages / Custom Domain** (clean, permanent, production URLs)

Each image can be linked directly from ReadyMag using a full HTTPS URL.

---

## ⚙️ Current Hosting Phase
| Phase | URL Base | Status |
|:------|:----------|:--------|
| **RAW (active)** | `https://raw.githubusercontent.com/ThePirateCowboy/imagesWeb/main` | ✅ in use now |
| **PAGES (planned)** | `https://thepiratecowboy.github.io/imagesWeb`<br>→ eventually `https://cdn.benhardingaudio.com` | 🔜 pending DNS verification |

Once Pages + domain are verified, update `IMG_BASE` in `~/.zshrc` to the Pages URL.

---

## 💻 Local Setup (macOS + zsh)

Clone the repo locally:

```bash
cd ~
git clone git@github.com:ThePirateCowboy/imagesWeb.git WebAssets
cd WebAssets
