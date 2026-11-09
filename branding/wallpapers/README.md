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

## Changing the wallpaper

Wallpapers are applied by `awww`, driven from the launcher:

- **Interactive:** `SUPER + SHIFT + W` opens the wallpaper selector; picking a
  tile applies it immediately and persists the choice.
- **Command line:** `awww img /usr/share/mylinux/wallpapers/<file>.png`.
- **Extra wallpapers:** drop a PNG/JPG/WebP into `/usr/share/mylinux/wallpapers/`
  and it appears in the selector on the next open.

Wallpapers are regenerated from the design brief in `branding/README.md`; no
third-party wallpaper is bundled.