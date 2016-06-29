Learn how to <a href="https://vapor.readme.io/docs/install-cli">install</a> the CLI in Vapor's documentation.

![cjexpzqxeaa0ps9](https://cloud.githubusercontent.com/assets/1342803/16012068/d98ba914-3155-11e6-8efe-733f35fe67a3.png)

## Installation instructions (to be moved to https://vapor.readme.io/docs/install-cli)

Assuming `bootstrap.swift` is being served from `cli.qutheory.io`:

Download installation script:

- `curl -L cli.qutheory.io -o install-vapor.swift`

Run it (installs to `/usr/local/bin/vapor` by default, optionally specify different target):

- `swift install-vapor.swift`

Remove install script:

- `rm install-vapor.swift`

## Extending VaporCLI

If you are using Xcode, everything should be set up in the Xcode project file. It builds and runs the tests.

There is also a script `test` which runs the unit tests on both Darwin (OSX/macOS) and Linux (via docker). It writes the test results to `test.log`, which can be committed to source control.

When added tests, please note that SPM currently requires a few extra steps for them to be picked up by the test runner on Linux:

- in the test case, add a `static var allTests: [(String, (ArrayExtTests) -> () throws -> Void)]` member listing all tests (see existing files for reference)
- in `LinuxMain.swift` add an entry `testCase(YourFileHere.swift)` to `XCTMain`
