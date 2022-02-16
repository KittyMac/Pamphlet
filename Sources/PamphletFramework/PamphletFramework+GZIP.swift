import Foundation
import libmcpp

extension PamphletFramework {
    func gzip(fileContents: String) -> String? {
        if options.contains(.includeGzip) {
            do {
                let task = Process()
                task.executableURL = URL(fileURLWithPath: "/usr/bin/gzip")
                task.arguments = ["-9", "-n"]
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
                    let compressedData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                    
                    return compressedData.base64EncodedString()
                } else {
                    throw ""
                }
            } catch {
                fatalError("Failed to use /usr/bin/gzip to compress the requested file")
            }
        }
        return nil
    }
}
