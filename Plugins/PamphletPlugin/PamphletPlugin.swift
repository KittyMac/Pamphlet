import Foundation
import PackagePlugin

@main struct PamphletPlugin: BuildToolPlugin {
    
    let extensions = ["json", "ts", "txt", "md", "html", "htm", "js", "css", "png", "jpg", "base64"]
    
    func gatherInputFiles(target: Target,
                          inputFiles: inout [PackagePlugin.Path]) {
        
        let url = URL(fileURLWithPath: target.directory.string)
        if let enumerator = FileManager.default.enumerator(at: url,
                                                           includingPropertiesForKeys: [.isRegularFileKey],
                                                           options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
            for case let fileURL as URL in enumerator {
                do {
                    let fileAttributes = try fileURL.resourceValues(forKeys:[.isRegularFileKey])
                    if fileAttributes.isRegularFile == true && extensions.contains(fileURL.pathExtension) {
                        inputFiles.append(PackagePlugin.Path(fileURL.path))
                    }
                } catch { print(error, fileURL) }
            }
        }
        
        for dependency in target.dependencies {
            switch dependency {
            case .target(let target):
                gatherInputFiles(target: target,
                                 inputFiles: &inputFiles)
                break
            default:
                break
            }
        }
    }
    
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        
        guard let target = target as? SwiftSourceModuleTarget else {
            return []
        }

        let tool = try context.tool(named: "Pamphlet")
        
        var inputFiles: [PackagePlugin.Path] = [
            tool.path
        ]
        gatherInputFiles(target: target,
                         inputFiles: &inputFiles)
                
        let outputFiles: [String] = [
            context.pluginWorkDirectory.string + "/Pamphlet.swift"
        ]
        
        return [
            .buildCommand(
                displayName: "Pamphlet - generating resources...",
                executable: tool.path,
                arguments: [
                    "--collapse-all",
                    target.directory.string + "/Pamphlet",
                    context.pluginWorkDirectory.string
                ],
                inputFiles: inputFiles,
                outputFiles: outputFiles.map { PackagePlugin.Path($0) }
            )
        ]
    }
}
