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
        
    let jsToolJS: JibFunction
    let jsToolJSON: JibFunction
    let jsToolHTML: JibFunction
    
    var jsCallback: JibFunction? = nil
    
    var lastJsResult: String = "undefined"
    
    init() {
        _ = jib[eval: "let global = {};"]
        _ = jib[eval: HalfHitch(stringLiteral: ToolsPamphlet.ToolsJs())]
        
        jsToolJS = jib[function: "global.toolJS"]!
        jsToolJSON = jib[function: "global.toolJSON"]!
        jsToolHTML = jib[function: "global.toolHTML"]!
                
        jsCallback = jib.new(function: "toolCallback", body: { [weak self] arguments in
            guard let self = self else { return nil }
            
            self.lastJsResult = "undefined"
            
            if arguments.count > 0 {
                self.lastJsResult = arguments[0].description
            }
            return nil
        })!
    }
    
    func run(tool: Tool,
             input: String) -> String? {
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
    
    private init() { }
            
    func toolHTML(input: String) -> String? {
        return JibRunner().run(tool: .html, input: input)
    }
    
    func toolJS(input: String) -> String? {
        return JibRunner().run(tool: .js, input: input)
    }
        
    func toolJSON(input: String) -> String? {
        return JibRunner().run(tool: .json, input: input)
    }
    
}


