import Foundation
import libmcpp

func pathFor(executable name: String) -> String {
    if FileManager.default.fileExists(atPath: "/opt/homebrew/bin/\(name)") {
        return "/opt/homebrew/bin/\(name)"
    } else if FileManager.default.fileExists(atPath: "/usr/bin/\(name)") {
        return "/usr/bin/\(name)"
    } else if FileManager.default.fileExists(atPath: "/usr/local/bin/\(name)") {
        return "/usr/local/bin/\(name)"
    } else if FileManager.default.fileExists(atPath: "/bin/\(name)") {
        return "/bin/\(name)"
    }
    return "./\(name)"
}

class JsonDirectory: Codable {
    var files:[String:String] = [:]
}

extension String {
    private func substring(with nsrange: NSRange) -> Substring? {
        guard let range = Range(nsrange, in: self) else { return nil }
        return self[range]
    }
    
    func matches(_ pattern: String, _ callback: @escaping ((NSTextCheckingResult, [String]) -> Void)) {
        do {
            let body = self
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let nsrange = NSRange(location: Int(0), length: Int(count))
            regex.enumerateMatches(in: body, options: [], range: nsrange) { (match, _, _) in
                guard let match = match else { return }

                var groups: [String] = []
                for iii in 0..<match.numberOfRanges {
                    if let groupString = body.substring(with: match.range(at: iii)) {
                        groups.append(String(groupString))
                    }
                }
                callback(match, groups)
            }
        } catch { }
    }
}

private func toVariableName(_ source: String) -> String {
    var scratch = ""
    scratch.reserveCapacity(source.count)
    var capitalize = true
    for c in source {
        if c == "." || c == "/" || c == "-" || c == "_" {
            capitalize = true
        } else {
            if capitalize {
                scratch.append(c.uppercased())
                capitalize = false
            } else {
                scratch.append(c)
            }
        }
    }
    return scratch
}

struct FilePath {
    let fullPath: String
    let parts: [String]
    let fileName: String
    let fullVariableName: String
    let variableName: String
    let swiftFileName: String
    let extensionName: String
    let parentExtensionName: String
    let myStructName: String
    var isStaticString: Bool = false
        
    init(_ pamphletName: String,
         _ inPath: String,
         _ options: PamphletOptions) {
        var path = inPath
        if path.hasPrefix("/") == false {
            path = "/" + path
        }
        
        let pathParts = path.components(separatedBy: "/").filter { $0.count > 0 }
        
        fullPath = path
        parts = pathParts.map { toVariableName($0) }
        
        fileName = pathParts.last ?? "Pamphlet"
        
        // swift file name
        var scratch = ""
        scratch.append("\(pamphletName)+")
        for part in parts {
            if part.count > 0 {
                scratch.append(part)
                scratch.append("+")
            }
        }
        scratch.removeLast()
        scratch.append(options.fileExt())
        swiftFileName = scratch
        
        // variable name
        variableName = toVariableName(fileName)
        
        // extensionName
        scratch.removeAll(keepingCapacity: true)
        scratch.append("\(pamphletName).")
        for part in parts.dropLast() {
            scratch.append(part)
            scratch.append(".")
        }
        scratch.removeLast()
        extensionName = scratch
        
        // parentExtensionName
        scratch.removeAll(keepingCapacity: true)
        scratch.append("\(pamphletName).")
        for part in parts.dropLast().dropLast() {
            scratch.append(part)
            scratch.append(".")
        }
        scratch.removeLast()
        parentExtensionName = scratch
        
        // myStructName
        if let myStructPart = parts.dropLast().last {
            myStructName = toVariableName(myStructPart)
        } else {
            myStructName = ""
        }
        
        // fullVariableName
        scratch.removeAll(keepingCapacity: true)
        scratch.append("\(pamphletName).")
        for part in parts.dropLast() {
            scratch.append(part)
            scratch.append(".")
        }
        scratch.append(variableName)
        fullVariableName = scratch
    }
    
    private func fileNameToVariableName(_ fileName: String) -> String {
        
        return variableName
    }
}

public struct PamphletOptions: OptionSet {
    public var kotlinPackage: String?
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public func fileExt() -> String {
        if contains(.kotlin) {
            return ".kt"
        }
        return ".swift"
    }
    
    public static let clean = PamphletOptions(rawValue:  1 << 0)
    public static let swiftpm = PamphletOptions(rawValue:  1 << 1)
    public static let releaseOnly = PamphletOptions(rawValue:  1 << 2)
    public static let includeOriginal = PamphletOptions(rawValue:  1 << 3)
    public static let includeGzip = PamphletOptions(rawValue:  1 << 4)
    public static let minifyHtml = PamphletOptions(rawValue:  1 << 5)
    public static let minifyJs = PamphletOptions(rawValue:  1 << 6)
    public static let minifyJson = PamphletOptions(rawValue:  1 << 7)
    public static let collapse = PamphletOptions(rawValue:  1 << 8)
    public static let kotlin = PamphletOptions(rawValue:  1 << 9)
    public static let collapseAll = PamphletOptions(rawValue:  1 << 10)
    
    public static let `default`: PamphletOptions = [.swiftpm, .includeOriginal, .includeGzip, .minifyHtml, .minifyJs, .minifyJson]
}
