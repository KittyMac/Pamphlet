import Foundation
import libmcpp
import JXKit

var warnHtmlCompressor = true

extension PamphletFramework {
    func minifyHtml(jxCtx: JXContext, inFile: String, fileContents: inout String) {
        if options.contains(.minifyHtml) {
            if inFile.hasSuffix(".css") || inFile.hasSuffix(".html") {
                
                var callbackResults = "undefined"
                let callback = JXValue(newFunctionIn: jxCtx) { context, this, arguments in
                    callbackResults = arguments[0].stringValue ?? "undefined"
                    return JXValue(undefinedIn: jxCtx)
                }

                let terserFunc = try! jxCtx.eval(script: "global.toolHTML")
                                
                try! terserFunc.call(withArguments: [
                    jxCtx.encode(fileContents),
                    callback
                ])
                
                guard callbackResults != "undefined" else {
                    print("failed to minify \(inFile)")
                    return
                }
                                
                fileContents = callbackResults
                
            }
        }
    }
}
