import Foundation
import Ipecac

public struct PamphletFramework {
    
    public init() {
        
    }
    
    private func fileNameToVariableName(_ fileName: String) -> String {
        return fileName.replacingOccurrences(of: ".", with: "_")
    }
    
    private func createPamphletFile(_ pages: [String], _ outFile: String) {
        let template = ####"""
        // swiftlint:disable all
        
        @dynamicMemberLookup
        public enum Pamphlet {
            static subscript(dynamicMember member: String) -> String? {
                switch member {
        {0}
                default: break
                }
                return nil
            }
        }
        """####
        let pagesCode = pages.map { "        case \"/\($0)\": return \(fileNameToVariableName($0))()" }.joined(separator: "\n")
        do {
            let swift = String(ipecac: template, pagesCode)
            try swift.write(toFile: outFile, atomically: true, encoding: .utf8)
        } catch {
            fatalError("Processing failed for file: \(outFile)")
        }
    }
    
    private func processFile(_ variableName: String, _ inFile: String, _ outFile: String) {
        let template = ####"""
        // swiftlint:disable all
        
        public extension Pamphlet {
            static func {0}() -> String {
        #if DEBUG
        if let contents = try? String(contentsOfFile:"{2}") {
            return contents
        }
        return "file not found"
        #else
        return ###"""
        {1}
        """###
        #endif
        }
        }
        """####
        do {
            let swift = String(ipecac: template, variableName, try String(contentsOfFile: inFile), inFile)
            try swift.write(toFile: outFile, atomically: true, encoding: .utf8)
        } catch {
            fatalError("Processing failed for file: \(inFile)")
        }
    }
    
    public func process(_ extensions: [String], _ inDirectory: String, _ outDirectory: String) {        
        let resourceKeys: [URLResourceKey] = [.creationDateKey, .isDirectoryKey]
        let enumerator = FileManager.default.enumerator(at: URL(fileURLWithPath: inDirectory),
                                                        includingPropertiesForKeys: resourceKeys,
                                                        options: [.skipsHiddenFiles],
                                                        errorHandler: { (url, error) -> Bool in
                                                            print("directoryEnumerator error at \(url): ", error)
                                                            return true
        })!
        
        var pages: [String] = []

        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: Set(resourceKeys))
                let pathExtension = (fileURL.path as NSString).pathExtension
                if extensions.contains(pathExtension) && resourceValues.isDirectory == false {
                    let fileName = fileURL.lastPathComponent
                    processFile(fileNameToVariableName(fileName), fileURL.path, outDirectory + "/Pamphlet+" + fileName + ".swift")
                    
                    pages.append(fileName)
                }
            } catch {
                    
            }
        }
        
        createPamphletFile(pages, outDirectory + "/Pamphlet.swift")
    }
    
}
