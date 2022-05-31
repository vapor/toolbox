DEST := /usr/local/bin/vapor

build:
	swiftc ./scripts/build.swift
	./build
	rm ./build
install: build
# if uid does not equal 0
# user is not root and must use sudo
ifneq ($(shell id -u), 0)
	sudo mv .build/release/vapor ${DEST}
	sudo chmod 755 ${DEST}
# if uid is 0
# user is root and perhaps sudo is not available
else
	mv .build/release/vapor ${DEST}
	chmod 755 ${DEST}
endif
uninstall:
ifneq ($(shell id -u), 0)
	sudo rm ${DEST}
else
	rm ${DEST}
endif
clean:
	rm -rf .build
