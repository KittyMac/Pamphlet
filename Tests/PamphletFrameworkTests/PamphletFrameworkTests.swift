import XCTest
//@testable import Pamphlet
import PamphletFramework

#if os(Windows)
public let pamphletTempPath = "C:/WINDOWS/Temp/"
#else
public let pamphletTempPath = "/tmp/"
#endif

final class PamphletTests: XCTestCase {
    
    private func path(to: String) -> String {
        return URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .appendingPathComponent(to, isDirectory: true)
            .path
    }
    
    #if os(macOS)
    
    func testProcessOptimize() {
        let extensions: [String] = []
        
        PamphletFramework.shared.process(prefix: nil,
                                         extensions: extensions,
                                         inDirectory: "/Users/rjbowli/Development/smallplanet/smallplanet_RoverCore_SDK/Sources/RoverCore/Pamphlet",
                                         outDirectory: "\(pamphletTempPath)Pamphlet",
                                         gitPath: path(to: "Pamphlet"),
                                         options:[.releaseOnly, .includeOriginal, .includeGzip, .minifyHtml, .minifyJs, .minifyJson])
    }
    
    func testPamphlet() {
        let extensions: [String] = []
        PamphletFramework.shared.process(prefix: nil,
                                         extensions: extensions,
                                         inDirectory: path(to: "Pamphlet"),
                                         outDirectory: "\(pamphletTempPath)Pamphlet",
                                         gitPath: path(to: "Pamphlet"),
                                         options:[.includeOriginal, .includeGzip, .minifyHtml, .minifyJs, .minifyJson])
    }
    
    func testPamphletReleaseOnly() {
        let extensions: [String] = []
        PamphletFramework.shared.process(prefix: nil,
                                         extensions: extensions,
                                         inDirectory: path(to: "Pamphlet"),
                                         outDirectory: "\(pamphletTempPath)Pamphlet",
                                         gitPath: path(to: "Pamphlet"),
                                         options:[.releaseOnly, .includeOriginal, .includeGzip, .minifyHtml, .minifyJs, .minifyJson])
    }
    
    func testDebugHotLoading() {
        // should print the path to the file if it hotloads
        //XCTAssertEqual(PamphletFrameworkTestsPamphlet.Test1Css().description, "#title { border-image-slice: 22 fill; }")
    }
    
    func testPreprocessFileDateCompareWithIncludes() {
        let extensions = ["txt", "md", "html", "htm", "js", "css", "png", "jpg"]
        PamphletFramework.shared.process(prefix: nil,
                                         extensions: extensions,
                                         inDirectory: "/Users/rjbowli/Development/chimerasw/Pamphlet/meta",
                                         outDirectory: "\(pamphletTempPath)Pamphlet",
                                         gitPath: "/Users/rjbowli/Development/chimerasw/Pamphlet/meta",
                                         options:PamphletOptions.default)
    }
    
    #endif
    
    func testProcessString() {
        let json = """
        [
        0,
        1,
        2,
        3
        ]
        """
        let result = PamphletFramework.shared.process(name: "sample.json", string:json)
        XCTAssertEqual(result, "[0,1,2,3]")
    }
    
        
    func testPreprocessFollow1() {
        let result = PamphletFramework.shared.preprocess(file: path(to: "Pamphlet/includeFollow1.css"))
        XCTAssertEqual(result, "#Follow3 { }\n#Follow2 { }\n#Follow1 { }\n")
    }
    
    func testPreprocess1() {
        let result = PamphletFramework.shared.preprocess(file: path(to: "Pamphlet/test1.html"))
        XCTAssertEqual(result, "\"'Hello dog!''Hello cat!''Hello pineapple!''Hello world!'\"\n")
    }
    
    func testPreprocess2() {
        let resultA = PamphletFramework.shared.preprocess(file: path(to: "Pamphlet/test2.html"))
        XCTAssertEqual(resultA, "\"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.\"\n")
        
        let resultB = PamphletFramework.shared.preprocess(file: path(to: "Pamphlet/test2b.html"))
        XCTAssertEqual(resultB, "\"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.\"\n")
    }
    
    func testPreprocess3() {
        let result = PamphletFramework.shared.preprocess(file: path(to: "Pamphlet/test3.html"))
        XCTAssertEqual(result, "{ command: hasRover ? 'reset' : 'skip', progress: scraper.progressCurrent, delay: 0, state: scraper.state, scraperStorageJson: scraperStorageAsJson(), tag: checkStringLength(\"this is a tag\") };\n{ command: 'external', progress: progressCurrent, provider: 'Some', storeId: 11, state: \"STATE_SOME\", tag: `Some ${11}` }\n")
    }
    
    func testPreprocess4() {
        let result = PamphletFramework.shared.preprocess(file: path(to: "Pamphlet/test4.html"))
        XCTAssertEqual(result, "{ command: 'external', progress: progressCurrent, provider: 'Some', storeId: 11, state: \"STATE_SOME\", tag: `Some ${11}` }\n")
    }
    
    func testPreprocess5() {
        // Unterminated macro error
        let filepath = path(to: "Pamphlet") + "/test5.html"
        let result = PamphletFramework.shared.preprocess(file: filepath)
        XCTAssertEqual(result, try! String(contentsOfFile: filepath))
    }
    
