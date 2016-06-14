
#if os(OSX)

    struct Xcode: Command {
        static let id = "xcode"

        static func execute(with args: [String], in directory: String) {
            print("Generating Xcode Project...")

            do {
                try run("swift package generate-xcodeproj")
            } catch {
                fail("Could not generate Xcode Project.")
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

