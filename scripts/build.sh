#!/usr/bin/env bash
set -euo pipefail

source_url='https://sourceware.org/pub/gdb/releases/gdb-9.2.tar.xz'
source_sha256='360cd7ae79b776988e89d8f9a01c985d0b1fa21c767a4295e5f88cb49175c555'
output_dir='/workspace/dist'
build_dir="$(mktemp -d)"
trap 'rm -rf "$build_dir"' EXIT

mkdir -p "$output_dir"
curl --proto '=https' --tlsv1.2 -fsSL --retry 3 \
  -o "$build_dir/gdb-9.2.tar.xz" "$source_url"
printf '%s  %s\n' "$source_sha256" "$build_dir/gdb-9.2.tar.xz" | sha256sum -c -
tar -xf "$build_dir/gdb-9.2.tar.xz" -C "$build_dir"
patch -d "$build_dir/gdb-9.2" -p1 \
  < /workspace/patches/gdb-9.2-gnulib-header-order.patch
mkdir "$build_dir/build"
cd "$build_dir/build"

CC=gcc CXX=g++ CFLAGS='-O2 -g0' CXXFLAGS='-O2 -g0' LDFLAGS='-static' \
  "$build_dir/gdb-9.2/gdb/gdbserver/configure" --disable-werror
make -j "$(nproc)"

binary="$output_dir/gdbserver-9.2-linux-i386-static"
install -m 0755 gdbserver "$binary"
file "$binary" | grep -E 'ELF 32-bit.*Intel 80386.*statically linked'
if readelf -l "$binary" | grep -q INTERP; then
  echo 'Unexpected dynamic interpreter in gdbserver' >&2
  exit 1
fi
"$binary" --version | head -n 1

install -m 0644 "$build_dir/gdb-9.2.tar.xz" "$output_dir/gdb-9.2.tar.xz"
(
  cd "$output_dir"
  sha256sum gdbserver-9.2-linux-i386-static gdb-9.2.tar.xz > SHA256SUMS
)
{
  printf 'Source: %s\n' "$source_url"
  printf 'Source SHA-256: %s\n' "$source_sha256"
  printf 'Compiler: %s\n' "$(gcc --version | head -n 1)"
  printf 'Architecture: %s\n' "$(gcc -dumpmachine)"
  printf 'Linking: static\n'
} > "$output_dir/BUILDINFO.txt"

