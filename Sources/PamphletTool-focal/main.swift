#if canImport(PamphletFramework)

import PamphletFramework
import ArgumentParser
import Foundation

struct Pamphlet: ParsableCommand {
    
    static var configuration = CommandConfiguration(
        abstract: "Store files resources in Swift code",
        subcommands: [Generate.self, Preprocess.self, Skip.self],
        defaultSubcommand: Generate.self)
    
    struct Generate: ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Generate Swift (or Kotlin) code from file resources")
        
        @Option(help: "Prefix to prepend to Pamphlet class name")
        var prefix: String?
        
        @Argument(help: "Path to directory of files to process")
        var inDirectory: String
        
        @Argument(help: "Path to sources directory to output Swift files to")
        var outDirectory: String
        
        @Option(help: "Path to git repository")
        var gitPath: String = "."
                                
        @Flag(help: "Generate Kotlin code instead of Swift code")
        var kotlin: Bool = false
        
        @Option(help: "Package path for Kotlin code generation (ie com.app.main)")
        var kotlinPackage: String?
        
        @Flag(help: "Only generate release code (no dynamic loading when in Debug)")
        var release: Bool = false

        @Flag(inversion: .prefixedEnableDisable, help: "Include the original file content")
        var original: Bool = true
        
        @Flag(inversion: .prefixedEnableDisable, help: "Include the gzip'd file content")
        var gzip: Bool = true
        
        @Flag(inversion: .prefixedEnableDisable, help: "Minify html content")
        var html: Bool = true
        
        @Flag(inversion: .prefixedEnableDisable, help: "Minify javascript content")
        var js: Bool = true
                
        @Flag(inversion: .prefixedEnableDisable, help: "Minify JSON content")
        var json: Bool = true
                
        mutating func run() throws {
            if let buildAction = ProcessInfo.processInfo.environment["ACTION"],
               buildAction == "indexbuild" {
                return
            }
            
            var options = PamphletOptions()
            
            if release { options.insert(.releaseOnly) }
            if original { options.insert(.includeOriginal) }
            if gzip { options.insert(.includeGzip) }
            if html { options.insert(.minifyHtml) }
            if js { options.insert(.minifyJs) }
            if json { options.insert(.minifyJson) }
            if kotlin { options.insert(.kotlin) }
            if let kotlinPackage = kotlinPackage { options.kotlinPackage = kotlinPackage }
            
            PamphletFramework.shared.process(prefix: prefix,
                                             extensions: [],
                                             inDirectory: inDirectory,
                                             outDirectory: outDirectory,
                                             gitPath: gitPath,
                                             options: options)
        }
    }

    struct Preprocess: ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Output the preprocessed results of a single file resource")
        
        @Argument(help: "Path to the file resource to preprocess")
        var inFile: String
        
        mutating func run() {
            if let buildAction = ProcessInfo.processInfo.environment["ACTION"],
               buildAction == "indexbuild" {
                return
            }
            
            PamphletFramework.shared.preprocess(file: inFile)
        }
    }
    
    struct Skip: ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Don't do anything")
                
        mutating func run() {
            
        }
    }
    
}

Pamphlet.main()

#endif
