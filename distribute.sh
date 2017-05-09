TAG=$(git describe --tags);
git checkout $TAG;

cat ./Sources/Executable/main.swift | \
    awk -v tag="$TAG" '/let version = "master"/ { printf "let version = \"%s\"\n", tag; next } 1' > .tmp && \
    mv .tmp Sources/Executable/main.swift;

swift build -c release -Xswiftc -static-stdlib
rm -rf ./dist
mkdir -p ./dist
cp .build/release/Executable ./dist/macOS-sierra
cp .build/release/*.dylib ./dist/

echo "Drag and drop macOS-sierra into https://github.com/vapor/toolbox/releases/edit/$TAG"

echo "Make sure to reset git after you are done"