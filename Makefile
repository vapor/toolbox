build:
	swift build \
	-Xswiftc -I/Users/tanner/dev/tanner0101/swiftpm/.build/release \
	-Xswiftc -I/Users/tanner/dev/tanner0101/swiftpm/.build/release/llbuild/products/llbuildSwift/ \
	-Xlinker -lSwiftPM \
	-Xlinker -L/Users/tanner/dev/tanner0101/swiftpm/.build/release \
	-Xlinker -L/Users/tanner/dev/tanner0101/swiftpm/.build/release/llbuild/lib/ \
	-Xlinker -F/Users/tanner/dev/tanner0101/swiftpm/.build/release/llbuild/lib/ \
	-Xswiftc -F/Users/tanner/dev/tanner0101/swiftpm/.build/release/llbuild/lib/
xcode:
	swift package \
	-Xswiftc -I/Users/tanner/dev/tanner0101/swiftpm/.build/release \
	-Xswiftc -I/Users/tanner/dev/tanner0101/swiftpm/.build/release/llbuild/products/llbuildSwift/ \
	-Xlinker -lSwiftPM \
	-Xlinker -L/Users/tanner/dev/tanner0101/swiftpm/.build/release \
	-Xlinker -L/Users/tanner/dev/tanner0101/swiftpm/.build/release/llbuild/lib/ \
	-Xlinker -F/Users/tanner/dev/tanner0101/swiftpm/.build/release/llbuild/lib/ \
	-Xswiftc -F/Users/tanner/dev/tanner0101/swiftpm/.build/release/llbuild/lib/ \
	generate-xcodeproj
