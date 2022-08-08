import Foundation
import libmcpp
import JXKit

var warnJJ = true

extension PamphletFramework {
    func minifyJson(inFile: String, fileContents: inout String) {
        if options.contains(.minifyJson) {
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
