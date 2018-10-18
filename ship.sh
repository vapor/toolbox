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

SHIP_DIR="./.ship"
rm -rf $SHIP_DIR
PACKAGE_DIR="$SHIP_DIR/$PACKAGE_NAME"
mkdir -p $PACKAGE_DIR

README="$PACKAGE_DIR/README.txt"

echo "Manual Install Instructions for Vapor Toolbox v$TAG" > $README
echo "" >> $README
echo "- Move *.dylib files into /usr/local/lib" >> $README
echo "- Move executable $EXEC_NAME into /usr/local/bin" >> $README
echo "- Type '$EXEC_NAME --help' into terminal to verify installation" >> $README

cp .build/release/Executable $PACKAGE_DIR/$EXEC_NAME
cp .build/release/*.dylib $PACKAGE_DIR/

tar -cvzf $SHIP_DIR/macOS-sierra.tar.gz $PACKAGE_DIR

echo "➡️  Drag and drop $SHIP_DIR/macOS-sierra.tar.gz into https://github.com/vapor/toolbox/releases/edit/$TAG"

open https://github.com/vapor/toolbox/releases/edit/$TAG
open $SHIP_DIR

while true; do
    read -p "Have you finished uploading? [y/n] " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done


echo "📦 Generating Ruby script\n\n\n"
HASH=$(shasum -a 256 macOS-sierra.tar.gz | cut -d " " -f 1)
echo "    New checksum is:"
echo ""
echo "    $HASH"
echo ""
echo "➡️  Copy and paste this into https://github.com/vapor/homebrew-tap/edit/master/vapor.rb"

open https://github.com/vapor/homebrew-tap/edit/master/$EXEC_NAME.rb

while true; do
    read -p "Have you opened a pull request? [y/n] " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

git checkout master
