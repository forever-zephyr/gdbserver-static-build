FROM debian:bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential bison flex texinfo libgmp-dev libmpfr-dev \
    libreadline-dev libncurses-dev libexpat1-dev zlib1g-dev liblzma-dev \
    python3-dev curl ca-certificates xz-utils file patch \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
CMD ["/workspace/scripts/build-host-gdb.sh"]

