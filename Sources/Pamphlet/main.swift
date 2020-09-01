import PamphletFramework
import ArgumentParser

struct Pamphlet: ParsableCommand {
    
    @Flag(help: "Delete existing Pamphlet files in the output directories before processing")
    var clean: Bool = false
    
    @Flag(help: "Generate a full swiftpm package directory")
    var swiftpm: Bool = false
    
    @Argument(help: "Path to directory of file to process")
    var inDirectory: String
    
    @Argument(help: "Path to sources directory to output Swift files to")
    var outDirectory: String
    
    @Argument(help: "List of valid file extensions (empty means all)")
    var extensions: [String] = []
    
    mutating func run() throws {
        PamphletFramework().process(extensions, inDirectory, outDirectory, swiftpm, clean)
    }
}

Pamphlet.main()

