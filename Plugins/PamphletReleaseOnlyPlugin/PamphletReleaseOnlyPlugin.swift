import Foundation
import PackagePlugin

@main struct PamphletPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        guard let target = target as? SwiftSourceModuleTarget else {
            return []
        }
        
        let (toolPath, repoPath, copiesDirectory, inputFiles, outputFiles) = try pluginShared(context: context,
                                                                                              target: target,
                                                                                              includeDebug: false)
        
        var pluginWorkDirectory = context.pluginWorkDirectory.string
        #if os(Windows)
        pluginWorkDirectory = "C:" + pluginWorkDirectory
        #endif
        
        return [
            .buildCommand(
                displayName: "Pamphlet - generating resources...",
                executable: toolPath,
                arguments: [
                    "--prefix",
                    target.name,
                    "--release",
                    "--git-path",
                    repoPath,
                    copiesDirectory,
                    pluginWorkDirectory
                ],
                inputFiles: inputFiles,
                outputFiles: outputFiles
            )
        ]
    }
}
