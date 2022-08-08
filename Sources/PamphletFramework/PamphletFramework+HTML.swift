import Foundation
import libmcpp
import JXKit

var warnHtmlCompressor = true

extension PamphletFramework {
    func minifyHtml(jxCtx: JXContext, inFile: String, fileContents: inout String) {
        if options.contains(.minifyHtml) {
            if inFile.hasSuffix(".css") || inFile.hasSuffix(".html") {
                
                var callbackResults = fileContents
                let callback = JXValue(newFunctionIn: jxCtx) { context, this, arguments in
                    print(inFile)
                    callbackResults = arguments[0].stringValue ?? "undefined"
                    return JXValue(undefinedIn: jxCtx)
                }

                let terserFunc = try! jxCtx.eval(script: "global.toolHTML")
                                
                try! terserFunc.call(withArguments: [
                    jxCtx.encode(fileContents),
                    callback
                ])
                                
                fileContents = callbackResults
                
            }
        }
    }
}
