bootstrap:
	rm -rf .bootstrap
	mkdir .bootstrap
	git clone https://github.com/apple/swift-llbuild .bootstrap/llbuild
	git clone https://github.com/apple/swift-package-manager .bootstrap/swiftpm
	cd .bootstrap/swiftpm; ./Utilities/bootstrap --release
build:
	swift build \
	-Xswiftc -I.bootstrap/swiftpm/.build/release \
	-Xswiftc -I.bootstrap/swiftpm/.build/release/llbuild/products/llbuildSwift/ \
	-Xlinker -lSwiftPM \
	-Xlinker -L.bootstrap/swiftpm/.build/release \
	-Xlinker -L.bootstrap/swiftpm/.build/release/llbuild/lib/ \
	-Xlinker -F.bootstrap/swiftpm/.build/release/llbuild/lib/ \
	-Xswiftc -F.bootstrap/swiftpm/.build/release/llbuild/lib/
xcode:
	swift package \
	-Xswiftc -I.bootstrap/swiftpm/.build/release \
	-Xswiftc -I.bootstrap/swiftpm/.build/release/llbuild/products/llbuildSwift/ \
	-Xlinker -lSwiftPM \
	-Xlinker -L.bootstrap/swiftpm/.build/release \
	-Xlinker -L.bootstrap/swiftpm/.build/release/llbuild/lib/ \
	-Xlinker -F.bootstrap/swiftpm/.build/release/llbuild/lib/ \
	-Xswiftc -F.bootstrap/swiftpm/.build/release/llbuild/lib/ \
	generate-xcodeproj
vapor3: build
	rm -rf /usr/local/bin/vapor3
	ln -s ${PWD}/.build/debug/Executable /usr/local/bin/vapor3
