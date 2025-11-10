#!/usr/bin/env bash
set -euo pipefail

# ===== Config =====
AUDIO_ROOT="WebsiteReady/AudioPlayer"
MANIFEST="$AUDIO_ROOT/manifest.json"
BASE_URL="https://thepiratecowboy.github.io/imagesWeb"   # your GitHub Pages prefix
PPS=60      # pixels-per-second for waveform density (50–80 looks good)
BITS=8      # 8-bit JSON stays small

# ===== Setup / checks =====
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"
mkdir -p "$AUDIO_ROOT"

FFPROBE="$(command -v ffprobe)"   || { echo "Missing 'ffmpeg' (ffprobe) — brew install ffmpeg"; exit 1; }
FFMPEG="$(command -v ffmpeg)"     || { echo "Missing 'ffmpeg' — brew install ffmpeg"; exit 1; }
AWF="$(command -v audiowaveform)" || { echo "Missing 'audiowaveform' — brew install audiowaveform"; exit 1; }
JQ="$(command -v jq)"             || { echo "Missing 'jq' — brew install jq"; exit 1; }

# Any audio to process? (exclude any prior .fix.wav)
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
echo "Mode: normalize-first (ffmpeg -> 16-bit mono 48k WAV) then audiowaveform"
echo

# ---- helpers ----
dur_sec () {
  "$FFPROBE" -v error -show_entries format=duration \
             -of default=noprint_wrappers=1:nokey=1 "$1" | awk '{printf "%.2f",$1}'
}
last_two_parts () { awk -F/ '{ if (NF>=2) {print $(NF-1)"/"$NF} else {print $0} }'; }

# ===== Main loop =====
# Safe with spaces; ignores *.fix.wav as inputs
while IFS= read -r -d '' REL; do
  DIR="$(dirname "$REL")"
  BASE="$(basename "$REL")"
  STEM="${BASE%.*}"

  PEAK_JSON="${DIR}/${STEM}.peaks.json"
  URL="${BASE_URL}/${REL}"
  PEAK_URL="${BASE_URL}/${PEAK_JSON}"

  # Make sure output dir exists
  mkdir -p "$(dirname "$PEAK_JSON")"

  # Generate peaks if missing
  if [[ -f "$PEAK_JSON" ]]; then
    DUR="$(dur_sec "$REL")"
  else
    echo "Generating peaks:"
    echo "  in : $REL"
    echo "  out: $PEAK_JSON"

    # Normalize to a known-safe temp WAV (16-bit mono 48k)
    FIX="$(mktemp "${TMPDIR:-/tmp}/awffix.XXXXXX").wav"
    "$FFMPEG" -y -hide_banner -loglevel error \
      -i "$REL" -ac 1 -c:a pcm_s16le -ar 48000 "$FIX"

    if [[ ! -s "$FIX" ]]; then
      echo "  ffmpeg failed for: $REL"
      rm -f "$FIX"
      exit 1
    fi

    # Temp output MUST end with .json so audiowaveform recognizes format
    tmp_out="$(mktemp "$(dirname "$PEAK_JSON")/.$(basename "$PEAK_JSON" .json).XXXXXX.json")"
    "$AWF" -i "$FIX" -o "$tmp_out" --pixels-per-second "$PPS" --bits "$BITS"
    mv -f "$tmp_out" "$PEAK_JSON"
    rm -f "$FIX"

    DUR="$(dur_sec "$REL")"
  fi

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

done < <(find "$AUDIO_ROOT" -type f \
          \( -iname "*.wav" -o -iname "*.mp3" -o -iname "*.flac" -o -iname "*.aif" -o -iname "*.aiff" \) \
          -not -name "*.fix.wav" \
          -print0 | sort -z)

"$JQ" '.' "$TMP_JSON" > "$MANIFEST"
echo
echo "Wrote $MANIFEST"