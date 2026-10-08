#!/bin/sh
# Santino - pin a screenshot of the selected region on screen, with the
# recognized text overlaid as real selectable text.
#
#   santino.sh                 Pin the selected region on screen. A window
#                              covers the region exactly, showing the capture
#                              with the OCR text placed over the text's actual
#                              position in the image (selectable). Keys inside
#                              the window:
#                                Esc        close
#                                Ctrl+C     copy selected text (all if none)
#                                Ctrl+A     select all in the focused line
#                                t          toggle the text overlay
#                                o          re-run OCR on the pinned image
#   santino.sh -l LANG         OCR language (default: eng).
#   santino.sh --ocr [FILE]    Forwarded to santino-ocr.sh (convenience).
#   santino.sh --help          Show this help.
#
# Depends on: slurp, grim, python3 + python-gobject (Gtk3); OCR additionally
# needs santino-ocr.sh, tesseract and wl-clipboard.

# Path to this script and its companions.
script=$(readlink -f "$0" 2>/dev/null)
[ -n "$script" ] || script=$(command -v santino.sh 2>/dev/null || printf '%s\n' "$0")
ocr_script=$(command -v santino-ocr.sh 2>/dev/null || printf '%s\n' "$(dirname "$script")/santino-ocr.sh")

usage() {
  printf '%s\n' \
    'Usage: santino.sh [--ocr [FILE]] [-l LANG]' \
    '  Pin the selected region on screen with selectable OCR text on top.' \
    '  --ocr [FILE] forwards to santino-ocr.sh instead of pinning.' \
    '  -l LANG selects the OCR language (default eng).' \
    ''
}

# notify <urgency> <summary> <body>
notify() {
  notify-send -a santino -t 5000 -u "$1" "$2" "$3" 2>/dev/null || :
}

lang=eng

while [ $# -gt 0 ]; do
  case "$1" in
    --ocr|-o)      exec "$ocr_script" "$@" ;;
    --pin|-p)      : ;;                       # pin is the default mode
    --lang|-l)     lang=$2; shift ;;
    --help|-h)     usage; exit 0 ;;
    --*)           printf 'Unknown option: %s\n' "$1" >&2; usage; exit 2 ;;
    *)             printf 'Unexpected argument: %s\n' "$1" >&2; usage; exit 2 ;;
  esac
  shift
done

pin_region() {
  coords=$(slurp -f '%x %y %w %h') || exit 0
  [ -n "$coords" ] || exit 0     # selection cancelled

  set -- $coords
  x=$1 y=$2 w=$3 h=$4

  tmpfile=$(mktemp "${TMPDIR:-/tmp}/santino.XXXXXX.png") || exit 1
  trap 'sleep 1; rm -f "$tmpfile"' EXIT HUP INT TERM

  grim -g "$x,$y ${w}x${h}" "$tmpfile" || {
    notify critical 'Santino' 'Failed to capture the region.'
    exit 1
  }

  # The GUI runs OCR itself (positioned, selectable text); it reads the
  # capture through santino-ocr.sh --tsv before we remove the temp file.
  "$(dirname "$script")/santino-gui.py" \
      --image "$tmpfile" --region "$x,$y,$w,$h" --lang "$lang"
}

pin_region