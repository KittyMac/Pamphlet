import XCTest
@testable import Pamphlet
import PamphletFramework

final class PamphletTests: XCTestCase {
    
    func testProcess() {
        let extensions = ["json", "ts", "txt", "md", "html", "htm", "js", "css", "png", "jpg"]
        PamphletFramework().process(nil,
                                    extensions,
                                    "/Volumes/Development/Development/chimerasw2/Pamphlet/meta/test",
                                    "/tmp/Pamphlet",
                                    true,
                                    true,
                                    false)
    }
    
    func testProcessReleaseOnly() {
        let extensions = ["json", "ts", "txt", "md", "html", "htm", "js", "css", "png", "jpg"]
        PamphletFramework().process("Release",
                                    extensions,
                                    "/Volumes/Development/Development/chimerasw2/Pamphlet/meta/test",
                                    "/tmp/Pamphlet",
                                    true,
                                    true,
                                    true)
    }
    
    func testPreprocessFollow1() {
        let result = PamphletFramework().preprocess("/Volumes/Development/Development/chimerasw2/Pamphlet/meta/includeFollow1.css")
                
        XCTAssertEqual(result, "\n\n\n\n\n\n#Follow3 { }\n\n#Follow2 { }\n\n#Follow1 { }\n")
    }
    
    func testPreprocess1() {
        
        let result = PamphletFramework().preprocess("/Volumes/Development/Development/chimerasw2/Pamphlet/meta/test1.html")
        
        XCTAssertEqual(result, "\n\n\"'Hello dog!''Hello cat!''Hello pineapple!''Hello world!'\"\n")
    }
    
    func testPreprocessUnknownDirective() {
        let result = PamphletFramework().preprocess("/Volumes/Development/Development/chimerasw2/Pamphlet/meta/test1.css")
        XCTAssertEqual(result, "\n\n\n\n#title {\n    border-image-slice: 22 fill;\n}\n")
    }
    
    func testPreprocessIncludeFromSourcePath() {
        let result = PamphletFramework().preprocess("/Volumes/Development/Development/chimerasw2/Pamphlet/meta/include1.css")
        XCTAssertEqual(result, "\n\n\n\n\n\n#title {\n    border-image-slice: 22 fill;\n}\n\n\n#title {\n    border-image-slice: 22 fill;\n}\n")
    }
    
    func testPreprocessFileDateCompareWithIncludes() {
        let extensions = ["txt", "md", "html", "htm", "js", "css", "png", "jpg"]
        PamphletFramework().process(nil,
                                    extensions,
                                    "/Volumes/Development/Development/chimerasw2/Pamphlet/meta",
                                    "/tmp/Pamphlet",
                                    true,
                                    false,
                                    false)
    }
    

    static var allTests = [
        ("testProcess", testProcess),
        ("testPreprocess1", testPreprocess1),
        ("testPreprocessUnknownDirective", testPreprocessUnknownDirective),
        ("testPreprocessIncludeFromSourcePath", testPreprocessIncludeFromSourcePath),
    ]
}
