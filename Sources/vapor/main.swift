#!/usr/bin/env swift

import Foundation
import VaporCLI


enum ReturnCodes: Int32 {
    case ok = 0
    case cancelled
    case failed
    case unexpected
}


do {
    try VaporCLI.execute(with: Process.arguments)
    exit(ReturnCodes.ok.rawValue)
} catch Error.cancelled(let msg) {
    print("Error: \(msg)")
    exit(ReturnCodes.cancelled.rawValue)
} catch Error.failed(let msg) {
    print("Error: \(msg)")
    print("Note: Make sure you are using Swift 3.0 Snapshot 06-06")
    exit(ReturnCodes.failed.rawValue)
} catch {
    print("unexpected error")
    exit(ReturnCodes.unexpected.rawValue)
}
