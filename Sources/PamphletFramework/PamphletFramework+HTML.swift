import Foundation
import libmcpp
import JXKit

var warnHtmlCompressor = true

extension PamphletFramework {
    func minifyHtml(jxCtx: JXContext, inFile: String, fileContents: inout String) {
        if options.contains(.minifyHtml) {
            if inFile.hasSuffix(".css") || inFile.hasSuffix(".html") {
                let terserFunc = try! jxCtx.eval(script: "global.toolTerserHTML")
                                
                fileContents = try! terserFunc.call(withArguments: [
                    jxCtx.encode(fileContents)
                ]).stringValue ?? "undefined"
            }
        }
    }
}
