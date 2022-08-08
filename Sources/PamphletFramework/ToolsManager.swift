import Foundation
import libmcpp
import Hitch
import JXKit

public class ToolsManager {
    static let shared = ToolsManager()
    
    private let jxCtx = JXContext()
    private let lock = NSLock()
    
    private init() {
        let _ = try! jxCtx.eval(script: "let global = {};")
        let _ = try! jxCtx.eval(script: ToolsPamphlet.ToolsJs().description)
    }
    
    func toolHTML(input: String) -> String? {
        lock.lock(); defer { lock.unlock() }
        
        var callbackResults: String? = nil
        let callback = JXValue(newFunctionIn: jxCtx) { context, this, arguments in
            callbackResults = arguments[0].stringValue ?? "undefined"
            return JXValue(undefinedIn: self.jxCtx)
        }
        let terserFunc = try! jxCtx.eval(script: "global.toolHTML")
        try! terserFunc.call(withArguments: [
            jxCtx.encode(input),
            callback
        ])
        return callbackResults
    }
    
    func toolJS(input: String) -> String? {
        lock.lock(); defer { lock.unlock() }
        
        var callbackResults: String? = nil
        let callback = JXValue(newFunctionIn: jxCtx) { context, this, arguments in
            callbackResults = arguments[0].stringValue ?? "undefined"
            return JXValue(undefinedIn: self.jxCtx)
        }
        let terserFunc = try! jxCtx.eval(script: "global.toolJS")
        try! terserFunc.call(withArguments: [
            jxCtx.encode(input),
            callback
        ])
        return callbackResults
    }
    
    func toolJSON(input: String) -> String? {
        lock.lock(); defer { lock.unlock() }
        
        var callbackResults: String? = nil
        let callback = JXValue(newFunctionIn: jxCtx) { context, this, arguments in
            callbackResults = arguments[0].stringValue ?? "undefined"
            return JXValue(undefinedIn: self.jxCtx)
        }
        let terserFunc = try! jxCtx.eval(script: "global.toolJSON")
        try! terserFunc.call(withArguments: [
            jxCtx.encode(input),
            callback
        ])
        return callbackResults
    }

}
