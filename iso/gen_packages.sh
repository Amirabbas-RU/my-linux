#!/usr/bin/env bash
# Generate the live ISO package list from packages/live.txt.
#
# mkarchiso reads iso/packages.x86_64 and installs exactly those packages into
# the live environment. We keep the source of truth in packages/live.txt and
# derive packages.x86_64 from it so there is a single place to edit.

set -Eeuo pipefail

HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd -- "$HERE/.." && pwd)"

SRC="$ROOT/packages/live.txt"
DST="$HERE/packages.x86_64"

[ -r "$SRC" ] || { echo "missing $SRC" >&2; exit 1; }

{
    echo "# GENERATED FILE — do not edit."
    echo "# Produced by iso/gen_packages.sh from packages/live.txt."
    echo "# Regenerate with: ./iso/gen_packages.sh"
    echo
    grep -vE '^\s*(#|$)' "$SRC"
} > "$DST"

echo "wrote $DST ($(grep -cvE '^\s*(#|$)' "$DST") packages)"
