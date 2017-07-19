echo "Updating Swift packages..."
swift package update

echo "Determining latest Git tag..."
TAG=$(git describe --tags);
git checkout $TAG;

echo "Updating compiled version to $TAG..."
cat ./Sources/Executable/main.swift | \
    awk -v tag="$TAG" '/let version = "master"/ { printf "let version = \"%s\"\n", tag; next } 1' > .tmp && \
    mv .tmp Sources/Executable/main.swift;

echo "Building..."
swift build -c release -Xswiftc -static-stdlib

echo "Creating package..."

EXEC_NAME="vapor"
if [[ $TAG == *"beta"* ]]; then
	echo "Beta package detected..."
	EXEC_NAME="vapor-beta"
fi

PACKAGE_NAME="vapor-toolbox-$TAG"
mkdir -p ./$PACKAGE_NAME

echo "Manual Install Instructions for Vapor Toolbox v$TAG\\n\\n- Move *.dylib files into /usr/local/lib\\n- Move executable $EXEC_NAME into /usr/local/bin\\n- Type '$EXEC_NAME --help' into terminal to verify installation" >> ./$PACKAGE_NAME/README.txt

cp .build/release/Executable ./$PACKAGE_NAME/$EXEC_NAME
cp .build/release/*.dylib ./$PACKAGE_NAME/

tar -cvzf macOS-sierra.tar.gz ./$PACKAGE_NAME

echo "Drag and drop $PWD/macOS-sierra.tar.gz into https://github.com/vapor/toolbox/releases/edit/$TAG"


while true; do
    read -p "Have you finished uploading? [y/n]" yn
    case $yn in
        [Yy]* ) make install; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

rm -rf macOS-sierra.tar.gz
rm -rf ./$PACKAGE_NAME
git reset --hard HEAD
git checkout master
