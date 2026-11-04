FROM --platform=$TARGETPLATFORM debian:bullseye

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential bison flex texinfo libgmp-dev libmpfr-dev \
    libexpat1-dev zlib1g-dev curl ca-certificates xz-utils \
    file binutils \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
CMD ["/workspace/scripts/build.sh"]

