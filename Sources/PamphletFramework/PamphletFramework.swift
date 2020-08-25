import Foundation
import Ipecac

public struct PamphletFramework {
    
    public init() {
        
    }
    
    private func fileNameToVariableName(_ fileName: String) -> String {
        return fileName.replacingOccurrences(of: ".", with: "_")
    }
    
    private func createPamphletFile(_ textPages: [String], _ dataPages: [String], _ outFile: String) {
        let template = ####"""
        import Foundation
        
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
            static subscript(dynamicMember member: String) -> Data? {
                switch member {
        {1}
                default: break
                }
                return nil
            }
        }
        """####
        let textPagesCode = textPages.map { "        case \"/\($0)\": return \(fileNameToVariableName($0))()" }.joined(separator: "\n")
        let dataPagesCode = dataPages.map { "        case \"/\($0)\": return \(fileNameToVariableName($0))()" }.joined(separator: "\n")
        do {
            let swift = String(ipecac: template, textPagesCode, dataPagesCode)
            try swift.write(toFile: outFile, atomically: true, encoding: .utf8)
        } catch {
            fatalError("Processing failed for file: \(outFile)")
        }
    }
    
    private func processTextFile(_ variableName: String, _ inFile: String, _ outFile: String) -> Bool {
        let template = ####"""
        import Foundation
        
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
            return false
        }
        return true
    }
    
    private func processDataFile(_ variableName: String, _ inFile: String, _ outFile: String) -> Bool {
        let template = ####"""
        import Foundation
        
        // swiftlint:disable all
        
        public extension Pamphlet {
            static func {0}() -> Data {
        #if DEBUG
        if let contents = try? Data(contentsOf:URL(fileURLWithPath: "{2}")) {
            return contents
        }
        return Data()
        #else
        return data!
        #endif
        }
        }
        
        private let data = Data(base64Encoded:"{1}")
        """####
        
        do {
            let fileData = try Data(contentsOf: URL(fileURLWithPath: inFile))
            let swift = String(ipecac: template, variableName, fileData.base64EncodedString(), inFile)
            try swift.write(toFile: outFile, atomically: true, encoding: .utf8)
        } catch {
            return false
        }
        return true
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
        
        var textPages: [String] = []
        var dataPages: [String] = []

        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: Set(resourceKeys))
                let pathExtension = (fileURL.path as NSString).pathExtension
                if extensions.contains(pathExtension) && resourceValues.isDirectory == false {
                    let fileName = fileURL.lastPathComponent
                    
                    if !processTextFile(fileNameToVariableName(fileName), fileURL.path, outDirectory + "/Pamphlet+" + fileName + ".swift") {
                        if !processDataFile(fileNameToVariableName(fileName), fileURL.path, outDirectory + "/Pamphlet+" + fileName + ".swift") {
                            fatalError("Processing failed for file: \(fileURL.path)")
                        } else {
                            dataPages.append(fileName)
                        }
                    } else {
                        textPages.append(fileName)
                    }
                    
                    
                }
            } catch {
                    
            }
        }
        
        createPamphletFile(textPages, dataPages, outDirectory + "/Pamphlet.swift")
    }
    
}
