FROM swift:5.6-focal as build
WORKDIR /build
COPY . .
RUN swift build --build-path /build/.build --static-swift-stdlib -c release

FROM ubuntu:focal
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true && \
    apt-get -q update && apt-get -q upgrade -y && apt-get install -y --no-install-recommends git ca-certificates \
    && rm -r /var/lib/apt/lists/*
COPY --from=build /build/.build/release/vapor /usr/bin

RUN git config --global user.name "Vapor"
RUN git config --global user.email "new@vapor.codes"

ENTRYPOINT ["vapor"]
