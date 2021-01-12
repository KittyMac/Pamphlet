import Foundation
import Ipecac
import libmcpp

extension PamphletFramework {
    func minifyJs(inFile: String, fileContents: inout String) {
        if options.contains(.minifyJs) {
            if (inFile.hasSuffix(".js") || inFile.hasSuffix(".ts")) &&
                FileManager.default.fileExists(atPath: "/usr/local/bin/closure-compiler") {
                // If this is a javascript file and closure-compiler is installed
                do {
                    let task = Process()
                    task.executableURL = URL(fileURLWithPath: "/usr/local/bin/closure-compiler")
                    let inputPipe = Pipe()
                    let outputPipe = Pipe()
                    task.standardInput = inputPipe
                    task.standardOutput = outputPipe
                    task.standardError = nil
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
                    fatalError("Failed to use /usr/local/bin/closure-compiler to compress the requested file")
                }
            }
        }
    }
}
