import PamphletFramework
import ArgumentParser

struct Pamphlet: ParsableCommand {
    
    @Argument(help: "Path to directory of file to process")
    var inDirectory: String
    
    @Argument(help: "Path to sources directory to output Swift files to")
    var outDirectory: String
    
    @Argument(help: "List of valid file extensions")
    var extensions: [String] = ["txt", "md", "html", "htm", "js", "css", "png", "jpg"]
    
    mutating func run() throws {
        PamphletFramework().process(extensions, inDirectory, outDirectory)
    }
}

Pamphlet.main()

