# MyLinux wallpapers

`mylinux-default.png` is generated specifically for MyLinux and is the wallpaper
shipped on every installation. It matches the palette documented in
`branding/README.md`.

## Installing a wallpaper

- **System default (all users):** replace
  `/usr/share/mylinux/wallpapers/mylinux-default.png`.
- **Per user:** drop a file in `~/.local/share/wallpapers/` and point
  `desktop/hypr/hyprpaper.conf` at it, or use `hyprctl hyprpaper wallpaper`.

Wallpapers are regenerated from the design brief in `branding/README.md`; no
third-party wallpaper is bundled.
