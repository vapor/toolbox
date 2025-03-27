DEST ?= /usr/local/bin/vapor
SUDO ?= true

_USE_SUDO := $(shell test $(shell id -u) -ne 0 -a "$(SUDO)" = "true" && echo "sudo" || echo "")

init-git:
	@if [ ! -d .git ]; then \
		git init; \
		git commit --allow-empty -m "first commit"; \
	fi
build: init-git
	swiftc ./scripts/build.swift
	./build
	rm ./build
install: build
	$(_USE_SUDO) mv .build/release/vapor ${DEST}
	$(_USE_SUDO) chmod 755 ${DEST}
uninstall:
	$(_USE_SUDO) rm ${DEST}
clean:
	rm -rf .build
