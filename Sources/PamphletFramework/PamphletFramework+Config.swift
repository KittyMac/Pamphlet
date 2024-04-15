import Foundation
import libmcpp
import Hitch
import Spanker

extension PamphletFramework {
    
    private func rule(for file: String) -> JsonElement? {
        for rule in pamphletJson.iterValues {
            guard let ruleRegex = rule[string: "file"] else { continue }
            if file.test(ruleRegex) {
                return rule
            }
        }
        return nil
    }
    
    func includeOriginal(for file: String) -> Bool {
        let key: HalfHitch = "includeOriginal"
        if let rule = rule(for: file),
           rule.contains(key: key) == true,
           let value = rule[bool: key] {
            return value
        }
        return true
    }
    
    func includeGzip(for file: String) -> Bool {
        let key: HalfHitch = "includeGzip"
        if let rule = rule(for: file),
           rule.contains(key: key) == true,
           let value = rule[bool: key] {
            return value
        }
        return true
    }
    
    func minifyHtml(for file: String) -> Bool {
        let key: HalfHitch = "minifyHtml"
        if let rule = rule(for: file),
           rule.contains(key: key) == true,
           let value = rule[bool: key] {
            return value
        }
        return true
    }
    
    func minifyJs(for file: String) -> Bool {
        let key: HalfHitch = "minifyJs"
        if let rule = rule(for: file),
           rule.contains(key: key) == true,
           let value = rule[bool: key] {
            return value
        }
        return true
    }
    
    func minifyJson(for file: String) -> Bool {
        let key: HalfHitch = "minifyJson"
        if let rule = rule(for: file),
           rule.contains(key: key) == true,
           let value = rule[bool: key] {
            return value
        }
        return true
    }
    
    func compressionLevel(for file: String) -> Int? {
        if let rule = rule(for: file),
           let value = rule[int: "compressionLevel"] {
            return value
        }
        return nil
    }
        
    func preprocessorWraps(for file: String,
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
