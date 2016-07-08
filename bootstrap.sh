#!/bin/sh

TAG="0.6.0"
SWIFT_VERSION="swift-DEVELOPMENT-SNAPSHOT-2016-06-20-a"

SWIFT=`which swift`

if [[ $SWIFT == *"swiftenv"* ]];
then
	echo "Swiftenv installed, continuing..."
	swiftenv install
else
	if [[ $SWIFT == *"swift-latest.xctoolchain"* ]];
	then
		PATH=`ls -lah /Library/Developer/Toolchains/swift-latest.xctoolchain`
		if [[ $PATH == *$SWIFT_VERSION* ]];
		then
			echo "$SWIFT_VERSION installed, continuing..."
		else
			echo "Incorrect Swift version installed, please install $SWIFT_VERSION"
			exit 1
		fi
	else
		if [[ $SWIFT == *$SWIFT_VERSION* ]];
		then
			echo "$SWIFT_VERSION installed, continuing..."
		else
			echo "Neither Swift nor Swiftenv is installed"
			echo "Please review the documentation for installing the Toolbox at http://docs.qutheory.io"
			exit 1
		fi
	fi
fi

TMP="vapor-toolbox-temp.zip"
DIR="vapor-toolbox-$TAG"

rm -rf $TMP $DIR

curl -L "https://github.com/qutheory/vapor-toolbox/archive/$TAG.zip" -o $TMP
tar xf $TMP
rm -rf $TMP

cd $DIR
swift build -c release
.build/release/Executable self install

cd ..
rm -rf $DIR
