import Foundation
import PackagePlugin

@main struct PamphletPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        guard let target = target as? SwiftSourceModuleTarget else {
            return []
        }
        
        let (toolPath, copiesDirectory, inputFiles, outputFiles) = try pluginShared(context: context,
                                                                                    target: target,
                                                                                    includeDebug: true)
        
        return [
            .buildCommand(
                displayName: "Pamphlet - generating resources...",
                executable: toolPath,
                arguments: [
                    "--prefix",
                    target.name,
                    copiesDirectory,
                    context.pluginWorkDirectory.string
                ],
                inputFiles: inputFiles,
                outputFiles: outputFiles
            )
        ]
    }
}
