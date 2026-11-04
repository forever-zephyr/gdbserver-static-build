#!/usr/bin/env bash
set -euo pipefail

release_dir="${1:?pass the merged artifact directory}"
versions=(9.2 13.2 18.1)
arches=(i386 x86_64 armv7 aarch64 mips mipsel mips64 mips64el)

for version in "${versions[@]}"; do
  host="gdb-${version}-linux-x86_64"
  test -s "$release_dir/$host"
  test -s "$release_dir/${host}.buildinfo.txt"
  for arch in "${arches[@]}"; do
    server="gdbserver-${version}-linux-${arch}-static"
    test -s "$release_dir/$server"
    test -s "$release_dir/${server}.buildinfo.txt"
  done
done

for version in "${versions[@]}"; do
  case "$version" in
    9.2) expected='360cd7ae79b776988e89d8f9a01c985d0b1fa21c767a4295e5f88cb49175c555' ;;
    13.2) expected='fd5bebb7be1833abdb6e023c2f498a354498281df9d05523d8915babeb893f0a' ;;
    18.1) expected='cd9fc3fe2b47743840e42c1592d3d87f8302eb18639c0b8b4ba0898002e2348f' ;;
  esac
  archive="$release_dir/gdb-${version}.tar.xz"
  curl --proto '=https' --tlsv1.2 -fsSL --retry 3 \
    -o "$archive" "https://sourceware.org/pub/gdb/releases/gdb-${version}.tar.xz"
  printf '%s  %s\n' "$expected" "$archive" | sha256sum -c -
done

cat > "$release_dir/RELEASE_MANIFEST.txt" <<'EOF'
GDB versions: 9.2, 13.2, 18.1
Target GDBserver architectures: i386, x86_64, armv7, aarch64, mips, mipsel, mips64, mips64el
Host GDB architecture: x86_64 (multi-target, dynamic Debian Bookworm build)
GDBserver linking: static
Each binary has a matching .buildinfo.txt file and GitHub provenance attestation.
EOF

(
  cd "$release_dir"
  find . -maxdepth 1 -type f ! -name SHA256SUMS -printf '%f\n' \
    | sort | xargs sha256sum > SHA256SUMS
  sha256sum -c SHA256SUMS
)

