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
        if let rule = rule(for: file),
           let value = rule[bool: "includeOriginal"] {
            return value
        }
        return true
    }
    
    func includeGzip(for file: String) -> Bool {
        if let rule = rule(for: file),
           let value = rule[bool: "includeGzip"] {
            return value
        }
        return true
    }
    
    func minifyHtml(for file: String) -> Bool {
        if let rule = rule(for: file),
           let value = rule[bool: "minifyHtml"] {
            return value
        }
        return true
    }
    
    func minifyJs(for file: String) -> Bool {
        if let rule = rule(for: file),
           let value = rule[bool: "minifyJs"] {
            return value
        }
        return true
    }
    
    func minifyJson(for file: String) -> Bool {
        if let rule = rule(for: file),
           let value = rule[bool: "minifyJson"] {
            return value
        }
        return true
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
