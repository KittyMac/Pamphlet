import Foundation
import PackagePlugin

struct RuntimeError: Error {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    public var localizedDescription: String {
        return message
    }
}

public extension String {
    func decoded<T: Decodable>() throws -> T {
        guard let jsonData = self.data(using: .utf8) else {
            throw RuntimeError("Unable to convert json String to Data")
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "+Infinity", negativeInfinity: "-Infinity", nan: "NaN")
        return try decoder.decode(T.self, from: jsonData)
    }
}

func binaryTool(context: PluginContext, named toolName: String) -> String {
    var osName = "focal"
    
    #if os(Windows)
    osName = "windows"
    #else
    if let osFile = try? String(contentsOfFile: "/etc/os-release") {
        if osFile.contains("Amazon Linux") {
            osName = "amazonlinux2"
        }
        if osFile.contains("Fedora Linux 37") {
            osName = "fedora37"
        }
        if osFile.contains("Fedora Linux 38") {
            osName = "fedora38"
        }
    }
    #endif
    
    var swiftVersions: [String] = []
#if swift(>=5.9.2)
    swiftVersions.append("592")
#endif
#if swift(>=5.8.0)
    swiftVersions.append("580")
#endif
#if swift(>=5.7.3)
    swiftVersions.append("573")
#endif
#if swift(>=5.7.1)
    swiftVersions.append("571")
#endif
    
    // Find the most recent version of swift we support and return that
    for swiftVersion in swiftVersions {
        let toolName = "\(toolName)-\(osName)-\(swiftVersion)"
        if let _ = try? context.tool(named: toolName) {
            return toolName
        }
    }

    return "\(toolName)-\(osName)-\(swiftVersions.first!)"
}

func pluginShared(context: PluginContext, target: Target) throws -> (PackagePlugin.Path, String, String, [PackagePlugin.Path], [PackagePlugin.Path]) {
    
    let toolName = "PamphletTool"
    let binaryToolName = binaryTool(context: context, named: toolName)
    guard let tool = (try? context.tool(named: binaryToolName)) ?? (try? context.tool(named: toolName)) else {
        fatalError("FlynnPlugin unable to load \(binaryToolName)")
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
    #if os(Windows)
    inputFiles = inputFiles.map { "C:" + $0 }
    #endif

    var directoryPath = target.directory.string
    #if os(Windows)
    directoryPath = "C:" + directoryPath
    #endif
            
    gatherInputFiles(targets: [directoryPath],
                     destinationDir: copiesDirectory,
                     isDependency: false,
                     inputFiles: &inputFiles)
            
    gatherInputFiles(targets: target.recursiveTargetDependencies.map {
        #if os(Windows)
        "C:" + $0.directory.string
        #else
        $0.directory.string
        #endif
    },
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
    
    if let pamphletJson = try? String(contentsOfFile: "\(directoryPath)/Pamphlet/pamphlet.json") {
        struct Rule: Codable {
            var file: String?
            var releaseOnly: Bool?
            var includeOriginal: Bool?
        }
        var shouldIncludeDebug = false
        if let rules: [Rule] = try? pamphletJson.decoded() {
            for rule in rules where rule.file == nil {
                if rule.releaseOnly == false {
                    shouldIncludeDebug = true
                }
            }
        }
        
        if shouldIncludeDebug {
            outputFiles.append(
                pluginWorkDirectory + "/\(target.name)Pamphlet.debug.swift"
            )
        }
    }
    
    var toolPath = tool.path.string
    #if os(Windows)
    toolPath = "C:" + toolPath
    #endif
        
    return (PackagePlugin.Path(toolPath),
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
