This release contains GDBserver 9.2, 13.2, and 18.1 for eight target variants: i386, x86_64, ARMv7, AArch64, MIPS32 big endian, MIPS32 little endian, MIPS64 big endian, and MIPS64 little endian. The target GDBservers are statically linked.

It also contains a multi-target x86_64 GDB for each version. GDB 13.2 and 18.1 include Python support. The GDB 9.2 build omits Python because this old GDB crashes when linked with Debian Bookworm's Python 3.11. These GDB binaries are dynamically linked on Debian Bookworm and require compatible runtime libraries; they are not expected to run directly on Ubuntu 20.04.

Each asset has a SHA-256 entry, build information, and a GitHub build provenance attestation. Official source archives are included. The GDB 9.2 builds apply the small tracked header-order compatibility patch in this repository. Review the workflow and dependencies before using the binaries in a sensitive environment.

