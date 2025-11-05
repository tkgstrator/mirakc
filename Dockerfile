FROM debian:bookworm AS build
RUN --mount=type=cache,target=/var/lib/apt/,sharing=locked \
    --mount=type=cache,target=/var/cache/apt/,sharing=locked \
    apt-get update && apt-get install -y --no-install-recommends \
    make g++ libpcsclite-dev
RUN --mount=type=bind,source=./softcas/,target=/usr/local/src/softcas/ \
    --mount=type=cache,target=/build_cache/,rw \
    cd /usr/local/src/softcas/ \
    && make OBJDIR=/build_cache/obj OUTPUTDIR=/usr/lib/x86_64-linux-gnu

FROM mirakc/mirakc:latest
RUN apt-get update \
    && apt-get -y upgrade
RUN --mount=type=cache,target=/var/lib/apt/,sharing=locked \
    --mount=type=cache,target=/var/cache/apt/,sharing=locked \
    apt-get -y update && apt-get install -y \
    build-essential \
    cmake \
    git \
    libclang-dev \
    libdvbv5-dev \
    libpcsclite1 \
    libpcsclite-dev \
    libudev-dev \
    pcscd \
    pkg-config
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | bash -s - -y
ENV PATH=/root/.cargo/bin:$PATH
RUN git clone --recursive https://github.com/kazuki0824/recisdb-rs.git \
    && cd ./recisdb-rs/ \
    && git reset --hard b6824672c469ba0ea3332d4749e92893c3ff4c2e \
    && cargo build -F dvb --release \
    && cp -a target/release/recisdb /usr/local/bin
RUN apt-get -y autoremove build-essential cmake git libpcsclite-dev pkg-config \
    && apt-get -y clean \
    && rm -rf /var/lib/apt/lists/*
COPY --from=build /usr/lib/x86_64-linux-gnu/libpcsclite.so.1 /usr/lib/x86_64-linux-gnu/libpcsclite.so.1
COPY entrypoint.sh .
ENTRYPOINT ["/entrypoint.sh"]
