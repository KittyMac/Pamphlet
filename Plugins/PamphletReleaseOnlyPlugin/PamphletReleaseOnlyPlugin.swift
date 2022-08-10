import Foundation
import PackagePlugin

@main struct PamphletReleaseOnlyPlugin: BuildToolPlugin {
        
    func gatherInputFiles(targets: [Target],
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
            context.pluginWorkDirectory.string + "/Pamphlet.release.swift"
        ]
                
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
}
