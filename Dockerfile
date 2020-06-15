FROM swift:5.2-bionic as build
WORKDIR /build
COPY . .
RUN swift build --build-path /build/.build --enable-test-discovery -c release

FROM swift:5.2-bionic-slim
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true && \
    apt-get -q update && apt-get -q upgrade -y && apt-get install -y --no-install-recommends git \
    && rm -r /var/lib/apt/lists/*
COPY --from=build /build/.build/release/vapor /usr/bin
ENTRYPOINT ["vapor"]
