import PamphletFramework
import ArgumentParser

struct Pamphlet: ParsableCommand {
    
    static var configuration = CommandConfiguration(
        abstract: "Store files resources in Swift code",
        subcommands: [Generate.self, Preprocess.self],
        defaultSubcommand: Generate.self)
    
    struct Generate: ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Generate Swift (or Kotlin) code from file resources")
        
        @Option(help: "Prefix to prepend to Pamphlet class name")
        var prefix: String?
        
        @Argument(help: "Path to directory of files to process")
        var inDirectory: String
        
        @Argument(help: "Path to sources directory to output Swift files to")
        var outDirectory: String
        
        @Argument(help: "List of valid file extensions (empty means all)")
        var extensions: [String] = []
        
        @Flag(help: "Collapse files in directory into a single .swift file")
        var collapse: Bool = false
        
        @Flag(help: "Collapse all files into a single Pamphlet.swift file")
        var collapseAll: Bool = false
        
        @Flag(help: "Generate Kotlin code instead of Swift code")
        var kotlin: Bool = false
        
        @Option(help: "Package path for Kotlin code generation (ie com.app.main)")
        var kotlinPackage: String?
        
        @Flag(help: "Delete existing Pamphlet files in the output directories before processing")
        var clean: Bool = false
        
        @Flag(help: "Generate a full swiftpm package directory")
        var swiftpm: Bool = false
        
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
        
        @Flag(inversion: .prefixedEnableDisable, help: "Compile typescript content")
        var ts: Bool = true
        
        @Flag(inversion: .prefixedEnableDisable, help: "Minify JSON content")
        var json: Bool = true
                
        mutating func run() throws {
            var options = PamphletOptions()
            
            if release { options.insert(.releaseOnly) }
            if clean { options.insert(.clean) }
            if swiftpm { options.insert(.swiftpm) }
            if original { options.insert(.includeOriginal) }
            if gzip { options.insert(.includeGzip) }
            if html { options.insert(.minifyHtml) }
            if js { options.insert(.minifyJs) }
            if json { options.insert(.minifyJson) }
            if collapse { options.insert(.collapse) }
            if collapseAll { options.insert(.collapseAll) }
            if kotlin { options.insert(.kotlin) }
            if let kotlinPackage = kotlinPackage { options.kotlinPackage = kotlinPackage }
            
            PamphletFramework().process(prefix: prefix,
                                        extensions: extensions,
                                        inDirectory: inDirectory,
                                        outDirectory: outDirectory,
                                        options: options)
        }
    }

    struct Preprocess: ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Output the preprocessed results of a single file resource")
        
        @Argument(help: "Path to the file resource to preprocess")
        var inFile: String
        
        mutating func run() {
            PamphletFramework().preprocess(inFile)
        }
    }
    
}

Pamphlet.main()

