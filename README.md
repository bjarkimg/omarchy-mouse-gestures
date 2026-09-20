# Omarchy mouse gestures

Opera-style mouse gestures for [Omarchy](https://omarchy.org/) / Hyprland.

Hold **right mouse**, flick, release. The compositor sends a shortcut to whatever window is focused, so it works in Chromium, Nautilus, and most GTK apps — not only the browser.

Suggested upstream: https://github.com/omacom/omarchy/discussions/12580

## Gestures

| Hold right, then | Action |
|---|---|
| Flick left | Alt+Left (back) |
| Flick right | Alt+Right (forward) |
| Flick up | Alt+Up (parent folder in Files) |
| Flick down | Alt+Down |
| Down, then right (or ↘) | Ctrl+W (close tab) |
| Click with almost no movement | Normal right-click menu |

Super+right-click still resizes windows. Fullscreen and Steam games skip so RMB is not stolen.

## Install on another Omarchy machine

Needs Hyprland 0.56+ Lua config (`~/.config/hypr/hyprland.lua`).

```bash
git clone https://github.com/bjarkimg/omarchy-mouse-gestures.git
cd omarchy-mouse-gestures
./install.sh
```

That copies `mouse-gestures.lua` into `~/.config/hypr/`, adds `require("hypr.mouse-gestures")` next to your bindings require if it is missing, and runs `hyprctl reload`.

Manual install:

```bash
cp mouse-gestures.lua ~/.config/hypr/
```

Then in `~/.config/hypr/hyprland.lua`, after `require("hypr.bindings")`:

```lua
require("hypr.mouse-gestures")
```

```bash
hyprctl reload
```

## Update

```bash
cd omarchy-mouse-gestures
git pull
./install.sh
```
