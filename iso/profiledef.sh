#!/usr/bin/env bash
# MyLinux Archiso profile definition.
#
# Consumed by mkarchiso. Defines the image name, filesystem flags for the
# squashfs/ISO and the boot modes. See archiso(1) for the full schema.

iso_name="mylinux"
iso_label="MYLINUX_$(date +%Y%m)"
iso_publisher="MyLinux <https://github.com/Amirabbas-RU/my-linux>"
iso_application="MyLinux live/installation medium"
iso_version="$(date +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')
bootmodes=('uefi.systemd-boot')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '15' '-b' '1M')
bootstrap_tarball_compression=('zstd' '-c' '-T0' '--long=30')
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/etc/gshadow"]="0:0:400"
  ["/root"]="0:0:750"
  ["/usr/local/bin/mylinux-install"]="0:0:755"
  ["/usr/local/bin/mylinux-live-welcome"]="0:0:755"
  ["/usr/local/bin/mylinux-netcheck"]="0:0:755"
)
