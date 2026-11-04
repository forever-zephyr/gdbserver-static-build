#!/usr/bin/env bash
set -euo pipefail

: "${GDB_VERSION:?set GDB_VERSION}"
case "$GDB_VERSION" in
  9.2) source_sha256='360cd7ae79b776988e89d8f9a01c985d0b1fa21c767a4295e5f88cb49175c555' ;;
  13.2) source_sha256='fd5bebb7be1833abdb6e023c2f498a354498281df9d05523d8915babeb893f0a' ;;
  18.1) source_sha256='cd9fc3fe2b47743840e42c1592d3d87f8302eb18639c0b8b4ba0898002e2348f' ;;
  *) echo "Unsupported GDB version: $GDB_VERSION" >&2; exit 2 ;;
esac

source_url="https://sourceware.org/pub/gdb/releases/gdb-${GDB_VERSION}.tar.xz"
output_dir="/workspace/dist/${GDB_VERSION}/host"
build_dir="$(mktemp -d)"
trap 'rm -rf "$build_dir"' EXIT
mkdir -p "$output_dir"

curl --proto '=https' --tlsv1.2 -fsSL --retry 3 \
  -o "$build_dir/source.tar.xz" "$source_url"
printf '%s  %s\n' "$source_sha256" "$build_dir/source.tar.xz" | sha256sum -c -
tar -xf "$build_dir/source.tar.xz" -C "$build_dir"
source_dir="$build_dir/gdb-$GDB_VERSION"
if [[ "$GDB_VERSION" == 9.2 ]]; then
  patch -d "$source_dir" -p1 \
    < /workspace/patches/gdb-9.2-gnulib-header-order.patch
fi

mkdir "$build_dir/build"
cd "$build_dir/build"
"$source_dir/configure" \
  --enable-targets=all --disable-binutils --disable-ld --disable-gold \
  --disable-gas --disable-sim --disable-gprof --disable-gdbserver \
  --disable-werror --disable-nls --with-system-readline \
  --with-python=/usr/bin/python3 --without-guile --without-babeltrace
make -j 2 all-gdb

binary="gdb-${GDB_VERSION}-linux-x86_64"
install -m 0755 gdb/gdb "$output_dir/$binary"
file "$output_dir/$binary" | grep -q 'ELF 64-bit.*x86-64'
"$output_dir/$binary" -nx -batch \
  -ex 'show version' \
  -ex 'python import sys; print("Embedded Python:", sys.version)' \
  | head -n 8

{
  printf 'Product: gdb\nVersion: %s\n' "$GDB_VERSION"
  printf 'Architecture: x86_64\nTargets: all\n'
  printf 'Source: %s\nSource SHA-256: %s\n' "$source_url" "$source_sha256"
  printf 'Compiler: %s\n' "$(gcc --version | head -n 1)"
  printf 'Linking: dynamic (Debian Bookworm glibc)\n'
  ldd "$output_dir/$binary"
  if [[ "$GDB_VERSION" == 9.2 ]]; then
    printf 'Patch SHA-256: %s\n' "$(sha256sum /workspace/patches/gdb-9.2-gnulib-header-order.patch | cut -d' ' -f1)"
  fi
} > "$output_dir/${binary}.buildinfo.txt"

