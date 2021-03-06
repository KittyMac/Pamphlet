import PamphletFramework
import ArgumentParser

struct Pamphlet: ParsableCommand {
    
    static var configuration = CommandConfiguration(
        abstract: "Store files resources in Swift code",
        subcommands: [Generate.self, Preprocess.self],
        defaultSubcommand: Generate.self)
    
    struct Generate: ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Generate Swift code from file resources")
        
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
        
        @Flag(inversion: .prefixedEnableDisable, help: "Minify html content (if htmlcompressor found)")
        var html: Bool = true
        
        @Flag(inversion: .prefixedEnableDisable, help: "Minify javascript content (if closure-compiler found)")
        var js: Bool = true
        
        @Flag(inversion: .prefixedEnableDisable, help: "Compile typescript content (if tsc found)")
        var ts: Bool = true
        
        @Flag(inversion: .prefixedEnableDisable, help: "Minify JSON content (if jj found)")
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
            if ts { options.insert(.minifyTs) }
            if json { options.insert(.minifyJson) }
            if collapse { options.insert(.collapse) }
            
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

