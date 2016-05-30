
extension Array where Element: Equatable {
    mutating func remove(_ element: Element) {
        self = self.filter { $0 != element }
    }

    mutating func remove(matching: (Element) -> Bool) {
        self = self.filter { !matching($0) }
    }
}
