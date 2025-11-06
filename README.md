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
Ensure your shell helpers are in place (from ~/.zshrc):

zsh
Copy code
export IMG_BASE="https://raw.githubusercontent.com/ThePirateCowboy/imagesWeb/main"
Later, switch to Pages:

zsh
Copy code
# export IMG_BASE="https://thepiratecowboy.github.io/imagesWeb"
Reload your shell:

bash
Copy code
source ~/.zshrc
🧩 Git Shortcuts
Command	What It Does
gsave "message"	Add → Commit → Rebase (if needed) → Push
gsync	Pull (rebase) + Push changes
gforce "message"	Force-push local state to GitHub
gstatus	Short, clean git status
glog	Compact graph view of recent commits
gclean	Clean and compact the repo
gremote	Show current remote URLs

🖼️ Image URL Shortcuts
Command	Description
imgurl path/to/file.webp	Copy the direct image URL to clipboard
imgurlv path/to/file.webp	Copy image URL + cache-busting timestamp (recommended)
imgfind .png	List all matching image URLs
imgall	List URLs for all images in repo
imgopen path/to/file.jpg	Open live image in browser
imgpickv	🔥 Opens a file-picker → you select an image → copies the cache-busted URL
imgpickpush	Pick an image → commit + push + copy URL in one step

⚡️ Cache-busting (Why It Matters)
When replacing an image, browsers and ReadyMag often cache the old version for speed.
Adding a timestamp query string forces them to fetch the newest version:

bash
Copy code
https://raw.githubusercontent.com/ThePirateCowboy/imagesWeb/main/images/AAA/thumbnail.webp?v=1730934801
The ?v=1730934801 changes each time you use imgurlv or imgpickv,
so your new image always loads instantly — no manual cache clearing.

🧠 Typical Workflow
Add or replace your image in the repo folder (~/WebAssets/images/...)

Commit & push:

bash
Copy code
gsave "update thumbnail for FPS reel"
Copy cache-busted URL:

bash
Copy code
imgurlv images/AAA/thumbnail.webp
→ URL is copied to clipboard automatically

Paste in ReadyMag (e.g. image block, background, or code embed)

Done!
Your live site now serves that image directly from GitHub.

🧰 Optional One-Click Helpers
Command	Action
imgpickv	Opens macOS file dialog → select image → copies live URL w/ cache-buster
imgpickpush	Select image → commits, pushes, and copies URL in one go

These use AppleScript to open a native file picker and automatically compute the correct URL relative to your repo root.

🚀 Switching to GitHub Pages / Custom Domain
Once your domain verification completes:

Enable GitHub Pages → Deploy from branch → main / (root)

Confirm Pages URL (temporary):
https://thepiratecowboy.github.io/imagesWeb

Add your custom CNAME in the repo root (e.g. cdn.benhardingaudio.com)

Update .zshrc:

zsh
Copy code
export IMG_BASE="https://cdn.benhardingaudio.com"
Reload:

bash
Copy code
source ~/.zshrc
Test:

bash
Copy code
imgurlv images/AAA/thumbnail.webp
→ Should now output a clean domain URL.

🪄 Example (current phase)
Input command:

bash
Copy code
imgurlv images/FPS/fps-reel.webp
Output copied to clipboard:

bash
Copy code
https://raw.githubusercontent.com/ThePirateCowboy/imagesWeb/main/images/FPS/fps-reel.webp?v=1730934801
Paste this URL into ReadyMag — it’ll always load the newest version.

📄 License
Personal/internal use only — not a public asset repository.

📝 Notes for future me (Ben):

Switch to Pages URL once domain _github-pages-challenge TXT record verifies.

Keep using imgurlv / imgpickv to avoid stale thumbnails.

Never rename files just to refresh cache — version query handles that.

Remember: gsave handles all commit/push steps safely.

yaml
Copy code

---

Would you like me to include a **small visual table** (for your Obsidian README) showing the URL difference between Raw vs Pages — like side-by-side examples for the same image?