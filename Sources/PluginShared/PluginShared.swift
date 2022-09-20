import Foundation

func gatherInputFiles(targets: [String],
                      destinationDir: String?,
                      isDependency: Bool,
                      inputFiles: inout [String]) {
    
    for target in targets {
        let base = target + "/Pamphlet/"
        
        let url = URL(fileURLWithPath: target)
        if let enumerator = FileManager.default.enumerator(at: url,
                                                           includingPropertiesForKeys: [.isRegularFileKey],
                                                           options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
            for case let fileURL as URL in enumerator {
                do {
                    let fileAttributes = try fileURL.resourceValues(forKeys:[.isRegularFileKey])
                    if fileAttributes.isRegularFile == true {
                        
                        // We only want files which are in the Pamphlet/
                        // directory of their respective target
                        if fileURL.path.hasPrefix(base) {
                            
                            if let destinationDir = destinationDir {
                                let relativePath = fileURL.path.replacingOccurrences(of: base, with: "")
                                
                                let sourcePath = fileURL.path
                                let destinationPath = destinationDir + relativePath
                                
                                // ensure the directory path exists
                                let destinationDirectory = URL(fileURLWithPath: destinationPath).deletingLastPathComponent().path
                                try! FileManager.default.createDirectory(atPath: destinationDirectory,
                                                                         withIntermediateDirectories: true)
                                
                                try? FileManager.default.createSymbolicLink(atPath: destinationPath,
                                                                            withDestinationPath: sourcePath)
                            }
                            
                            inputFiles.append(fileURL.path)
                        }
                    }
                } catch { print(error, fileURL) }
            }
        }
    }
}

func pathFor(executable name: String) -> String {
    if FileManager.default.fileExists(atPath: "/opt/homebrew/bin/\(name)") {
        return "/opt/homebrew/bin/\(name)"
    } else if FileManager.default.fileExists(atPath: "/usr/bin/\(name)") {
        return "/usr/bin/\(name)"
    } else if FileManager.default.fileExists(atPath: "/usr/local/bin/\(name)") {
        return "/usr/local/bin/\(name)"
    } else if FileManager.default.fileExists(atPath: "/bin/\(name)") {
        return "/bin/\(name)"
    }
    return "./\(name)"
}

func git() -> String? {
    do {
        let path = pathFor(executable: "git")
        
        let repoPath = FileManager.default.currentDirectoryPath
        
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
                print("warning: git describe did not return a valid semver, got \(tagString) instead")
            }
        }
        
        return nil
    } catch {
        print("warning: failed to retrieve semver from git")
        return nil
    }
}
