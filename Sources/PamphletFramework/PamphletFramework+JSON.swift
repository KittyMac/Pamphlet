import Foundation
import libmcpp

extension PamphletFramework {
    func minifyJson(inFile: String, fileContents: inout String) {
        if minifyJson(for: inFile) {
            if (inFile.hasSuffix(".json")) {
                if let results = ToolsManager.shared.toolJSON(input: fileContents) {
                    fileContents = results
                } else {
                    print("failed to minify \(inFile)")
                }
            }
        }
    }
}
