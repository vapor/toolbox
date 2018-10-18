FROM swift:4.2
COPY . .
ENTRYPOINT swift test
