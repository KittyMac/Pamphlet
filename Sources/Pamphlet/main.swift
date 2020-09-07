import PamphletFramework
import ArgumentParser

struct Pamphlet: ParsableCommand {
    
    static var configuration = CommandConfiguration(
        abstract: "Store files resources in Swift code",
        subcommands: [Generate.self, Preprocess.self],
        defaultSubcommand: Generate.self)
    
    struct Generate: ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Generate Swift code from file resources")

        @Flag(help: "Delete existing Pamphlet files in the output directories before processing")
        var clean: Bool = false
        
        @Flag(help: "Generate a full swiftpm package directory")
        var swiftpm: Bool = false
        
        @Argument(help: "Path to directory of files to process")
        var inDirectory: String
        
        @Argument(help: "Path to sources directory to output Swift files to")
        var outDirectory: String
        
        @Argument(help: "List of valid file extensions (empty means all)")
        var extensions: [String] = []
        
        mutating func run() throws {
            PamphletFramework().process(extensions, inDirectory, outDirectory, swiftpm, clean)
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

