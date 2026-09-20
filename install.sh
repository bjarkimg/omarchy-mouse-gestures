#!/usr/bin/env bash
set -euo pipefail

src="$(cd "$(dirname "$0")" && pwd)/mouse-gestures.lua"
dest="${HOME}/.config/hypr/mouse-gestures.lua"
hypr="${HOME}/.config/hypr/hyprland.lua"

if [[ ! -f "$src" ]]; then
  echo "missing $src" >&2
  exit 1
fi

mkdir -p "$(dirname "$dest")"
cp "$src" "$dest"
echo "installed $dest"

if [[ ! -f "$hypr" ]]; then
  echo "no $hypr — add: require(\"hypr.mouse-gestures\")" >&2
  exit 1
fi

if grep -Fq 'require("hypr.mouse-gestures")' "$hypr"; then
  echo "hyprland.lua already requires hypr.mouse-gestures"
else
  python3 - "$hypr" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()
needle = 'require("hypr.bindings")'
insert = needle + '\nrequire("hypr.mouse-gestures")'
if needle in text:
    path.write_text(text.replace(needle, insert, 1))
    print(f"added require to {path}")
else:
    print(f'add this line to {path}:', file=sys.stderr)
    print('require("hypr.mouse-gestures")', file=sys.stderr)
    sys.exit(1)
PY
fi

if command -v hyprctl >/dev/null 2>&1; then
  hyprctl reload
  errors="$(hyprctl configerrors || true)"
  if [[ -n "$errors" ]]; then
    echo "$errors" >&2
    exit 1
  fi
  echo "hyprland reloaded"
else
  echo "hyprctl not found; reload Hyprland yourself"
fi
