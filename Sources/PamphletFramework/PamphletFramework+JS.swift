import Foundation
import libmcpp

extension PamphletFramework {
    func minifyJs(inFile: String, fileContents: inout String) {
        if options.contains(.minifyJs) && minifyJs(for: inFile)  {
            guard inFile.hasSuffix(".min.js") == false else { return }
            if (inFile.hasSuffix(".js")) {
                if let results = ToolsManager.shared.toolJS(input: fileContents) {
                    fileContents = results
                } else {
                    print("failed to minify \(inFile)")
                }
            }
        }
    }
}