    func testPreprocess7() {
        let result = PamphletFramework.shared.preprocess(file: path(to: "Pamphlet/test7.html"))
        XCTAssertEqual(result, "/(?:#f|term1|term2|term3|term with space)/i\n/(?: #f| term1| term2| term3| term with space )/i\n")
    }
    
    func testNotAValidPreprocessingToken() {
        let result = PamphletFramework.shared.preprocess(file: path(to: "Pamphlet/test2.js"))
        XCTAssertEqual(result, "\n\nvar x = 5\n`width:${x}em;height:${x}em;`\n")
    }
    
    func testPreprocessUnknownDirective() {
        let result = PamphletFramework.shared.preprocess(file: path(to: "Pamphlet/test1.css"))
        XCTAssertEqual(result, "\n#title {\n    border-image-slice: 22 fill;\n}\n")
    }
    
    func testPreprocessIncludeFromSourcePath() {
        PamphletFramework.shared.ignoreHeader = "rover/"
        let result = PamphletFramework.shared.preprocess(file: path(to: "Pamphlet/include1.css"))
        XCTAssertEqual(result, "\n#title {\n    border-image-slice: 22 fill;\n}\n\n#title {\n    border-image-slice: 22 fill;\n}\n")
    }
    
    func testPreprocessImageFile() {
        let result = PamphletFramework.shared.preprocess(file: path(to: "Pamphlet/include_image.js"))
        XCTAssertEqual(result, "\nlet icon_png = \"iVBORw0KGgoAAAANSUhEUgAAAIAAAACACAIAAABMXPacAAAACXBIWXMAAAsTAAALEwEAmpwYAAAFG2lUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4gPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgNi4wLWMwMDYgNzkuZGFiYWNiYiwgMjAyMS8wNC8xNC0wMDozOTo0NCAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bWxuczpkYz0iaHR0cDovL3B1cmwub3JnL2RjL2VsZW1lbnRzLzEuMS8iIHhtbG5zOnBob3Rvc2hvcD0iaHR0cDovL25zLmFkb2JlLmNvbS9waG90b3Nob3AvMS4wLyIgeG1sbnM6eG1wTU09Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9tbS8iIHhtbG5zOnN0RXZ0PSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvc1R5cGUvUmVzb3VyY2VFdmVudCMiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIDIyLjQgKE1hY2ludG9zaCkiIHhtcDpDcmVhdGVEYXRlPSIyMDIxLTExLTA4VDE2OjM0OjUyLTA1OjAwIiB4bXA6TW9kaWZ5RGF0ZT0iMjAyMS0xMS0wOFQxNzoxOTozMS0wNTowMCIgeG1wOk1ldGFkYXRhRGF0ZT0iMjAyMS0xMS0wOFQxNzoxOTozMS0wNTowMCIgZGM6Zm9ybWF0PSJpbWFnZS9wbmciIHBob3Rvc2hvcDpDb2xvck1vZGU9IjMiIHBob3Rvc2hvcDpJQ0NQcm9maWxlPSJzUkdCIElFQzYxOTY2LTIuMSIgeG1wTU06SW5zdGFuY2VJRD0ieG1wLmlpZDoxYjA0MDhjZi0xZGEyLTQ4Y2EtYTcyZi0yZWU2NDI2MjY5NDIiIHhtcE1NOkRvY3VtZW50SUQ9InhtcC5kaWQ6MWIwNDA4Y2YtMWRhMi00OGNhLWE3MmYtMmVlNjQyNjI2OTQyIiB4bXBNTTpPcmlnaW5hbERvY3VtZW50SUQ9InhtcC5kaWQ6MWIwNDA4Y2YtMWRhMi00OGNhLWE3MmYtMmVlNjQyNjI2OTQyIj4gPHhtcE1NOkhpc3Rvcnk+IDxyZGY6U2VxPiA8cmRmOmxpIHN0RXZ0OmFjdGlvbj0iY3JlYXRlZCIgc3RFdnQ6aW5zdGFuY2VJRD0ieG1wLmlpZDoxYjA0MDhjZi0xZGEyLTQ4Y2EtYTcyZi0yZWU2NDI2MjY5NDIiIHN0RXZ0OndoZW49IjIwMjEtMTEtMDhUMTY6MzQ6NTItMDU6MDAiIHN0RXZ0OnNvZnR3YXJlQWdlbnQ9IkFkb2JlIFBob3Rvc2hvcCAyMi40IChNYWNpbnRvc2gpIi8+IDwvcmRmOlNlcT4gPC94bXBNTTpIaXN0b3J5PiA8L3JkZjpEZXNjcmlwdGlvbj4gPC9yZGY6UkRGPiA8L3g6eG1wbWV0YT4gPD94cGFja2V0IGVuZD0iciI/Prb0m48AAADXSURBVHja7dNBDQAgDATBlvDFFH/UEoxhAHQ0mVVwzaT55orSnV16fgsBACAAAAQAgAAAEAAAAgBAAAAIAAABACAAAAQAgAAAEAAAAgBAAAAIAAABACAAAAQAgAAAEAAAAgBAAAAIAAABACAAAAQAgAAAEAAAAgBAAAAoMsYrfUC/6QMEAIAAABAAAAIAQAAACAAAAQAgAAAEAIAAABAAAAIAQAAACAAAAQAAQAAACAAAAQAgAAAEAIAAABAAAAIAQAAACAAAAQAgAAAEAIAAABAAAAJQvQ+cFwX4GCJDYQAAAABJRU5ErkJggg==\"\n")
    }
    
}
