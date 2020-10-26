DEST := /usr/local/bin/vapor

build:
	swiftc ./scripts/build.swift
	./build
	rm ./build
install: build
	sudo mv .build/release/vapor ${DEST}
	sudo chmod 755 ${DEST}
uninstall:
	sudo rm ${DEST}
clean:
	rm -rf .build
