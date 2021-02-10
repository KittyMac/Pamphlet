import Foundation

public class BoxedArray<T>: MutableCollection {
    var array: [T]

    public init() {
        array = [T]()
    }

    public var startIndex: Int {
        return array.startIndex
    }
    public var endIndex: Int {
        return array.endIndex
    }
    public func index(after idx: Int) -> Int {
        array.index(after: idx)
    }

    public func append(_ value: T) {
        array.append(value)
    }

    public subscript (index: Int) -> T {
        get { return array[index] }
        set(newValue) { array[index] = newValue }
    }
}

public extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

public extension Array where Element: Equatable {
    mutating func removeOne (_ element: Element) {
        if let idx = firstIndex(of: element) {
            remove(at: idx)
        }
    }

    mutating func removeAll (_ element: Element) {
        removeAll { $0 == element }
    }
}

public extension BoxedArray where Element: Equatable {
    func removeOne (_ element: Element) {
        if let idx = firstIndex(of: element) {
            array.remove(at: idx)
        }
    }

    func removeAll (_ element: Element) {
        array.removeAll { $0 == element }
    }
}
