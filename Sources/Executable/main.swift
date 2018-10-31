import Foundation
import VaporToolbox
import Vapor

//try fooBar()

do {
    let app = try boot().wait()
    try app.run()
} catch {
    print("Error:")
    print("\(error)")
}
