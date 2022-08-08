import Foundation
import libmcpp
import JXKit

var warnHtmlCompressor = true

extension PamphletFramework {
    func minifyHtml(inFile: String, fileContents: inout String) {
        if options.contains(.minifyHtml) {
            if inFile.hasSuffix(".css") || inFile.hasSuffix(".html") {
                if let results = ToolsManager.shared.toolHTML(input: fileContents) {
                    fileContents = results
                } else {
                    print("failed to minify \(inFile)")
                }
            }
        }
    }
}
