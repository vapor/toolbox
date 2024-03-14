import Foundation

enum ResourceError: Error {
  case notValidProject

  var localizedDescription: String {
    switch self {
    case .notValidProject:
      return "No Package.swift found. Are you in a Vapor project?"
    }
  }
}
