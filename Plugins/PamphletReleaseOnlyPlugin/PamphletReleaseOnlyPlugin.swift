import Foundation
import PackagePlugin

@main struct PamphletPlugin: BuildToolPlugin {
    
    private func shouldProcess(inputs: [String],
                               outputs: [String]) -> Bool {
        var maxInputDate = Date.distantPast
        var minOutputDate = Date.distantFuture
        
        for input in inputs {
            if let attr = try? FileManager.default.attributesOfItem(atPath: input),
               let date = attr[FileAttributeKey.modificationDate] as? Date {
                if date > maxInputDate {
                    print("input: \(input) is \(date)")
                    maxInputDate = date
                }
            }
        }
        
        for output in outputs {
            if let attr = try? FileManager.default.attributesOfItem(atPath: output),
               let date = attr[FileAttributeKey.modificationDate] as? Date {
                if date < minOutputDate {
                    print("output: \(output) is \(date)")
                    minOutputDate = date
                }
            }
        }
        
        if maxInputDate == Date.distantPast || minOutputDate == Date.distantFuture {
            return true
        }
                
        return minOutputDate < maxInputDate
    }
        
    private func gatherInputFiles(targets: [Target],
                                  destinationDir: String?,
                                  isDependency: Bool,
                                  inputFiles: inout [PackagePlugin.Path]) {
        
        for target in targets {
            let base = target.directory.string + "/Pamphlet/"
            
            let url = URL(fileURLWithPath: target.directory.string)
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

                                inputFiles.append(PackagePlugin.Path(fileURL.path))
                            }
                        }
                    } catch { print(error, fileURL) }
                }
            }
        }
    }
    
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        
        guard let target = target as? SwiftSourceModuleTarget else {
            return []
        }

        let tool = try context.tool(named: "Pamphlet")
        
        let copiesDirectory = context.pluginWorkDirectory.string + "/Pamphlet/"
        
        try? FileManager.default.removeItem(atPath: copiesDirectory)
        try? FileManager.default.createDirectory(atPath: copiesDirectory, withIntermediateDirectories: false)
        
        var inputFiles: [PackagePlugin.Path] = [
            tool.path
        ]
        
        gatherInputFiles(targets: [target],
                         destinationDir: copiesDirectory,
                         isDependency: false,
                         inputFiles: &inputFiles)
        
        gatherInputFiles(targets: target.recursiveTargetDependencies,
                         destinationDir: copiesDirectory,
                         isDependency: true,
                         inputFiles: &inputFiles)
                        
        let outputFiles: [String] = [
            context.pluginWorkDirectory.string + "/Pamphlet.debug.swift",
            context.pluginWorkDirectory.string + "/Pamphlet.release.swift"
        ]
        
        // detect when the git version changes and reprocess
        let gitVersionPath = context.pluginWorkDirectory.string + "/git.version"
        var gitVersionDidChange = true
        if let version = git() {
            // save the version number as an input in our tool working directory
            if let lastVersion = try? String(contentsOfFile: gitVersionPath),
               lastVersion == version {
                gitVersionDidChange = false
            } else {
                try? version.write(toFile: gitVersionPath, atomically: false, encoding: .utf8)
            }
        }
                
        if shouldProcess(inputs: inputFiles.map { $0.string },
                         outputs: outputFiles) || gitVersionDidChange {
            return [
                .buildCommand(
                    displayName: "Pamphlet - generating resources...",
                    executable: tool.path,
                    arguments: [
                        "--release",
                        copiesDirectory,
                        context.pluginWorkDirectory.string
                    ],
                    inputFiles: inputFiles,
                    outputFiles: outputFiles.map { PackagePlugin.Path($0) }
                )
            ]
        }
        
        return [
            .buildCommand(
                displayName: "Pamphlet - skipping...",
                executable: tool.path,
                arguments: [ "skip" ],
                inputFiles: inputFiles,
                outputFiles: outputFiles.map { PackagePlugin.Path($0) }
            )
        ]
    }
}


fileprivate func pathFor(executable name: String) -> String {
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

fileprivate func git() -> String? {
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
