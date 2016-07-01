
#if os(OSX)

    // FIXME: add tests
    struct Xcode: Command {
        static let id = "xcode"

        static func execute(with args: [String], in shell: PosixSubsystem) throws {
            print("Generating Xcode Project...")

            do {
                try shell.run("swift package generate-xcodeproj")
            } catch {
                throw Error.failed("Could not generate Xcode Project.")
            }

            print("Opening Xcode...")

            do {
                try shell.run("open *.xcodeproj")
            } catch {
                throw Error.failed("Could not open Xcode Project.")
            }
        }
    }
    
    extension Xcode {
        static var help: [String] {
            return [
                       "Generates and opens an Xcode Project."
            ]
        }
    }
    
#endif

