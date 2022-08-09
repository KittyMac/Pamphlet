import Foundation
import libmcpp
import Hitch
import JXKit

private class JXRunner {
    let context = JXContext()
    let lock = NSLock()
    
    init() {
        lock.lock()
        let _ = try! context.eval(script: "let global = {};")
        let _ = try! context.eval(script: ToolsPamphlet.ToolsJs().description)
        lock.unlock()
    }
    
    func perform<T>(_ block: (JXContext) -> T) -> T {
        lock.lock(); defer { lock.unlock() }
        return block(context)
    }
}

public class ToolsManager {
    static let shared = ToolsManager()
    
    private let cores = ProcessInfo.processInfo.activeProcessorCount
    
    private var jxRoundRobin = 0
    private var jxRunners: [JXRunner] = []
    private let lock = NSLock()
    
    private init() {
        DispatchQueue.global(qos: .utility).sync {
            for _ in 0..<cores {
                jxRunners.append(JXRunner())
            }
        }
    }
    
    private func nextRunner() -> JXRunner {
        jxRoundRobin = (jxRoundRobin + 1) % cores
        return jxRunners[jxRoundRobin]
    }
    
    private func run(tool: String,
                     input: String) -> String? {
        return self.nextRunner().perform { context in
            var callbackResults: String? = nil
            let jsCallback = JXValue(newFunctionIn: context) { context, this, arguments in
                callbackResults = String(arguments[0].stringValue ?? "undefined")
                return JXValue(undefinedIn: context)
            }
            let terserFunc = try! context.eval(script: tool)
            try! terserFunc.call(withArguments: [
                context.encode(input),
                jsCallback
            ])
            return callbackResults
        }
    }
        
    func toolHTML(input: String) -> String? {
        lock.lock(); defer { lock.unlock() }
        return run(tool: "global.toolHTML", input: input)
    }
    
    func toolJS(input: String) -> String? {
        lock.lock(); defer { lock.unlock() }
        return run(tool: "global.toolJS", input: input)
    }
        
    func toolJSON(input: String) -> String? {
        lock.lock(); defer { lock.unlock() }
        return run(tool: "global.toolJSON", input: input)
    }
    
}
