import Foundation
import libmcpp
import Gzip

extension PamphletFramework {
    func gzip(fileContents: String) -> String? {
        if options.contains(.includeGzip) {
            
            if let fileContentsAsData = fileContents.data(using: .utf8),
                let fileContentsAsGzip = try? fileContentsAsData.gzipped(level: .bestCompression) {
                return fileContentsAsGzip.base64EncodedString()
            }
            
            fatalError("Failed to compress the requested file")
        }
        return nil
    }
}
