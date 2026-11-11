# MyLinux wallpapers

The wallpapers in this directory are generated specifically for MyLinux and
match the palette in `branding/README.md`. `mylinux-default.png` is the one
every installation starts with.

| File | Palette | Character |
| ---- | ------- | --------- |
| `mylinux-default.png` | primary `#F5A623` | warm amber gradient, the shipping default |
| `mylinux-violet.png`  | accent `#7C6CF0`  | cool violet glow |
| `mylinux-ridge.png`   | mixed             | layered ridgeline |
| `mylinux-grid.png`    | accent            | perspective grid |
| `mylinux-dunes.png`   | primary           | soft dunes |
| `mylinux-eclipse.png` | mixed             | dark eclipse ring |

All six are 2560×1440 PNGs. The installer copies every `*.png` here into
`/usr/share/mylinux/wallpapers/`, and the launcher lists whatever it finds there.

Wallpapers are regenerated from the design brief in `branding/README.md`; no
third-party wallpaper is bundled.

## How wallpapers are set

Wallpapers are drawn by [`awww`](https://codeberg.org/itdomi/awww) (the
maintained successor to `swww`). `awww-daemon` is started at login from
`desktop/hypr/conf.d/autostart.lua`, and every change is sent to it with
`awww img`. `hyprpaper` is not used anywhere; there is no `hyprpaper.conf` to
edit.

### Selecting and applying

- **Interactive:** `SUPER + SHIFT + W` opens the wallpaper selector. Picking a
  tile applies it immediately and records the choice.
- **Command line:** `awww img /usr/share/mylinux/wallpapers/<file>.png`.

The selector lists every `*.png`, `*.jpg`, `*.jpeg`, and `*.webp` in
`/usr/share/mylinux/wallpapers/`. If `awww-daemon` is not running it is started
automatically before the image is applied.

### Persistence

The chosen path is saved to `~/.local/state/mylinux/launcher.json` (the
`wallpaper` field, alongside favorites and the search provider). When the shell
starts it reapplies that path; if nothing has been saved it falls back to
`/usr/share/mylinux/wallpapers/mylinux-default.png`. Restarting the shell
therefore never resets the wallpaper.

## Adding a wallpaper

1. Drop the image into `branding/wallpapers/` in the repository.
2. Add a row to the table above.
3. Reinstall, or copy it straight to `/usr/share/mylinux/wallpapers/` on a
   running system.

Any file placed in `/usr/share/mylinux/wallpapers/` appears in the selector on
the next open; no configuration change is required.