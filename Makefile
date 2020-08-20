VERSION := $(shell ./scripts/current-version.sh)

build:
	# Set version
	sed -i '' 's/nil/"${VERSION}"/g' Sources/VaporToolbox/Version.swift
	# Build
	swift build \
		--disable-sandbox \
		--configuration release \
		-Xswiftc -cross-module-optimization \
		--enable-test-discovery
	# Reset version
	sed -i '' 's/"${VERSION}"/nil/g' Sources/VaporToolbox/Version.swift
install: build
	mv .build/release/vapor /usr/local/bin/vapor-make
uninstall:
	rm /usr/local/bin/vapor-make
clean:
	rm -rf .build
