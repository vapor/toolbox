FROM swift:5.1
WORKDIR /toolbox
COPY . .
RUN swift build
RUN mv /toolbox/.build/debug/vapor /usr/bin
ENTRYPOINT ["vapor"]
