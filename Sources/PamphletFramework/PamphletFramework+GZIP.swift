import Foundation
import libmcpp

extension PamphletFramework {
    func gzip(fileContents: String) -> String? {
        if options.contains(.includeGzip) {
            let path = pathFor(executable: "gzip")
            
            do {
                let task = Process()
                task.executableURL = URL(fileURLWithPath: path)
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
                fatalError("Failed to use \(path) to compress the requested file")
            }
        }
        return nil
    }
}
