TAG=$(git describe --tags);
git checkout $TAG;

cat ./Sources/Executable/main.swift | \
    awk -v tag="$TAG" '/let version = "master"/ { printf "let version = \"%s\"\n", tag; next } 1' > .tmp && \
    mv .tmp Sources/Executable/main.swift;

export FLUENT_NO_SQLITE=true
swift build -c release -Xswiftc -static-stdlib -Xswiftc -DNO_SQLITE
mv .build/release/Executable ./macOS-sierra

echo "Drag and drop macOS-sierra into https://github.com/vapor/toolbox/releases/edit/$TAG"

echo "We did stuff, undo it."
