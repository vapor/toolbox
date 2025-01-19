import ArgumentParser

enum Database: String, CaseIterable, ExpressibleByArgument {
    case postgres
    case mysql
    case sqlite
    case mongo

    static var allValueStrings: [String] {
        allCases.map { $0 == .postgres ? "\($0.rawValue) (Recommended)" : $0.rawValue }
    }
}
