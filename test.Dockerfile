FROM swift:4.1
COPY Sources/ Sources/
COPY Tests/ Tests/
COPY Package.swift Package.swift
RUN swift test
