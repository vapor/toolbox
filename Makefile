DEST := /usr/local/bin/vapor

build:
	swiftc ./scripts/build.swift
	./build
	rm ./build
install: build
	mv .build/release/vapor ${DEST}
uninstall:
	rm ${DEST}
clean:
	rm -rf .build
