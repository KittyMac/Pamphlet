import Foundation
import libmcpp
import Gzip

extension PamphletFramework {
    func gzip(path: FilePath,
              contents: String) -> String? {
        if includeGzip(for: path.fileName) {
            let ext = URL(fileURLWithPath: path.fullPath).pathExtension
            
            if let fileContentsAsData = contents.data(using: .utf8) {
                let not = [
                    "zip", "gzip", "gz", "lz", "br", "bz2", "lz4", "lzo", "lzma", "sz", "z", "xz", "Z", "7z", "tgz", "dmg"
                ]
                if not.contains(ext) {
                    return fileContentsAsData.base64EncodedString()
                }
                
                var gzipLevel: CompressionLevel = .bestCompression
                if let level = compressionLevel(for: path.fileName) {
                    #if os(Windows)
                    gzipLevel = CompressionLevel(rawValue: Int32(level)) ?? .bestCompression
                    #else
                    gzipLevel = CompressionLevel(rawValue: Int32(level))
                    #endif
                }
                
                if let fileContentsAsGzip = try? fileContentsAsData.gzipped(level: gzipLevel) {
                    return fileContentsAsGzip.base64EncodedString()
                }
            }
            
            fatalError("Failed to compress the requested file")
        }
        return nil
    }
}
