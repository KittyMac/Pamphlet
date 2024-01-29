import Foundation
import libmcpp
import Hitch
import Spanker

extension PamphletFramework {
    private func rule(for file: FilePath) -> JsonElement? {
        for rule in pamphletJson.iterValues {
            guard let ruleRegex = rule[string: "file"] else { continue }
            if file.fileName.test(ruleRegex) {
                return rule
            }
        }
        return nil
    }
    
    func gzip(for file: FilePath) -> Bool {
        if let rule = rule(for: file),
           let value = rule[bool: "gzip"] {
            return value
        }
        return true
    }
    
    func preprocessorWraps(for file: FilePath,
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
