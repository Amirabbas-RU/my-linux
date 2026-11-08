# Building the MyLinux ISO

The ISO is produced by [Archiso](https://wiki.archlinux.org/title/Archiso) from
the profile in `iso/`. This document explains the build, the resulting artefacts
and how to verify them.

## Requirements

Run the build **inside the MyLinux development VM**, never on the host.

| Requirement      | Notes                                                       |
|-----------------|-------------------------------------------------------------|
| Arch Linux       | The build host must be Arch (mkarchiso uses pacman/pacstrap) |
| Root privileges  | `mkarchiso` needs root                                      |
| Disk space       | ~10 GB free for work/ + out/                                 |
| Network          | Packages are downloaded during the build                     |
| Tools            | `archiso`, `arch-install-scripts`, `squashfs-tools`, `libisoburn`, `mtools` |

Install them:

```bash
sudo pacman -S --needed archiso arch-install-scripts \
    squashfs-tools libisoburn mtools
```

## Build

```bash
# pre-flight only (no root required)
./iso/build.sh --check

# full build
sudo ./iso/build.sh

# clean rebuild
sudo ./iso/build.sh --clean
```

`iso/build.sh` performs these steps:

1. **Pre-flight**: verifies required tools, the profile layout, UEFI status, and
   regenerates `iso/packages.x86_64` from `packages/live.txt`.
2. **Stage payload**: copies `packages/`, `desktop/`, `system/`, `docs/`,
   `branding/`, `installer/` into `iso/airootfs/usr/share/mylinux/`, and installs
   the `mylinux-install` launcher into the live environment.
3. **mkarchiso**: builds the squashfs and the ISO into `out/`.
4. **Checksum**: writes `out/<iso>.sha256`.

Typical build time is 15–40 minutes depending on CPU and network.

### Build output

```
out/
├── mylinux-YYYY.MM.DD-x86_64.iso
└── mylinux-YYYY.MM.DD-x86_64.iso.sha256
work/                       # intermediate build tree (safe to delete)
```

The `.iso` and `.sha256` are git-ignored.

## What the ISO contains

- The Arch kernel and an Archiso initramfs.
- The live environment defined by `iso/airootfs/` and `packages/live.txt`.
- The MyLinux installer (`/usr/local/bin/mylinux-install` → the staged
  frontend at `/usr/share/mylinux/installer/frontend/mylinux-install`).
- The MyLinux configuration tree at `/usr/share/mylinux/` (so the installer can
  copy desktop configs into the target without network access).
- Documentation at `/usr/share/doc/mylinux/`.
- UEFI boot entries for systemd-boot and a GRUB menu (both are configured in
  `profiledef.sh` via `bootmodes=('uefi.grub' 'uefi.systemd-boot')`).

## Boot modes

`iso/profiledef.sh` sets:

```sh
bootmodes=('uefi.grub' 'uefi.systemd-boot')
```

Both UEFI paths are built. The GRUB menu also offers the screen-reader entry and
firmware settings; systemd-boot offers the same entries from
`iso/efiboot/loader/entries/`.

> BIOS/legacy boot is not enabled. MyLinux installs only on UEFI, so the ISO does
> not need a legacy path.

## Verify the ISO

```bash
cd out
sha256sum -c mylinux-*.iso.sha256
file mylinux-*.iso
isoinfo -d -i mylinux-*.iso | head -20      # optional, needs cdrkit
```

## Boot-test the ISO

The repository includes a nested-VM boot test. It boots the ISO with OVMF (UEFI)
in an isolated QEMU VM and waits for the MyLinux live welcome banner.

```bash
sudo ./tests/boot_iso_test.sh out/mylinux-*.iso
sudo ./tests/boot_iso_test.sh out/mylinux-*.iso --timeout 600   # slower machines
```

What it checks:

- The UEFI firmware finds and boots the ISO.
- The kernel and Archiso initramfs mount the squashfs root.
- The live system reaches multi-user and the MyLinux welcome/installer starts.

The test only uses the given ISO and a temporary qcow2 disk in `/tmp`. It never
touches a host disk, the development VM disk or the cold backup.

To watch the boot interactively instead:

```bash
qemu-system-x86_64 -machine q35 -m 2048 -cpu max \
    -drive if=pflash,format=raw,readonly=on,file=/usr/share/edk2/x64/OVMF_CODE.4m.fd \
    -drive if=pflash,format=raw,file=/tmp/OVMF_VARS.fd \
    -drive file=out/mylinux-*.iso,media=cdrom,readonly=on \
    -display gtk -serial stdio
```

## Reproducibility

The profile is plain files in the repository, so a build is defined by the commit
you build from:

- Package selection is pinned by `packages/live.txt`.
- `iso/build.sh` regenerates `packages.x86_64` before every build, so the live
  image cannot drift from the source of truth.
- The installer and configuration tree are staged from the same tree, so the ISO
  and the installed system always agree.

Full bit-for-bit reproducibility also depends on upstream package versions and
timestamps; Arch is a rolling release, so two builds on different days will differ
in package versions. Within the same repository commit and package snapshot the
build is deterministic.

## Cleaning up

```bash
sudo rm -rf work out        # remove build tree and images
```

`work/` is large (several GB) and can always be regenerated.

## Troubleshooting

| Symptom                              | Fix                                                    |
|--------------------------------------|--------------------------------------------------------|
| `mkarchiso: command not found`       | `pacman -S archiso`                                    |
| `target not found: <pkg>`            | The package was removed from the repos; update `packages/live.txt`. |
| Build fails during pacstrap          | Stale package DB; `sudo pacman -Syu` on the build host. |
| ISO builds but does not boot         | Run the boot test and read the serial log for the failure. |
| `no space left on device`            | Free space in the VM; `work/` needs several GB.        |