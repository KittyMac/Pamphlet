import Foundation
import libmcpp
import Hitch

extension PamphletFramework {
    func platforms(for file: FilePath) -> [String] {
        
        for rule in pamphletJson.iterValues {
            guard let ruleRegex = rule[string: "file"] else { continue }
            guard let platforms = rule[element: "platforms"] else { continue }
            if file.fileName.test(ruleRegex) {
                return platforms.iterValues.compactMap { $0.stringValue }
            }
        }
        
        return []
    }
    
    func platformsOpen(for file: FilePath) -> String {
        let hitch = Hitch()
        let platforms = platforms(for: file)
        if platforms.isEmpty == false {
            hitch.append("#if ")
            hitch.append(
                platforms.map {  "os(\($0))" }.joined(separator: " || ")
            )
            hitch.append("\n")
        }
        return hitch.toString()
    }
    
    func platformsClose(for file: FilePath) -> String {
        let hitch = Hitch()
        let platforms = platforms(for: file)
        if platforms.isEmpty == false {
            hitch.append("#endif\n")
        }
        return hitch.toString()
    }
    
    func platformsWrap(for file: FilePath,
                       string: String) -> String {
        let hitch = Hitch()
        hitch.append(platformsOpen(for: file))
        hitch.append(string)
        hitch.append("\n")
        hitch.append(platformsClose(for: file))
        return hitch.toString()
    }
}
