import Foundation
import Ipecac
import libmcpp

extension PamphletFramework {
    func minifyTs(inFile: String, fileContents: inout String) {
        if options.contains(.minifyTs) {
            if inFile.hasSuffix(".ts") &&
                FileManager.default.fileExists(atPath: "/usr/local/bin/tsc") {
                do {
                    // as insane as it is to contemplate, typescript (tsc) has NO CAPABILITY to
                    // just write output to stdout.  using --outFile /dev/stdout does not appear to
                    // work properly (I just get empty string). So we're going to have to write this
                    // to a file.
                    let task = Process()
                    task.executableURL = URL(fileURLWithPath: "/usr/local/bin/node")
                    let outputPipe = Pipe()
                    task.standardOutput = outputPipe
                    task.arguments = ["/usr/local/bin/tsc", "--outFile", "/dev/stdout", inFile]
                    try task.run()
                    let compiledData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                    fileContents = String(data: compiledData, encoding: .utf8) ?? fileContents
                    
                    print(fileContents)
                } catch {
                    fatalError("Failed to use /usr/local/bin/tsc to compile the typescript file")
                }
            }
        }
    }
}
