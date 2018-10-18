TAG=$1
echo "📦  Checking out tag $TAG..."
git checkout $TAG;

echo "📦  Updating Swift packages..."
swift package update

echo "📦  Building..."
swift build -c release --static-swift-stdlib

echo "📦  Creating package..."
EXEC_NAME="vapor"
if [[ $TAG == *"beta"* ]]; then
    echo "Beta package detected..."
    EXEC_NAME="vapor-beta"
fi

PACKAGE_NAME="vapor-toolbox-$TAG"
mkdir -p ./$PACKAGE_NAME

rm -rf ./.ship
SHIP_DIR="./.ship/$PACKAGE_NAME"

README="$SHIP_DIR/README.txt"

echo "Manual Install Instructions for Vapor Toolbox v$TAG" > $README
echo "" >> $README
echo "- Move *.dylib files into /usr/local/lib" >> $README
echo "- Move executable $EXEC_NAME into /usr/local/bin" >> $README
echo "- Type '$EXEC_NAME --help' into terminal to verify installation" >> $README

cp .build/release/Executable $SHIP_DIR/$EXEC_NAME
cp .build/release/*.dylib $SHIP_DIR/

tar -cvzf macOS-sierra.tar.gz $SHIP_DIR

echo "📦  Drag and drop $PWD/macOS-sierra.tar.gz into https://github.com/vapor/toolbox/releases/edit/$TAG"

open ../

while true; do
    read -p "Have you finished uploading? [y/n]" yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done


echo "📦 Generating Ruby script\n\n\n"
HASH=$(shasum -a 256 macOS-sierra.tar.gz | cut -d " " -f 1)
echo "    New checksum is:"
echo "\n    $HASH\n"

echo "Copy and paste this into https://github.com/vapor/homebrew-tap/edit/master/vapor.rb"

while true; do
    read -p "Have you opened a pull request? [y/n]" yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

git checkout master
