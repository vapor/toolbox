FROM swift:4.2.1 as builder
WORKDIR /toolbox
COPY ./Sources ./Sources
COPY ./Tests ./Tests
COPY ./Package.swift ./Package.swift
RUN swift build -Xlinker -rpath -Xlinker /usr/lib/swift4.2.1
ENTRYPOINT .build/debug/Executable -h

# FROM ubuntu:16.04
# RUN apt-get -qq update
# RUN apt-get install -y libssl-dev libbsd0 libatomic1 libicu55 libcurl3 libxml2 tzdata
# COPY --from=builder /toolbox/.build/debug/Executable /usr/bin/vapor
# RUN mkdir /usr/lib/swift4.2.1/
# COPY --from=builder /usr/lib/swift/linux/*.so /usr/lib/swift4.2.1/
# RUN ldd /usr/bin/vapor
# ENTRYPOINT vapor -h
