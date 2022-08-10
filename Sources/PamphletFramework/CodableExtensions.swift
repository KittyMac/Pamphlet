import Foundation

struct RuntimeError: Error {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    public var localizedDescription: String {
        return message
    }
}

private let suppressDefaultValuesKey = CodingUserInfoKey(rawValue: "SuppressDefaultValues")!

internal extension Encodable {

    func cloned<T: Decodable>() throws -> T {
        return try self.encoded().decoded()
    }

    func encoded(_ suppressDefaultValues: Bool = true) throws -> Data {
        let encoder = JSONEncoder()
        encoder.userInfo[suppressDefaultValuesKey] = suppressDefaultValues
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(self)
    }

    func json(_ suppressDefaultValues: Bool = true) throws -> String {
        let encoder = JSONEncoder()
        encoder.userInfo[suppressDefaultValuesKey] = suppressDefaultValues
        encoder.dateEncodingStrategy = .iso8601
        return try String(data: encoder.encode(self), encoding: .utf8)!
    }
}

internal extension Data {
    func decoded<T: Decodable>() throws -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: self)
    }
}

internal extension String {
    func decoded<T: Decodable>() throws -> T {
        guard let jsonData = self.data(using: .utf8) else {
            throw RuntimeError("Unable to convert json String to Data")
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: jsonData)
    }
}
