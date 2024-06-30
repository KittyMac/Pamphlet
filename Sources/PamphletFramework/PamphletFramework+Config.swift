import Foundation
import libmcpp
import Hitch
import Spanker

extension PamphletFramework {
    
    private func rule(for file: String?) -> JsonElement? {
        // set global rule first
        for rule in pamphletJson.iterValues {
            if rule[string: "file"] == nil {
                if rule.contains(key: HalfHitch(stringLiteral: "includeOriginal")),
                   let value = rule[bool: "includeOriginal"] {
                    gIncludeOriginal = value
                }
                if rule.contains(key: HalfHitch(stringLiteral: "releaseOnly")),
                   let value = rule[bool: "releaseOnly"] {
                    gReleaseOnly = value
                }
                if rule.contains(key: HalfHitch(stringLiteral: "includeGzip")),
                   let value = rule[bool: "includeGzip"] {
                    gIncludeGzip = value
                }
                if rule.contains(key: HalfHitch(stringLiteral: "minifyHtml")),
                   let value = rule[bool: "minifyHtml"] {
                    gMinifyHtml = value
                }
                if rule.contains(key: HalfHitch(stringLiteral: "minifyJs")),
                   let value = rule[bool: "minifyJs"] {
                    gMinifyJs = value
                }
                if rule.contains(key: HalfHitch(stringLiteral: "minifyJson")),
                   let value = rule[bool: "minifyJson"] {
                    gMinifyJson = value
                }
                if rule.contains(key: HalfHitch(stringLiteral: "compressionLevel")),
                   let value = rule[int: "compressionLevel"] {
                    gCompressionLevel = value
                }
            }
        }
        
        for rule in pamphletJson.iterValues {
            if let ruleRegex = rule[string: "file"],
               file?.test(ruleRegex) == true {
                return rule
            }
        }
        return nil
    }
        
    func includeOriginal(for file: String?) -> Bool {
        let key: HalfHitch = "includeOriginal"
        if let rule = rule(for: file),
           rule.contains(key: key) == true,
           let value = rule[bool: key] {
            return value
        }
        return gIncludeOriginal ?? options.contains(.includeOriginal)
    }
    
    func releaseOnly(for file: String?) -> Bool {
        let key: HalfHitch = "releaseOnly"
        if let rule = rule(for: file),
           rule.contains(key: key) == true,
           let value = rule[bool: key] {
            return value
        }
        return gReleaseOnly ?? options.contains(.releaseOnly)
    }
    
    func includeGzip(for file: String?) -> Bool {
        let key: HalfHitch = "includeGzip"
        if let rule = rule(for: file),
           rule.contains(key: key) == true,
           let value = rule[bool: key] {
            return value
        }
        return gIncludeGzip ?? options.contains(.includeGzip)
    }
    
    func minifyHtml(for file: String?) -> Bool {
        let key: HalfHitch = "minifyHtml"
        if let rule = rule(for: file),
           rule.contains(key: key) == true,
           let value = rule[bool: key] {
            return value
        }
        return gMinifyHtml ?? options.contains(.minifyHtml)
    }
    
    func minifyJs(for file: String?) -> Bool {
        let key: HalfHitch = "minifyJs"
        if let rule = rule(for: file),
           rule.contains(key: key) == true,
           let value = rule[bool: key] {
            return value
        }
        return gMinifyJs ?? options.contains(.minifyJs)
    }
    
    func minifyJson(for file: String?) -> Bool {
        let key: HalfHitch = "minifyJson"
        if let rule = rule(for: file),
           rule.contains(key: key) == true,
           let value = rule[bool: key] {
            return value
        }
        return gMinifyJson ?? options.contains(.minifyJson)
    }
    
    func compressionLevel(for file: String?) -> Int? {
        if let rule = rule(for: file),
           let value = rule[int: "compressionLevel"] {
            return value
        }
        return gCompressionLevel ?? 9
    }
        
    func preprocessorWraps(for file: String?,
                           string: String) -> String {
        let rule = rule(for: file)
        let hitch = Hitch()
        if let rule = rule,
           let format = rule[halfHitch: "format"] {
            hitch.append(.newLine)
            hitch.append(format: format, string)
            hitch.append(.newLine)
        } else {
            hitch.append(string)
        }
        return hitch.toString()
    }
}
