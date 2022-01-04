import XCTest
//@testable import Pamphlet
import PamphletFramework

final class PamphletTests: XCTestCase {
        
    /*
    func testProcessSOPedia() {
        PamphletFramework().process(prefix: "SOPedia",
                                    extensions: [],
                                    inDirectory: "/Volumes/Development/Development/chimerasw2/SOPedia/Resources",
                                    outDirectory: "/Volumes/Development/Development/chimerasw2/SOPedia/Sources/SOPediaPamphlet",
                                    options:PamphletOptions.default)
    }
    
    func testProcessSO() {
        PamphletFramework().process(prefix: nil,
                                    extensions: [],
                                    inDirectory: "/Volumes/Development/Development/chimerasw2/starbaseorion10/Server/Resources",
                                    outDirectory: "/Volumes/Development/Development/chimerasw2/starbaseorion10/Server/Sources/Pamphlet",
                                    options:PamphletOptions.default)
    }
    */
    
    func testProcess() {
        let extensions = ["json", "ts", "txt", "md", "html", "htm", "js", "css", "png", "jpg"]
        PamphletFramework().process(prefix: nil,
                                    extensions: extensions,
                                    inDirectory: "/Volumes/Development/Development/chimerasw2/Pamphlet/meta/test",
                                    outDirectory: "/tmp/Pamphlet",
                                    options:PamphletOptions.default)
    }
    
    func testProcessKotlin() {
        let extensions = ["json", "ts", "txt", "md", "html", "htm", "js", "css", "png", "jpg"]
        PamphletFramework().process(prefix: nil,
                                    extensions: extensions,
                                    inDirectory: "/Volumes/Development/Development/chimerasw2/Pamphlet/meta/test",
                                    outDirectory: "/tmp/Pamphlet",
                                    options:[.swiftpm, .includeOriginal, .includeGzip, .minifyHtml, .minifyJs, .minifyTs, .minifyJson, .kotlin])
    }
    
    func testProcessCollpased() {
        let extensions = ["json", "ts", "txt", "md", "html", "htm", "js", "css", "png", "jpg"]
        PamphletFramework().process(prefix: nil,
                                    extensions: extensions,
                                    inDirectory: "/Volumes/Development/Development/chimerasw2/Pamphlet/meta/test",
                                    outDirectory: "/tmp/Pamphlet",
                                    options:[.clean, .collapse, .swiftpm, .includeOriginal, .includeGzip, .minifyHtml, .minifyJs, .minifyTs, .minifyJson])
    }
    
    func testProcessReleaseOnly() {
        let extensions = ["json", "ts", "txt", "md", "html", "htm", "js", "css", "png", "jpg"]
        PamphletFramework().process(prefix: "Release",
                                    extensions: extensions,
                                    inDirectory: "/Volumes/Development/Development/chimerasw2/Pamphlet/meta/test",
                                    outDirectory: "/tmp/Pamphlet",
                                    options:PamphletOptions.default)
    }
    
    func testPreprocessFollow1() {
        let result = PamphletFramework().preprocess("/Volumes/Development/Development/chimerasw2/Pamphlet/meta/includeFollow1.css")
                
        XCTAssertEqual(result, "#Follow3 { }\n#Follow2 { }\n#Follow1 { }\n")
    }
    
    func testPreprocess1() {
        
        let result = PamphletFramework().preprocess("/Volumes/Development/Development/chimerasw2/Pamphlet/meta/test1.html")
        
        XCTAssertEqual(result, "\"'Hello dog!''Hello cat!''Hello pineapple!''Hello world!'\"\n")
    }
    
    func testPreprocess2() {
        
        let result = PamphletFramework().preprocess("/Volumes/Development/Development/chimerasw2/Pamphlet/meta/test2.html")
        
        XCTAssertEqual(result, "\"Lorem ipsum dolor sit amet,\nconsectetur adipiscing elit,\nsed do eiusmod tempor incididunt\nut labore et dolore magna aliqua.\"\n")
    }
    
    func testNotAValidPreprocessingToken() {
        
        let result = PamphletFramework().preprocess("/Volumes/Development/Development/chimerasw2/Pamphlet/meta/test2.js")
                
        XCTAssertEqual(result, "\n\nvar x = 5\n`width:${x}em;height:${x}em;`\n")
    }
    
    func testPreprocessUnknownDirective() {
        let result = PamphletFramework().preprocess("/Volumes/Development/Development/chimerasw2/Pamphlet/meta/test1.css")
        XCTAssertEqual(result, "\n#title {\n    border-image-slice: 22 fill;\n}\n")
    }
    
    func testPreprocessIncludeFromSourcePath() {
        let result = PamphletFramework().preprocess("/Volumes/Development/Development/chimerasw2/Pamphlet/meta/include1.css")
        XCTAssertEqual(result, "\n#title {\n    border-image-slice: 22 fill;\n}\n\n#title {\n    border-image-slice: 22 fill;\n}\n")
    }
    
