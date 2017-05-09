TAG=$(git describe --tags);
git checkout $TAG;

cat ./Sources/Executable/main.swift | \
    awk -v tag="$TAG" '/let version = "master"/ { printf "let version = \"%s\"\n", tag; next } 1' > .tmp && \
    mv .tmp Sources/Executable/main.swift;

swift build -c release -Xswiftc -static-stdlib
mkdir -p ./dist
cp .build/release/Executable ./dist/macOS-sierra
cp .build/release/*.dylib ./dist/

echo "Drag and drop $PWD/dist/* into https://github.com/vapor-cloud/toolbox/releases/edit/$TAG"

while true; do
    read -p "Have you finished uploading? [y/n]" yn
    case $yn in
        [Yy]* ) make install; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

rm -rf ./dist
git reset --hard HEAD
git checkout master
