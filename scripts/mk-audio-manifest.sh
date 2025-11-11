#!/usr/bin/env bash
set -euo pipefail

# ===== Config (override via env) =====
AUDIO_ROOT="${AUDIO_ROOT:-WebsiteReady/AudioPlayer}"
MANIFEST="$AUDIO_ROOT/manifest.json"
BASE_URL="${BASE_URL:-https://thepiratecowboy.github.io/imagesWeb}"  # GitHub Pages prefix
PPS="${PPS:-1200}"     # pixels-per-second for waveform density
BITS="${BITS:-16}"     # 8 or 16
FORCE="${FORCE:-0}"    # set FORCE=1 to regenerate even if peaks look OK

# ===== Setup / checks =====
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"
mkdir -p "$AUDIO_ROOT"

FFPROBE="$(command -v ffprobe)"   || { echo "Missing 'ffprobe' (from ffmpeg) — brew install ffmpeg"; exit 1; }
FFMPEG="$(command -v ffmpeg)"     || { echo "Missing 'ffmpeg' — brew install ffmpeg"; exit 1; }
AWF="$(command -v audiowaveform)" || { echo "Missing 'audiowaveform' — brew install audiowaveform"; exit 1; }
JQ="$(command -v jq)"             || { echo "Missing 'jq' — brew install jq"; exit 1; }

# Any audio to process? (exclude *.fix.wav as inputs)
if ! find "$AUDIO_ROOT" -type f \
     \( -iname "*.wav" -o -iname "*.mp3" -o -iname "*.flac" -o -iname "*.aif" -o -iname "*.aiff" \) \
     -not -name "*.fix.wav" | grep -q .; then
  echo "No audio files found under $AUDIO_ROOT"
  echo "Put files in e.g. $AUDIO_ROOT/Weapon-Melee/Axe/WeaponSwingHeavy and re-run."
  exit 1
fi

TMP_JSON="$(mktemp)"
echo "{\"categories\":{}, \"tracks\":{}, \"updated\":$(date +%s)}" > "$TMP_JSON"

echo "Scanning under: $AUDIO_ROOT"
echo "Mode: ffmpeg -> mono 48k .fix.wav, then audiowaveform at ${PPS}pps, ${BITS}-bit"
echo

# ---- helpers ----
dur_sec () {
  "$FFPROBE" -v error -show_entries format=duration \
             -of default=noprint_wrappers=1:nokey=1 "$1" | awk '{printf "%.2f",$1}'
}
last_two_parts () { awk -F/ '{ if (NF>=2) {print $(NF-1)"/"$NF} else {print $0} }'; }

needs_regen () {
  # returns 0 (true) if we should rebuild, 1 otherwise
  local json="$1"
  # Rebuild if peaks file doesn't exist
  if [ ! -f "$json" ]; then
    return 0
  fi
  # Check metadata inside peaks JSON
  local spp bits
  spp="$($JQ -r '.samples_per_pixel // .samplesPerPixel // empty' "$json" 2>/dev/null || true)"
  bits="$($JQ -r '.bits // empty' "$json" 2>/dev/null || true)"
  if [ -z "$spp" ] || [ -z "$bits" ]; then
    return 0
  fi
  # PPS or bit depth changed?
  if [ "$spp" != "$PPS" ] || [ "$bits" != "$BITS" ]; then
    return 0
  fi
  # Otherwise keep it
  return 1
}

# ===== Main loop =====
while IFS= read -r -d '' REL; do
  DIR="$(dirname "$REL")"
  BASE="$(basename "$REL")"
  STEM="${BASE%.*}"

  PEAK_JSON="${DIR}/${STEM}.peaks.json"
  URL="${BASE_URL}/${REL}"
  PEAK_URL="${BASE_URL}/${PEAK_JSON}"

  mkdir -p "$(dirname "$PEAK_JSON")"

  # Choose input: prefer normalized .fix.wav if it exists
  IN="$REL"
  if [ -f "${REL%.*}.fix.wav" ]; then
    IN="${REL%.*}.fix.wav"
  else
    # Make a temp normalized mono 48k if source isn't already .fix.wav
    # (skip if it's already mono 48k PCM)
    # You can comment this block out if you don't want auto-normalization.
    TMP_FIX="$(mktemp -t awf_fix_XXXXXX).wav"
    "$FFMPEG" -y -hide_banner -loglevel error -i "$REL" -ac 1 -c:a pcm_s16le -ar 48000 "$TMP_FIX"
    IN="$TMP_FIX"
  fi

  # Generate peaks if missing / forced / config changed
  if [ "$FORCE" = "1" ] || needs_regen "$PEAK_JSON"; then
    echo "Generating peaks (high detail):"
    echo "  in : $IN"
    echo "  out: $PEAK_JSON"
    "$AWF" \
      -i "$IN" \
      -o "$PEAK_JSON" \
      -b "$BITS" \
      --pixels-per-second "$PPS"
  fi

  # Duration for manifest (use input we rendered from)
  DUR="$(dur_sec "$IN")"

  # Category = last two dirs under AUDIO_ROOT (e.g. Axe/WeaponSwingHeavy)
  UNDER_AP="${REL#${AUDIO_ROOT}/}"
  CATEGORY="$(dirname "$UNDER_AP" | last_two_parts)"

  # ID = "category/stem" sanitized (slashes -> -- ; trim trailing dashes)
  ID_RAW="${CATEGORY}/${STEM}"
  ID="$(echo "$ID_RAW" \
    | tr '[:space:]' '-' \
    | tr -cd '[:alnum:]\-/_' \
    | sed 's#/#--#g; s/-\+$//')"

  "$JQ" --arg cat "$CATEGORY" \
        --arg id "$ID" \
        --arg url "$URL" \
        --arg pk "$PEAK_URL" \
        --arg t "$STEM" \
        --arg dur "$DUR" \
        '
        .categories[$cat] = (.categories[$cat] // []) +
          [{"id":$id,"title":$t,"src":$url,"peaks":$pk,"dur":($dur|tonumber)}]
        | .tracks[$id] = {"id":$id,"title":$t,"src":$url,"peaks":$pk,"dur":($dur|tonumber),"category":$cat}
        ' "$TMP_JSON" > "${TMP_JSON}.new" && mv "${TMP_JSON}.new" "$TMP_JSON"

  # Clean up temp fix if created
  if [[ "${IN}" == /var/folders/*awf_fix_* ]] || [[ "${IN}" == /tmp/awf_fix_* ]]; then
    rm -f "$IN" || true
  fi
done < <(find "$AUDIO_ROOT" -type f \
          \( -iname "*.wav" -o -iname "*.mp3" -o -iname "*.flac" -o -iname "*.aif" -o -iname "*.aiff" \) \
          -not -name "*.fix.wav" \
          -print0 | sort -z)

"$JQ" '.' "$TMP_JSON" > "$MANIFEST"
echo
echo "Wrote $MANIFEST"