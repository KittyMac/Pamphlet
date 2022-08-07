import Foundation
import libmcpp

var warnTerser = true

extension PamphletFramework {
    func minifyJs(inFile: String, fileContents: inout String) {
        if options.contains(.minifyJs) {
            guard inFile.hasSuffix(".min.js") == false else { return }
            if (inFile.hasSuffix(".js")) {
                let nodePath = pathFor(executable: "node")
                let terserPath = pathFor(executable: "terser")
                
                if warnTerser {
                    warnTerser = false
                    print("warning: \(terserPath) not found")
                }
                
                /*
                let nodePath = pathFor(executable: "node")
                let terserPath = pathFor(executable: "terser")
                
                if FileManager.default.fileExists(atPath: nodePath) &&
                    FileManager.default.fileExists(atPath: terserPath) {
                    do {
                        let task = Process()
                        task.executableURL = URL(fileURLWithPath: nodePath)
                        let inputPipe = Pipe()
                        let outputPipe = Pipe()
                        
                        task.environment = ProcessInfo.processInfo.environment
                        task.standardInput = inputPipe
                        task.standardOutput = outputPipe
                        task.arguments = [terserPath, "--compress", "--mangle", "--format", "ascii_only=true"]
                        
                        try task.run()
                        if let fileContentsAsData = fileContents.data(using: .utf8) {
                            DispatchQueue.global(qos: .userInitiated).async {
                                inputPipe.fileHandleForWriting.write(fileContentsAsData)
                                inputPipe.fileHandleForWriting.closeFile()
                            }
                            let minifiedData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                            fileContents = String(data: minifiedData, encoding: .utf8) ?? fileContents
                        } else {
                            throw ""
                        }
                    } catch {
                        fatalError("Failed to use \(terserPath) to compress the requested file")
                    }
                } else {
                    if warnTerser {
                        warnTerser = false
                        print("warning: \(terserPath) not found")
                    }
                }
                */
            }
        }
    }
}
