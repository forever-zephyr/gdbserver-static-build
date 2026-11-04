#!/usr/bin/env bash
set -euo pipefail

: "${GDB_VERSION:?set GDB_VERSION}"
: "${TARGET_ARCH:?set TARGET_ARCH}"
: "${TARGET_TRIPLE:?set TARGET_TRIPLE}"

case "$GDB_VERSION" in
  9.2) source_sha256='360cd7ae79b776988e89d8f9a01c985d0b1fa21c767a4295e5f88cb49175c555' ;;
  13.2) source_sha256='fd5bebb7be1833abdb6e023c2f498a354498281df9d05523d8915babeb893f0a' ;;
  18.1) source_sha256='cd9fc3fe2b47743840e42c1592d3d87f8302eb18639c0b8b4ba0898002e2348f' ;;
  *) echo "Unsupported GDB version: $GDB_VERSION" >&2; exit 2 ;;
esac

case "$TARGET_ARCH:$TARGET_TRIPLE" in
  i386:i686-linux-gnu) emulator='' ;;
  x86_64:x86_64-linux-gnu) emulator='' ;;
  armv7:arm-linux-gnueabihf) emulator='qemu-arm' ;;
  aarch64:aarch64-linux-gnu) emulator='qemu-aarch64' ;;
  mips:mips-linux-gnu) emulator='qemu-mips' ;;
  mipsel:mipsel-linux-gnu) emulator='qemu-mipsel' ;;
  mips64:mips64-linux-gnuabi64) emulator='qemu-mips64' ;;
  mips64el:mips64el-linux-gnuabi64) emulator='qemu-mips64el' ;;
  *) echo "Unsupported architecture/triple: $TARGET_ARCH/$TARGET_TRIPLE" >&2; exit 2 ;;
esac

source_url="https://sourceware.org/pub/gdb/releases/gdb-${GDB_VERSION}.tar.xz"
output_dir="/workspace/dist/${GDB_VERSION}/${TARGET_ARCH}"
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
  configure_script="$source_dir/gdb/gdbserver/configure"
  make_target=''
  output_binary='gdbserver'
else
  configure_script="$source_dir/configure"
  make_target='all-gdbserver'
  output_binary='gdbserver/gdbserver'
fi

mkdir "$build_dir/build"
cd "$build_dir/build"
export CC="$TARGET_TRIPLE-gcc" CXX="$TARGET_TRIPLE-g++"
export AR="$TARGET_TRIPLE-ar" RANLIB="$TARGET_TRIPLE-ranlib"
export CFLAGS='-O2 -g0' CXXFLAGS='-O2 -g0' LDFLAGS='-static'
"$configure_script" --host="$TARGET_TRIPLE" --target="$TARGET_TRIPLE" \
  --disable-werror --disable-inprocess-agent --disable-nls --disable-gdb
if [[ -n "$make_target" ]]; then
  make -j 2 "$make_target"
else
  make -j 2
fi

binary="gdbserver-${GDB_VERSION}-linux-${TARGET_ARCH}-static"
install -m 0755 "$output_binary" "$output_dir/$binary"
file "$output_dir/$binary" | grep -q 'statically linked'
if readelf -l "$output_dir/$binary" | grep -q INTERP; then
  echo 'Unexpected dynamic interpreter in gdbserver' >&2
  exit 1
fi
case "$TARGET_ARCH" in
  i386) file "$output_dir/$binary" | grep -q 'ELF 32-bit.*Intel 80386' ;;
  x86_64) file "$output_dir/$binary" | grep -q 'ELF 64-bit.*x86-64' ;;
  armv7) file "$output_dir/$binary" | grep -q 'ELF 32-bit.*ARM' ;;
  aarch64) file "$output_dir/$binary" | grep -q 'ELF 64-bit.*ARM aarch64' ;;
  mips|mipsel) file "$output_dir/$binary" | grep -q 'ELF 32-bit.*MIPS' ;;
  mips64|mips64el) file "$output_dir/$binary" | grep -q 'ELF 64-bit.*MIPS' ;;
esac

if [[ -n "$emulator" ]]; then
  "$emulator" "$output_dir/$binary" --version | head -n 1
else
  "$output_dir/$binary" --version | head -n 1
fi

{
  printf 'Product: gdbserver\nVersion: %s\n' "$GDB_VERSION"
  printf 'Architecture: %s\nTarget triple: %s\n' "$TARGET_ARCH" "$TARGET_TRIPLE"
  printf 'Source: %s\nSource SHA-256: %s\n' "$source_url" "$source_sha256"
  printf 'Compiler: %s\n' "$("$CC" --version | head -n 1)"
  printf 'Linking: static\n'
  if [[ "$GDB_VERSION" == 9.2 ]]; then
    printf 'Patch SHA-256: %s\n' "$(sha256sum /workspace/patches/gdb-9.2-gnulib-header-order.patch | cut -d' ' -f1)"
  fi
} > "$output_dir/${binary}.buildinfo.txt"

