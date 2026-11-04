# Static i386 GDBserver build

This repository builds a 32-bit statically linked GDBserver 9.2 from the
[official GDB release source](https://sourceware.org/pub/gdb/releases/gdb-9.2.tar.xz).
The source archive is pinned by SHA-256 in `scripts/build.sh`. GitHub Actions
builds inside a `linux/386` Debian Bullseye container, checks the ELF architecture and
absence of a dynamic interpreter, and publishes the binary with source,
checksums, build information, and a GitHub provenance attestation.

Public CI makes the build steps visible, but it is not a guarantee that the
source, dependencies, runner, or resulting binary are harmless. Bullseye's
security package index currently references removed files, so this build uses
its main package repository. The base image and packages can change;
`BUILDINFO.txt` records the builder image ID for the individual run. Review the workflow and use the
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

