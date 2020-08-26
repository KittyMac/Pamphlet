import XCTest
@testable import Pamphlet
import PamphletFramework

final class PamphletTests: XCTestCase {
    
    func testProcess() {
        let extensions = ["txt", "md", "html", "htm", "js", "css", "png", "jpg"]
        PamphletFramework().process(extensions,
                                    "/Volumes/Development/Development/chimerasw2/Pamphlet/meta/test",
                                    "/tmp")
    }
    

    static var allTests = [
        ("testProcess", testProcess),
    ]
}
