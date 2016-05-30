
#if os(OSX)

    struct Xcode: Command {
        static let id = "xcode"

        static func execute(with args: [String], in directory: String) {
            print("Generating Xcode Project...")

            do {
                try run("swift build --fetch")
                try run("rm -rf Packages/Vapor-*/Sources/Development")
                try run("rm -rf Packages/Vapor-*/Sources/Performance")
                try run("rm -rf Packages/Vapor-*/Sources/Generator")
            } catch {
                print("Failed to remove extra schemes")
            }

            do {
                try run("swift build --generate-xcodeproj")
            } catch {
                print("Could not generate Xcode Project.")
                return
            }

            print("Opening Xcode...")

            do {
                try run("open *.xcodeproj")
            } catch {
                fail("Could not open Xcode Project.")
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

