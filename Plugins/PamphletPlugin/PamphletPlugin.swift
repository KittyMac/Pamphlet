import Foundation
import PackagePlugin

@main struct PamphletPlugin: BuildToolPlugin {
    
    private func modificationDate(filePath: String) -> Date {
        let resourceKeys: [URLResourceKey] = [.contentModificationDateKey]
        let fileURL = URL(fileURLWithPath: filePath)
        if let values = try? fileURL.resourceValues(forKeys: Set(resourceKeys)) {
            return values.contentModificationDate ?? Date.distantPast
        }
        return Date.distantPast
    }
    
    private func copyFile(sourceFile: String,
                          destinationFile: String) {
        if modificationDate(filePath: destinationFile) < modificationDate(filePath: sourceFile) {
            try? FileManager.default.copyItem(atPath: sourceFile,
                                              toPath: destinationFile)
        }
    }
    
    func gatherInputFiles(targets: [Target],
                          copyTo: String?,
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
                                
                                if let copyTo = copyTo {
                                    let relativePath = fileURL.path.replacingOccurrences(of: base, with: "")
                                    
                                    let sourcePath = fileURL.path
                                    let destinationPath = copyTo + relativePath
                                    
                                    // ensure the directory path exists
                                    let destinationDirectory = URL(fileURLWithPath: destinationPath).deletingLastPathComponent().path
                                    try! FileManager.default.createDirectory(atPath: destinationDirectory,
                                                                             withIntermediateDirectories: true)
                                    
                                    
                                    copyFile(sourceFile: sourcePath,
                                             destinationFile: destinationPath)
                                }
                                
                                inputFiles.append(PackagePlugin.Path(fileURL.path))
                            }
                        }
                    } catch { print(error, fileURL) }
                }
            }
        }
    }
    
    func removeExtraFiles(from base: String,
                          inputFiles: [PackagePlugin.Path]) {
        // Recursively walk from path. Any file which does not exist in inputFiles should be removed.
        
        let url = URL(fileURLWithPath: base)
        if let enumerator = FileManager.default.enumerator(at: url,
                                                           includingPropertiesForKeys: [.isRegularFileKey],
                                                           options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
            for case let fileURL as URL in enumerator {
                do {
                    let fileAttributes = try fileURL.resourceValues(forKeys:[.isRegularFileKey])
                    if fileAttributes.isRegularFile == true {
                        
                        let relativePath = "/Pamphlet/" + fileURL.path.replacingOccurrences(of: base, with: "")
                        
                        var hasInputFile = false
                        for inputFile in inputFiles where inputFile.string.hasSuffix(relativePath) {
                            hasInputFile = true
                            break
                        }
                        
                        if hasInputFile == false {
                            try? FileManager.default.removeItem(at: fileURL)
                        }
                    }
                } catch { print(error, fileURL) }
            }
        }
    }
    
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        
        guard let target = target as? SwiftSourceModuleTarget else {
            return []
        }

        let tool = try context.tool(named: "Pamphlet")
        
        let copiesDirectory = context.pluginWorkDirectory.string + "/Pamphlet/"
        
        try? FileManager.default.createDirectory(atPath: copiesDirectory, withIntermediateDirectories: false)
        
        var inputFiles: [PackagePlugin.Path] = [
            tool.path
        ]
        
        gatherInputFiles(targets: [target],
                         copyTo: copiesDirectory,
                         inputFiles: &inputFiles)
        
        gatherInputFiles(targets: target.recursiveTargetDependencies,
                         copyTo: copiesDirectory,
                         inputFiles: &inputFiles)
        
        removeExtraFiles(from: copiesDirectory,
                         inputFiles: inputFiles)
                
        let outputFiles: [String] = [
            context.pluginWorkDirectory.string + "/Pamphlet.swift"
        ]
        
        return [
            .buildCommand(
                displayName: "Pamphlet - generating resources...",
                executable: tool.path,
                arguments: [
                    "--collapse-all",
                    copiesDirectory,
                    context.pluginWorkDirectory.string
                ],
                inputFiles: inputFiles,
                outputFiles: outputFiles.map { PackagePlugin.Path($0) }
            )
        ]
    }
}
