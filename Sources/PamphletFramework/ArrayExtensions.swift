import Foundation

public class BoxedArray<T>: MutableCollection {
    var lock = NSLock()
    var array: [T]

    public init() {
        array = [T]()
    }

    public var startIndex: Int {
        lock.lock(); defer { lock.unlock() }
        return array.startIndex
    }
    public var endIndex: Int {
        lock.lock(); defer { lock.unlock() }
        return array.endIndex
    }
    public func index(after idx: Int) -> Int {
        lock.lock(); defer { lock.unlock() }
        return array.index(after: idx)
    }

    public func append(_ value: T) {
        lock.lock(); defer { lock.unlock() }
        array.append(value)
    }

    public subscript (index: Int) -> T {
        get {
            lock.lock(); defer { lock.unlock() }
            return array[index]
        }
        set(newValue) {
            lock.lock(); defer { lock.unlock() }
            array[index] = newValue
        }
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
