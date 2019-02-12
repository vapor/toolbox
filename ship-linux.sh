VERSION="18_0_0-beta_14"

docker build --file ubuntu.Dockerfile --tag toolbox-$VERSION .
docker run --name toolbox-$VERSION $(docker images -q toolbox-$VERSION)

rm -rf .ship
PACKAGE_NAME="vapor-toolbox-linux-$VERSION"
mkdir -p .ship/$PACKAGE_NAME/bin
mkdir -p .ship/$PACKAGE_NAME/lib

docker cp toolbox-$VERSION:/toolbox/.build/debug/Executable .ship/$PACKAGE_NAME/bin/vapor
docker cp toolbox-$VERSION:/usr/lib/swift/linux .ship/$PACKAGE_NAME/lib
docker rm toolbox-$VERSION

mv .ship/$PACKAGE_NAME/lib/linux .ship/$PACKAGE_NAME/lib/swift4.2.1
rm -rf .ship/$PACKAGE_NAME/lib/swift4.2.1/x86_64

tar -C .ship -cvzf .ship/linux.tar.gz $PACKAGE_NAME
open .ship