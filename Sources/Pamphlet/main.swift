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
        
        @Flag(help: "Delete existing Pamphlet files in the output directories before processing")
        var clean: Bool = false
        
        @Flag(help: "Generate a full swiftpm package directory")
        var swiftpm: Bool = false
        
        @Flag(help: "Only generate release code (no dynamic loading when in Debug)")
        var release: Bool = false
        
        @Flag(help: "Include the original file content")
        var includeOriginal: Bool = true
        
        @Flag(help: "Include the gzip'd file content")
        var includeGzip: Bool = true
        
        @Flag(help: "Minify html content (if htmlcompressor found)")
        var minifyHtml: Bool = true
        
        @Flag(help: "Minify javascript content (if closure-compiler found)")
        var minifyJs: Bool = true
        
        @Flag(help: "Compile typescript content (if tsc found)")
        var minifyTs: Bool = true
        
        @Flag(help: "Minify JSON content (if jj found)")
        var minifyJson: Bool = true
                
        mutating func run() throws {
            var options = PamphletOptions()
            
            if release { options.insert(.releaseOnly) }
            if clean { options.insert(.clean) }
            if swiftpm { options.insert(.swiftpm) }
            if includeOriginal { options.insert(.includeOriginal) }
            if includeGzip { options.insert(.includeGzip) }
            if minifyHtml { options.insert(.minifyHtml) }
            if minifyJs { options.insert(.minifyJs) }
            if minifyTs { options.insert(.minifyTs) }
            if minifyJson { options.insert(.minifyJson) }
            
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

