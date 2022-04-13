import Foundation
import libmcpp

extension PamphletFramework {
    func git() -> String? {
        do {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/git")
            task.arguments = ["describe"]
            let inputPipe = Pipe()
            let outputPipe = Pipe()
            task.standardInput = inputPipe
            task.standardOutput = outputPipe
            task.standardError = nil
            try task.run()
            
            DispatchQueue.global(qos: .userInitiated).async {
                inputPipe.fileHandleForWriting.write(Data())
                inputPipe.fileHandleForWriting.closeFile()
            }
            let tagData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                            
            if let tagString = String(data: tagData, encoding: .utf8) {
                if tagString.hasPrefix("v") && tagString.components(separatedBy: ".").count == 3 {
                    return tagString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                } else {
                    print("warning: git describe did not return a valid semver, got \(tagString) instead")
                }
            }
            
            return nil
        } catch {
            print("warning: failed to retrieve semver from git")
            return nil
        }
    }
}
