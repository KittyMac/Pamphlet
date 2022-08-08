import Foundation
import libmcpp
import JXKit


extension PamphletFramework {
    func minifyJs(jxCtx: JXContext, inFile: String, fileContents: inout String) {
        if options.contains(.minifyJs) {
            guard inFile.hasSuffix(".min.js") == false else { return }
            if (inFile.hasSuffix(".js")) {
                                
                var callbackResults = "undefined"
                let callback = JXValue(newFunctionIn: jxCtx) { context, this, arguments in
                    callbackResults = arguments[0].stringValue ?? "undefined"
                    return JXValue(undefinedIn: jxCtx)
                }

                let terserFunc = try! jxCtx.eval(script: "global.toolJS")
                                
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
