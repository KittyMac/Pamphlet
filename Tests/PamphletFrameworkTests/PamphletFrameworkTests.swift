import XCTest
@testable import Pamphlet
import PamphletFramework
import libmcpp

final class PamphletTests: XCTestCase {
    
    func testProcess() {
        let extensions = ["txt", "md", "html", "htm", "js", "css", "png", "jpg"]
        
        //mcpp_help()
        mcpp_preprocessFile("/Volumes/Development/Development/chimerasw2/starbaseorion10/Server/Resources/shell.html",
                            "/Volumes/Development/Development/chimerasw2/starbaseorion10/Server/Resources/shell2.html")
        
        PamphletFramework().process(extensions,
                                    "/Volumes/Development/Development/chimerasw2/Pamphlet/meta/test",
                                    "/tmp/Pamphlet",
                                    true,
                                    true)
    }
    

    static var allTests = [
        ("testProcess", testProcess),
    ]
}
