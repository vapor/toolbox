<p align="center">
    <img 
        src="https://user-images.githubusercontent.com/1342803/87364900-cf9e6880-c542-11ea-9cdf-9621a11925e1.png" 
        height="64" 
        alt="Vapor Toolbox"
    >
    <br>
    <br>
    <a href="https://docs.vapor.codes/4.0/">
        <img src="https://design.vapor.codes/images/readthedocs.svg" alt="Documentation">
    </a>
    <a href="https://discord.gg/vapor">
        <img src="https://design.vapor.codes/images/discordchat.svg" alt="Team Chat">
    </a>
    <a href="LICENSE.txt">
        <img src="https://design.vapor.codes/images/mitlicense.svg" alt="MIT License">
    </a>
    <a href="https://github.com/vapor/toolbox/actions/workflows/test.yml">
        <img src="https://img.shields.io/github/actions/workflow/status/vapor/toolbox/test.yml?event=push&style=plastic&logo=github&label=tests&logoColor=%23ccc" alt="CI">
    </a>
    <a href="https://codecov.io/github/vapor/toolbox">
        <img src="https://img.shields.io/codecov/c/github/vapor/toolbox?style=plastic&logo=codecov&label=codecov">
    </a>
    <a href="https://swift.org">
        <img src="https://design.vapor.codes/images/swift60up.svg" alt="Swift 6.0">
    </a>
</p>

🧰 A CLI tool to easily create new Vapor projects.

### Supported Platforms

Vapor Toolbox supports macOS 13.0+ and all Linux distributions that Swift 6.0 supports.

### Installation

#### macOS

On macOS, Toolbox is distributed via Homebrew. If you do not have Homebrew yet, visit [brew.sh](https://brew.sh/) for install instructions.

```sh
brew install vapor
```

Double check to ensure that the installation was successful by printing help.

```sh
vapor --help
```

You should see a list of available commands.

#### Linux

On Linux, you will need to build the Toolbox from source. View the Toolbox's [releases](https://github.com/vapor/toolbox/releases) on GitHub to find the latest version.

```sh
git clone https://github.com/vapor/toolbox.git
cd toolbox
git checkout <desired version>
make install
```

Double check the installation was successful by printing help.

```sh
vapor --help
```

You should see a list of available commands.

## Overview

The Vapor Toolbox is a command line tool that helps you create new Vapor projects.
It is the easiest way to get started with Vapor.

The Toolbox only has one subcommand: `new`.
It's marked as the default one, so you can omit it when running the Toolbox.
For example:

```sh
vapor new Hello -n
```

is the same as

```sh
vapor Hello -n
```

### Getting Started

To create a new Vapor project, see the [Getting Started](https://docs.vapor.codes/getting-started/hello-world/#new-project) guide.

To show help information for the Toolbox, run:

```sh
vapor --help
```

### Custom Templates & Manifests

The Toolbox uses templates to create new projects.
By default, it uses the official [Vapor template](https://github.com/vapor/template).

You can also specify a custom template by passing a URL of a Git repository to the `--template` flag.
If the template is not in the `main` branch, you can specify the branch with the `--branch` flag.

If you want to dynamically generate the project depending on some variable given to the Toolbox, you have to add to the template a `manifest.yml` file.
This file should contain a list of variables that will be asked for during project generation and a list of all template files and folders, which will be processed based on the variables.

You can define boolean, string and multiple-choice (option) variables, as well as nested variables.

You can specify if some file or folder should be added to the project based on the value of a variable.
You can also have files and folders with dynamic names: they must be Mustache templates and will be processed based on the variables.
The content of a file can also be a Mustache template, and if you define it as `dynamic`, it will be processed using the variables.

You can take a look at the [`manifest.yml` file](https://github.com/vapor/template/blob/main/manifest.yml) of the official Vapor template and [an overly complicated one](Tests/VaporToolboxTests/manifest.yml) we use for testing.
It may also be helpful to look at the [manifest's structure](Sources/VaporToolbox/TemplateManifest.swift).
