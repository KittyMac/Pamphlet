import Foundation
import libmcpp

var warnJJ = true

extension PamphletFramework {
    func minifyJson(inFile: String, fileContents: inout String) {
        if options.contains(.minifyJson) {
            if (inFile.hasSuffix(".json")) {
                if FileManager.default.fileExists(atPath: "\(userBinPath)/jj") {
                    // If this is a javascript file and closure-compiler is installed
                    do {
                        let task = Process()
                        task.executableURL = URL(fileURLWithPath: "\(userBinPath)/jj")
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
                        fatalError("Failed to use \(userBinPath)/jj to compress the requested file")
                    }
                } else {
                    if warnJJ {
                        warnJJ = false
                        print("warning: \(userBinPath)/jj not found")
                    }
                }
            }
        }
    }
}
