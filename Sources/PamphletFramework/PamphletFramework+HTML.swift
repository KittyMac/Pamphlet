import Foundation
import libmcpp

var warnHtmlCompressor = true

extension PamphletFramework {
    func minifyHtml(inFile: String, fileContents: inout String) {
        if options.contains(.minifyHtml) {
            if inFile.hasSuffix(".css") || inFile.hasSuffix(".html") {
                let path = pathFor(executable: "htmlcompressor")
                
                if warnHtmlCompressor {
                    warnHtmlCompressor = false
                    print("warning: \(path) not found")
                }
                
                /*
                if FileManager.default.fileExists(atPath: path) {
                    do {
                        let task = Process()
                        task.executableURL = URL(fileURLWithPath: path)
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
                        fatalError("Failed to use \(path) to compress the requested file")
                    }
                } else {
                    if warnHtmlCompressor {
                        warnHtmlCompressor = false
                        print("warning: \(path) not found")
                    }
                }*/
            }
        }
    }
}
