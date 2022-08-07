import Foundation
import libmcpp
import JXKit

var warnJJ = true

extension PamphletFramework {
    func minifyJson(jxCtx: JXContext, inFile: String, fileContents: inout String) {
        if options.contains(.minifyJson) {
            if (inFile.hasSuffix(".json")) {
                let terserFunc = try! jxCtx.eval(script: "global.toolTerserJSON")
                                
                fileContents = try! terserFunc.call(withArguments: [
                    jxCtx.encode(fileContents)
                ]).stringValue ?? "undefined"
            }
        }
    }
}
