public func +=(lhs: inout [String], rhs: String) {
    lhs.append(rhs)
}

public func +=(lhs: inout ArraySlice<String>, rhs: String) {
    lhs.append(rhs)
}
