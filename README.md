<p align="center">
<img src="https://cloud.githubusercontent.com/assets/1342803/16012068/d98ba914-3155-11e6-8efe-733f35fe67a3.png" width="745" align="middle"/>
</p>

# Vapor Toolbox

Learn more about Vapor Toolbox in the <a href="https://vapor.github.io/documentation/getting-started/install-toolbox.html">documentation</a>.

## Homebrew

```sh
# install Vapor Toolbox
brew install vapor/tap/vapor
```

## Linux
```sh
# install Vapor Toolbox
# Ubuntu 16.04 / Ubuntu 16.10
```

Install pre dependencies

```sh
sudo apt-get install software-properties-common python-software-properties
```

Import verification key with:

```sh
wget -q https://repo.vapor.codes/apt/keyring.gpg -O- | sudo apt-key add -
```

Add this repository to /etc/apt/sources.list as:

```sh
echo "deb https://repo.vapor.codes/apt $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/vapor.list
```

Update apt-get

```sh
sudo apt-get update
```

Install Swift and Vapor

```
sudo apt-get install swift vapor
```

See here for reference
<https://repo.vapor.codes>

## Manual

You can manually install the toolbox on platforms that aren't supported by Homebrew or our APT repo.

```sh
git clone git@github.com:vapor/toolbox.git
cd toolbox
swift build -c release
mv .build/release/Executable /usr/local/bin/vapor
```
