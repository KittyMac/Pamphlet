import Foundation
import libmcpp

extension PamphletFramework {
    func minifyHtml(inFile: String, fileContents: inout String) {
        if options.contains(.minifyHtml) {
            if inFile.hasSuffix(".css") ||
                inFile.hasSuffix(".html") &&
                FileManager.default.fileExists(atPath: "/usr/local/bin/htmlcompressor") {
                do {
                    let task = Process()
                    task.executableURL = URL(fileURLWithPath: "/usr/local/bin/htmlcompressor")
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
                    fatalError("Failed to use /usr/local/bin/htmlcompressor to compress the requested file")
                }
            }
        }
    }
}
