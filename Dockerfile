FROM swift:5.2 as build
WORKDIR /toolbox
COPY . .
RUN mkdir -p /build/lib && cp -R /usr/lib/swift/linux/*.so* /build/lib
RUN swift build -c release && mv `swift build -c release --show-bin-path` /build/bin

FROM swift:5.2-slim
WORKDIR /toolbox
COPY --from=build /build/bin/vapor /usr/bin
COPY --from=build /build/lib/* /usr/lib/
ENTRYPOINT ["vapor"]
