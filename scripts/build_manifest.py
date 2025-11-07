#!/usr/bin/env python3
import os, json, time, urllib.parse, sys

# --- CONFIG ---
# Base URL for your GitHub Pages project (no trailing slash)
BASE = "https://thepiratecowboy.github.io/imagesWeb"

# Which file extensions to include
EXTS = {".jpg",".jpeg",".png",".webp",".gif",".svg"}

# Directories to skip (git internals, caches, etc.)
SKIP_DIRS = {".git","node_modules",".github",".idea",".vscode"}

# If a sidecar file "<asset>.<ext>.id" exists with a custom ID, we use it
# Otherwise: id = "<parent>-<stem>", lowercased
def slug(s): 
    return "".join(c.lower() if c.isalnum() else "-" for c in s).strip("-").replace("--","-")

def derive_id(relpath):
    parent = slug(os.path.basename(os.path.dirname(relpath))) or "root"
    stem = slug(os.path.splitext(os.path.basename(relpath))[0])
    return f"{parent}-{stem}"

root = os.getcwd()
manifest = {}
seen_ids = set()

for dirpath, dirnames, filenames in os.walk(root):
    # prune unwanted dirs
    dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS and not d.startswith(".")]
    for fn in filenames:
        ext = os.path.splitext(fn)[1].lower()
        if ext not in EXTS: 
            continue
        abspath = os.path.join(dirpath, fn)
        relpath = os.path.relpath(abspath, root)
        # URL-encode path segments
        webpath = urllib.parse.quote(relpath.replace(os.sep, "/"))

        # Cache-buster: use file mtime (stable per change)
        v = int(os.path.getmtime(abspath))
        url = f"{BASE}/{webpath}?v={v}"

        # Optional sidecar ID file
        sidecar = abspath + ".id"
        if os.path.exists(sidecar):
            with open(sidecar, "r", encoding="utf-8") as f:
                _id = f.read().strip()
                _id = slug(_id) or derive_id(relpath)
        else:
            _id = derive_id(relpath)

        # Avoid accidental duplicates by appending a suffix
        base_id = _id
        i = 2
        while _id in seen_ids:
            _id = f"{base_id}-{i}"
            i += 1
        seen_ids.add(_id)
        manifest[_id] = url

out_path = os.path.join(root, "manifest.json")
with open(out_path, "w", encoding="utf-8") as f:
    json.dump(manifest, f, indent=2)

print(f"Wrote {len(manifest)} entries to manifest.json")

