# MyLinux branding assets

This directory holds the original MyLinux visual identity. Nothing here is
copied from another distribution; all assets are generated for this project.

| File                              | Purpose                                            |
|-----------------------------------|----------------------------------------------------|
| `os-release`                      | Distribution identity read by `hostnamectl` etc.   |
| `wallpapers/mylinux-default.png`  | Default desktop wallpaper (installed system-wide)  |
| `wallpapers/README.md`            | Wallpaper provenance and replacement instructions  |
| `logo/mylinux-logo.svg`           | Vector logo used in docs and the live environment  |
| `logo/mylinux-logo.txt`           | ASCII wordmark used by terminal tools              |

## Palette

| Token        | Hex       | Use                          |
|--------------|-----------|------------------------------|
| `base`       | `#0d0b14` | darkest background           |
| `surface`    | `#16131f` | panels, cards                |
| `surfaceAlt` | `#1e1a2b` | raised surfaces              |
| `primary`    | `#f5a623` | brand amber accent           |
| `accent`     | `#7c6cf0` | secondary violet accent      |
| `text`       | `#ece9f5` | primary text                 |
| `textDim`    | `#b6afc9` | secondary text               |
| `danger`     | `#ef5f7a` | errors, destructive actions  |
| `success`    | `#5cc98a` | confirmations                |

The same tokens are defined in `desktop/quickshell/theme/Theme.qml` and in
`desktop/hypr/conf.d/appearance.conf`, so the compositor and the shell always
agree on the look.
