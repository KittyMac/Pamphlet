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
    
    func testPreprocess2() {
        //XCTAssertEqual(result, "\n\n\"'Hello dog!''Hello cat!''Hello pineapple!''Hello world!'\"\n")
    }
    

    static var allTests = [
        ("testProcess", testProcess),
        ("testPreprocess1", testPreprocess1),
        ("testPreprocess2", testPreprocess2),
    ]
}
