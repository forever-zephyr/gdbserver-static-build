# Static i386 GDBserver build

## Multiarch release

The new [`release-multi.yml`](.github/workflows/release-multi.yml) workflow
builds three GDB versions (9.2, 13.2, 18.1). Each version has statically linked
GDBserver builds for i386, x86_64, ARMv7 hard float, AArch64, MIPS32 big and
little endian, and MIPS64 big and little endian. Each version also has a
multi-target x86_64 GDB with Python support for debugging all these targets
from a Debian Bookworm-compatible analysis machine. The host GDB binaries are
dynamically linked and do not run directly on Ubuntu 20.04; use that system's
older GDB/Pwndbg or a compatible container there.

The workflow checks the source SHA-256, static linkage and ELF architecture,
then runs every target GDBserver under its native CPU or QEMU user emulation.
Each binary gets a build information file and a GitHub provenance attestation.
The tag-triggered release job verifies that the entire matrix is present,
downloads the exact official source archives, and publishes a release-wide
`SHA256SUMS`. Push a `multi-v*` tag to run the complete release matrix.

For a focused test before tagging, run `build-multi.yml` manually with a
product, version, and architecture selection. Source hashes are pinned in
`scripts/build-multi.sh`, `scripts/build-host-gdb.sh`, and
`scripts/assemble-multi-release.sh`.

The following section describes the original i386-only release.

## Original i386 release

This repository builds a 32-bit statically linked GDBserver 9.2 from the
[official GDB release source](https://sourceware.org/pub/gdb/releases/gdb-9.2.tar.xz).
The source archive is pinned by SHA-256 in `scripts/build.sh`. GitHub Actions
builds inside a `linux/386` Debian Bookworm container, applies the included
header-order compatibility patch, checks the ELF architecture and
absence of a dynamic interpreter, and publishes the binary with source,
checksums, build information, and a GitHub provenance attestation.

Public CI makes the build steps visible, but it is not a guarantee that the
source, dependencies, runner, or resulting binary are harmless. The base image
and packages can change; `BUILDINFO.txt` records the builder image ID for the
individual run. Review the workflow, the one-line source patch, and use the
attestation before running the binary in a sensitive environment.

## Download and verify

Replace `OWNER` and `TAG` with the repository owner and release tag:

```bash
gh release download TAG -R OWNER/gdbserver-static-build -p 'gdbserver-9.2-linux-i386-static' -p 'SHA256SUMS' -p 'BUILDINFO.txt'
sha256sum -c SHA256SUMS --ignore-missing
gh attestation verify gdbserver-9.2-linux-i386-static -R OWNER/gdbserver-static-build
file gdbserver-9.2-linux-i386-static
```

The source archive is included in each release for independent rebuilding.

