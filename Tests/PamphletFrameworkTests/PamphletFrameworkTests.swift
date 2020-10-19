import XCTest
@testable import Pamphlet
import PamphletFramework

final class PamphletTests: XCTestCase {
    
    func testProcess() {
        let extensions = ["txt", "md", "html", "htm", "js", "css", "png", "jpg"]
        PamphletFramework().process(extensions,
                                    "/Volumes/Development/Development/chimerasw2/Pamphlet/meta/test",
                                    "/tmp/Pamphlet",
                                    true,
                                    true)
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
        PamphletFramework().process(extensions,
                                    "/Volumes/Development/Development/chimerasw2/Pamphlet/meta",
                                    "/tmp/Pamphlet",
                                    true,
                                    false)
    }
    

    static var allTests = [
        ("testProcess", testProcess),
        ("testPreprocess1", testPreprocess1),
        ("testPreprocessUnknownDirective", testPreprocessUnknownDirective),
        ("testPreprocessIncludeFromSourcePath", testPreprocessIncludeFromSourcePath),
    ]
}
