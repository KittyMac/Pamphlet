import Foundation
import PackagePlugin

@main struct PamphletPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        fatalError("""
            deprecated in v0.3.108: to maintain functionality add pamphlet.json file:
            [
                {
                    "releaseOnly": true
                }
            ]
        """)
    }
}
