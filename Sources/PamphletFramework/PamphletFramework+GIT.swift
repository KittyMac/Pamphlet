import Foundation
import libmcpp
import Hitch

extension PamphletFramework {
    
    #if os(macOS) || os(Linux)
    func git(repoPath: String) -> String? {
        do {
            let path = pathFor(executable: "git")
            
            let task = Process()
            task.executableURL = URL(fileURLWithPath: path)
            task.arguments = [
                "-C",
                repoPath,
                "describe"
            ]
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
                    print("warning: git describe did not return a valid semver for repo at \(repoPath)")
                }
            }
            
            task.waitUntilExit()
            
            return nil
        } catch {
            print("warning: failed to retrieve semver from git")
            return nil
        }
    }
    func gitHash(repoPath: String) -> String {
        if let version = git(repoPath: repoPath),
           let md5 = Hitch(string: version).md5() {
            return md5.toString()
        }
        return ""
    }
    #else
    func git(repoPath: String) -> String? {
        return nil
    }
    func gitHash(repoPath: String) -> String {
        return ""
    }
    #endif
}
