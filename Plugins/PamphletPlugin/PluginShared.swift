import Foundation
import PackagePlugin

func pluginShared(context: PluginContext, target: Target, includeDebug: Bool) throws -> (PackagePlugin.Path, String, String, [PackagePlugin.Path], [PackagePlugin.Path]) {
    
    // Note: We want to load the right pre-compiled tool for the right OS
    // There are currently two tools:
    // PamphletPluginTool-focal: supports macos and ubuntu-focal
    // PamphletPluginTool-focal: supports macos and amazonlinux2
    //
    // When we are compiling to build the precompiled tools, only the
    // default ( PamphletPluginTool-focal ) is available.
    //
    // When we are running and want to use the pre-compiled tools, we look in
    // /etc/os-release (available on linux) to see what distro we are running
    // and to load the correct tool there.
    var tool = try? context.tool(named: "PamphletTool-focal")
    
    #if os(Windows)
    if let osTool = try? context.tool(named: "FlynnPluginTool-windows") {
        tool = osTool
    }
    #endif
    
    if let osFile = try? String(contentsOfFile: "/etc/os-release") {
        if osFile.contains("Amazon Linux"),
           let osTool = try? context.tool(named: "PamphletTool-amazonlinux2") {
            tool = osTool
        }
        if osFile.contains("Fedora Linux 37"),
           let osTool = try? context.tool(named: "PamphletTool-fedora") {
            tool = osTool
        }
        if osFile.contains("Fedora Linux 38"),
           let osTool = try? context.tool(named: "PamphletTool-fedora38") {
            tool = osTool
        }
    }
    
    guard let tool = tool else {
        fatalError("PamphletPlugin unable to load PamphletTool")
    }
    
    var pluginWorkDirectory = context.pluginWorkDirectory.string
    #if os(Windows)
    pluginWorkDirectory = "C:" + pluginWorkDirectory
    #endif
    
    let copiesDirectory = pluginWorkDirectory + "/Pamphlet/"
    
    try? FileManager.default.removeItem(atPath: copiesDirectory)
    try? FileManager.default.createDirectory(atPath: copiesDirectory, withIntermediateDirectories: false)
    
    var inputFiles: [String] = [
        tool.path.string
    ]
    
    var directoryPath = target.directory.string
    #if os(Windows)
    directoryPath = "C:" + directoryPath
    #endif
            
    gatherInputFiles(targets: [directoryPath],
                     destinationDir: copiesDirectory,
                     isDependency: false,
                     inputFiles: &inputFiles)
            
    gatherInputFiles(targets: target.recursiveTargetDependencies.map { $0.directory.string },
                     destinationDir: copiesDirectory,
                     isDependency: true,
                     inputFiles: &inputFiles)
    
    // detect when the git version changes and reprocess
    let gitVersionPath = pluginWorkDirectory + "/git.version"
    if let version = git(repoPath: directoryPath) {
        // save the version number as an input in our tool working directory
        if let lastVersion = try? String(contentsOfFile: gitVersionPath),
           lastVersion == version {
        } else {
            try? version.write(toFile: gitVersionPath, atomically: false, encoding: .utf8)
        }
    }
    
    var outputFiles: [String] = [
        pluginWorkDirectory + "/\(target.name)Pamphlet.release.swift"
    ]
    
    if includeDebug {
        outputFiles.append(
            pluginWorkDirectory + "/\(target.name)Pamphlet.debug.swift"
        )
    }
    
    return (tool.path,
            directoryPath,
            copiesDirectory,
            inputFiles.map { PackagePlugin.Path($0) },
            outputFiles.map { PackagePlugin.Path($0) })
}

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
        
        return nil
    } catch {
        print("warning: failed to retrieve semver from git")
        return nil
    }
}
