import Foundation
import libmcpp
import Gzip

extension PamphletFramework {
    func gzip(path: FilePath,
              contents: String) -> String? {
        if options.contains(.includeGzip) && includeGzip(for: path.fileName) {
            let ext = URL(fileURLWithPath: path.fullPath).pathExtension
            
            if let fileContentsAsData = contents.data(using: .utf8) {
                let not = [
                    "zip", "gzip", "gz", "lz", "br", "bz2", "lz4", "lzo", "lzma", "sz", "z", "xz", "Z", "7z", "tgz", "dmg"
                ]
                if not.contains(ext) {
                    return fileContentsAsData.base64EncodedString()
                }
                
                if let fileContentsAsGzip = try? fileContentsAsData.gzipped(level: .bestCompression) {
                    return fileContentsAsGzip.base64EncodedString()
                }
            }
            
            fatalError("Failed to compress the requested file")
        }
        return nil
    }
}
