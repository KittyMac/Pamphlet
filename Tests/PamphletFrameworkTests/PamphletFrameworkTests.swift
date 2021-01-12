import XCTest
@testable import Pamphlet
import PamphletFramework

final class PamphletTests: XCTestCase {
    
    func testProcessRandom() {
        PamphletFramework().process(prefix: nil,
                                    extensions: [],
                                    inDirectory: "/Volumes/Development/Development/smallplanet/planetios/npd_ReceiptPal/receiptpal_amazon/iOS/Scrape/Resources",
                                    outDirectory: "/Volumes/Development/Development/smallplanet/planetios/npd_ReceiptPal/receiptpal_amazon/iOS/Scrape/Sources/Pamphlet",
                                    options: [.clean, .releaseOnly, .includeGzip])
    }
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