    func testPreprocessImageFile() {
        let result = PamphletFramework().preprocess("/Volumes/Development/Development/chimerasw2/Pamphlet/meta/include_image.js")
        XCTAssertEqual(result, "\nlet icon_png = \"iVBORw0KGgoAAAANSUhEUgAAAIAAAACACAIAAABMXPacAAAACXBIWXMAAAsTAAALEwEAmpwYAAAFG2lUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4gPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgNi4wLWMwMDYgNzkuZGFiYWNiYiwgMjAyMS8wNC8xNC0wMDozOTo0NCAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bWxuczpkYz0iaHR0cDovL3B1cmwub3JnL2RjL2VsZW1lbnRzLzEuMS8iIHhtbG5zOnBob3Rvc2hvcD0iaHR0cDovL25zLmFkb2JlLmNvbS9waG90b3Nob3AvMS4wLyIgeG1sbnM6eG1wTU09Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9tbS8iIHhtbG5zOnN0RXZ0PSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvc1R5cGUvUmVzb3VyY2VFdmVudCMiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIDIyLjQgKE1hY2ludG9zaCkiIHhtcDpDcmVhdGVEYXRlPSIyMDIxLTExLTA4VDE2OjM0OjUyLTA1OjAwIiB4bXA6TW9kaWZ5RGF0ZT0iMjAyMS0xMS0wOFQxNzoxOTozMS0wNTowMCIgeG1wOk1ldGFkYXRhRGF0ZT0iMjAyMS0xMS0wOFQxNzoxOTozMS0wNTowMCIgZGM6Zm9ybWF0PSJpbWFnZS9wbmciIHBob3Rvc2hvcDpDb2xvck1vZGU9IjMiIHBob3Rvc2hvcDpJQ0NQcm9maWxlPSJzUkdCIElFQzYxOTY2LTIuMSIgeG1wTU06SW5zdGFuY2VJRD0ieG1wLmlpZDoxYjA0MDhjZi0xZGEyLTQ4Y2EtYTcyZi0yZWU2NDI2MjY5NDIiIHhtcE1NOkRvY3VtZW50SUQ9InhtcC5kaWQ6MWIwNDA4Y2YtMWRhMi00OGNhLWE3MmYtMmVlNjQyNjI2OTQyIiB4bXBNTTpPcmlnaW5hbERvY3VtZW50SUQ9InhtcC5kaWQ6MWIwNDA4Y2YtMWRhMi00OGNhLWE3MmYtMmVlNjQyNjI2OTQyIj4gPHhtcE1NOkhpc3Rvcnk+IDxyZGY6U2VxPiA8cmRmOmxpIHN0RXZ0OmFjdGlvbj0iY3JlYXRlZCIgc3RFdnQ6aW5zdGFuY2VJRD0ieG1wLmlpZDoxYjA0MDhjZi0xZGEyLTQ4Y2EtYTcyZi0yZWU2NDI2MjY5NDIiIHN0RXZ0OndoZW49IjIwMjEtMTEtMDhUMTY6MzQ6NTItMDU6MDAiIHN0RXZ0OnNvZnR3YXJlQWdlbnQ9IkFkb2JlIFBob3Rvc2hvcCAyMi40IChNYWNpbnRvc2gpIi8+IDwvcmRmOlNlcT4gPC94bXBNTTpIaXN0b3J5PiA8L3JkZjpEZXNjcmlwdGlvbj4gPC9yZGY6UkRGPiA8L3g6eG1wbWV0YT4gPD94cGFja2V0IGVuZD0iciI/Prb0m48AAADXSURBVHja7dNBDQAgDATBlvDFFH/UEoxhAHQ0mVVwzaT55orSnV16fgsBACAAAAQAgAAAEAAAAgBAAAAIAAABACAAAAQAgAAAEAAAAgBAAAAIAAABACAAAAQAgAAAEAAAAgBAAAAIAAABACAAAAQAgAAAEAAAAgBAAAAoMsYrfUC/6QMEAIAAABAAAAIAQAAACAAAAQAgAAAEAIAAABAAAAIAQAAACAAAAQAAQAAACAAAAQAgAAAEAIAAABAAAAIAQAAACAAAAQAgAAAEAIAAABAAAAJQvQ+cFwX4GCJDYQAAAABJRU5ErkJggg==\"\n")
    }
    
    func testPreprocessFileDateCompareWithIncludes() {
        let extensions = ["txt", "md", "html", "htm", "js", "css", "png", "jpg"]
        PamphletFramework().process(prefix: nil,
                                    extensions: extensions,
                                    inDirectory: "/Volumes/Development/Development/chimerasw2/Pamphlet/meta",
                                    outDirectory: "/tmp/Pamphlet",
                                    options:PamphletOptions.default)
    }
    

    static var allTests = [
        ("testProcess", testProcess),
        ("testPreprocess1", testPreprocess1),
        ("testPreprocessUnknownDirective", testPreprocessUnknownDirective),
        ("testPreprocessIncludeFromSourcePath", testPreprocessIncludeFromSourcePath),
    ]
}
