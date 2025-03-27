DEST ?= /usr/local/bin/vapor
SUDO ?= true

USE_SUDO := $(shell test $(shell id -u) -ne 0 -a "$(SUDO)" = "true" && echo "sudo" || echo "")

build:
	swiftc ./scripts/build.swift
	./build
	rm ./build
install: build
	$(USE_SUDO) mv .build/release/vapor ${DEST}
	$(USE_SUDO) chmod 755 ${DEST}
uninstall:
	$(USE_SUDO) rm ${DEST}
clean:
	rm -rf .build
