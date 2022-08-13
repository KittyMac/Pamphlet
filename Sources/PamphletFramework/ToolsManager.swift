import Foundation
import libmcpp
import Hitch
import Jib

private enum Tool {
    case json
    case js
    case html
}

private class JibRunner {
    let jib = Jib()
    let lock = NSLock()
        
    let jsToolJS: JibFunction
    let jsToolJSON: JibFunction
    let jsToolHTML: JibFunction
    
    var jsCallback: JibFunction? = nil
    
    var lastJsResult: String = "undefined"
    
    init() {
        lock.lock()
        
        _ = jib[eval: "let global = {};"]
        _ = jib[eval: HalfHitch(stringLiteral: ToolsPamphlet.ToolsJs())]
        
        jsToolJS = jib[function: "global.toolJS"]!
        jsToolJSON = jib[function: "global.toolJSON"]!
        jsToolHTML = jib[function: "global.toolHTML"]!
        
        jsCallback = jib.new(function: "toolCallback", body: { arguments in
            self.lastJsResult = "undefined"
            
            if arguments.count > 0 {
                self.lastJsResult = arguments[0].description
            }
            return nil
        })!
        
        lock.unlock()
    }
    
    func run(tool: Tool,
             input: String) -> String? {
        lock.lock(); defer { lock.unlock() }
        
        var jsFunction = jsToolJS
        if tool == .html {
            jsFunction = jsToolHTML
        } else if tool == .json {
            jsFunction = jsToolJSON
        }
        
        jib.call(jsFunction, [input, jsCallback])
        
        return lastJsResult
    }
}

public class ToolsManager {
    static let shared = ToolsManager()
    
    private var jibRoundRobin = 0
    private var jibRunners: [JibRunner] = []
    private let lock = NSLock()
    
    private init() {
        DispatchQueue.global(qos: .utility).sync {
            for _ in 0..<ProcessInfo.processInfo.activeProcessorCount {
                jibRunners.append(JibRunner())
            }
        }
    }
    
    private func nextRunner() -> JibRunner {
        jibRoundRobin = (jibRoundRobin + 1) % jibRunners.count
        return jibRunners[jibRoundRobin]
    }
            
    func toolHTML(input: String) -> String? {
        lock.lock(); defer { lock.unlock() }
        return nextRunner().run(tool: .html, input: input)
    }
    
    func toolJS(input: String) -> String? {
        lock.lock(); defer { lock.unlock() }
        return nextRunner().run(tool: .js, input: input)
    }
        
    func toolJSON(input: String) -> String? {
        lock.lock(); defer { lock.unlock() }
        return nextRunner().run(tool: .json, input: input)
    }
    
}
