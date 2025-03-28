<p align="center">
    <img 
        src="https://user-images.githubusercontent.com/1342803/87364900-cf9e6880-c542-11ea-9cdf-9621a11925e1.png" 
        height="64" 
        alt="Vapor Toolbox"
    >
    <br>
    <br>
    <a href="https://docs.vapor.codes/4.0/"><img src="https://design.vapor.codes/images/readthedocs.svg" alt="Documentation"></a>
    <a href="https://discord.gg/vapor"><img src="https://design.vapor.codes/images/discordchat.svg" alt="Team Chat"></a>
    <a href="LICENSE.txt"><img src="https://design.vapor.codes/images/mitlicense.svg" alt="MIT License"></a>
    <a href="https://github.com/vapor/toolbox/actions/workflows/test.yml"><img src="https://img.shields.io/github/actions/workflow/status/vapor/toolbox/test.yml?event=push&style=plastic&logo=github&label=tests&logoColor=%23ccc" alt="CI"></a>
    <a href="https://codecov.io/github/vapor/toolbox"><img src="https://img.shields.io/codecov/c/github/vapor/toolbox?style=plastic&logo=codecov&label=codecov"></a>
    <a href="https://swift.org"><img src="https://design.vapor.codes/images/swift60up.svg" alt="Swift 6.0"></a>
</p>

🧰 A CLI tool to easily create new Vapor projects.

### Supported Platforms

Vapor Toolbox supports macOS 13.0+ and all Linux distributions that Swift 6.0 supports.

### Installation

#### Homebrew

On macOS and Linux, the Toolbox is distributed via Homebrew. If you do not have Homebrew yet, visit [brew.sh](https://brew.sh/) for install instructions.

```sh
brew install vapor
```

Double check to ensure that the installation was successful by printing help.

```sh
vapor --help
```

You should see a list of available commands.

#### Makefile

If you want, you can build the Toolbox from source. View the Toolbox's [releases](https://github.com/vapor/toolbox/releases) on GitHub to find the latest version.

```sh
git clone https://github.com/vapor/toolbox.git
cd toolbox
git checkout <desired version>
make install
```

If you want to specify a different location, pass the `DEST` variable to the `make install` command.

```sh
make install DEST=/usr/local/bin/vapor
```

If you don't want to use `sudo`, pass the `SUDO` variable to the `make install` command.

```sh
make install SUDO=false
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

To create a new Vapor project, open a terminal and, replacing `<ProjectName>` with the name of your project, run the following command:

```sh
vapor new <ProjectName>
```

You will be asked for all the necessary information to create the project.

> [!TIP]
> If you want to skip the questions, you can pass the `-n` flag to the command to automatically answer "no" to all questions.

Once the command finishes, you will have a new folder in the current directory containing the project. If you want to create the project in a specific folder, you can pass the `--output` flag to the command with the path to the folder.

By default, a Git repository is initialized in the project folder and a commit is made with the initial project structure.
If you don't want to initialize a Git repository, you can pass the `--no-git` flag to the command.
If you just want to skip the initial commit, but still want a Git repo, pass the `--no-commit` flag.

To show help information for the Toolbox, run:

```sh
vapor --help
```

You can also see the [Getting Started](https://docs.vapor.codes/getting-started/hello-world/#new-project) guide to learn more about creating a new project with the Toolbox.

### Custom Templates

The Toolbox uses templates to create new projects.
By default, it uses the official [Vapor template](https://github.com/vapor/template).

You can also specify a custom template by passing a URL of a Git repository to the `--template` flag.
By default, the toolbox uses the `main` branch. If you want to use a different branch, you can use the `--branch` flag.

> [!TIP]
> Add the `--help` flag to the command, along with the `--template` and optionally the `--branch` and `--manifest` flags, to see all the available options for the custom template.

#### Creating a Custom Template

If you are creating a custom template and want to dynamically generate the project depending on some variable given to the Toolbox, you have to add to the template a manifest file.

By default, the Toolbox looks for a YAML file named `manifest.yml` in the root of the template; if it doesn't exist, it then looks for `manifest.json`, also in the root of the template.
You can specify a different path to a YAML or JSON file with the `--manifest` flag.

This file should contain a list of variables that will be asked for during project generation and a list of all template files and folders, which will be processed based on the variables.

```yaml
name: Custom Vapor Template
variables:
  - name: fluent
    description: Would you like to use Fluent (ORM)?
    type: nested
    variables:
      ...
  - name: leaf
    description: Would you like to use Leaf (templating)?
    type: bool
files:
  - file: Package.swift
    dynamic: true
  - folder: Sources
    files:
      ...
```

##### Variables

There are four kinds of variables you can define in the manifest file:

- **Boolean**: the user can answer "yes" or "no"
```yaml
- name: leaf
  description: Would you like to use Leaf (templating)?
  type: bool
```

- **String**: the user can answer with any string
```yaml
- name: hello
  description: What would you like to display on the `/hello` route?
  type: string
```

- **Option**: the user can choose one of the options and its associated data will be passed to the template
```yaml
- name: db
  description: Which database would you like to use?
  type: option
  options:
    - name: Postgres (Recommended)
      data:
        module: Postgres
        id: psql
        version: "2.8.0"
    - name: MySQL
      data:
        module: MySQL
        id: mysql
        version: "4.4.0"
    - name: SQLite
      data:
        module: SQLite
        id: sqlite
        version: "4.6.0"
```

- **Nested**: a variable that contains other variables; the value of the nested variable will be a dictionary with the values of the nested variables
```yaml
- name: fluent
  description: Would you like to use Fluent (ORM)?
  type: nested
  variables:
    - name: db
      ...
    - name: model
      description: How would you like to name your model?
      type: string
```

##### Files and Folders

You can specify if some file or folder should be added to the project based on the value of a variable by adding an `if` key.

```yaml
- folder: Migrations
  if: fluent
  files:
    - CreateTodo.swift
- folder: Controllers
  files:
    - file: TodoController.swift
      if: fluent
```

You can also have files and folders with dynamic names: they must be Mustache templates and will be processed based on the variables.

```yaml
- folder: AppTests
  dynamic_name: "{{name}}Tests"
  files:
    - file: AppTests.swift
    dynamic_name: "{{name}}Tests.swift"
```

The content of a file can also be a Mustache template, and if you define it as `dynamic`, it will be processed using the variables.

```yaml
- file: Package.swift
  dynamic: true
```

> [!TIP]
> You can take a look at the [`manifest.yml` file](https://github.com/vapor/template/blob/main/manifest.yml) of the official Vapor template and [an overly complicated one](Tests/VaporToolboxTests/manifest.yml) we use for testing.
It may also be helpful to look at the [manifest's structure](Sources/VaporToolbox/TemplateManifest.swift).
