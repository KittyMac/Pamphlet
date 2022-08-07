import Foundation
import libmcpp

var warnJJ = true

extension PamphletFramework {
    func minifyJson(inFile: String, fileContents: inout String) {
        if options.contains(.minifyJson) {
            if (inFile.hasSuffix(".json")) {
                let path = pathFor(executable: "jj")
                
                if FileManager.default.fileExists(atPath: path) {
                    // If this is a javascript file and closure-compiler is installed
                    do {
                        let task = Process()
                        task.executableURL = URL(fileURLWithPath: path)
                        let inputPipe = Pipe()
                        let outputPipe = Pipe()
                        task.standardInput = inputPipe
                        task.standardOutput = outputPipe
                        task.standardError = nil
                        task.arguments = ["-u"]
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
                        fatalError("Failed to use \(path) to compress the requested file")
                    }
                } else {
                    if warnJJ {
                        warnJJ = false
                        print("warning: \(path) not found")
                    }
                }
            }
        }
    }
}
