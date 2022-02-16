import Foundation
import libmcpp

extension PamphletFramework {
    func minifyJs(inFile: String, fileContents: inout String) {
        if options.contains(.minifyJs) {
            guard inFile.hasSuffix(".min.js") == false else { return }
            if (inFile.hasSuffix(".js")) &&
                FileManager.default.fileExists(atPath: "/usr/local/bin/node") &&
                FileManager.default.fileExists(atPath: "/usr/local/bin/terser") {
                do {
                    let task = Process()
                    task.executableURL = URL(fileURLWithPath: "/usr/local/bin/node")
                    let inputPipe = Pipe()
                    let outputPipe = Pipe()
                    
                    task.environment = ProcessInfo.processInfo.environment
                    task.standardInput = inputPipe
                    task.standardOutput = outputPipe
                    task.arguments = ["/usr/local/bin/terser", "--compress", "--mangle", "--format", "ascii_only=true"]
                    
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
                    fatalError("Failed to use /usr/local/bin/terser to compress the requested file")
                }
            }
        }
    }
}
