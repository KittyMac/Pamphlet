import Foundation
import Ipecac
import libmcpp

let stringTemplate = ####"""
import Foundation

// swiftlint:disable all

public extension {?} {
    static func {?}() -> String {
#if DEBUG
let filePath = "{?}"
if let contents = try? String(contentsOfFile:filePath) {
    if contents.hasPrefix("#define PAMPHLET_PREPROCESSOR") {
        do {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/local/bin/pamphlet")
            task.arguments = ["preprocess", filePath]
            let outputPipe = Pipe()
            task.standardOutput = outputPipe
            try task.run()
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(decoding: outputData, as: UTF8.self)
            return output
        } catch {
            return "Failed to use /usr/local/bin/pamphlet to preprocess the requested file"
        }
    }
    return contents
}
return "file not found"
#else
return ###"""
{?}
"""###
#endif
}
}
"""####

private let dataTemplate = ####"""
import Foundation

// swiftlint:disable all

public extension {?} {
    static func {?}() -> Data {
#if DEBUG
if let contents = try? Data(contentsOf:URL(fileURLWithPath: "{?}")) {
    return contents
}
return Data()
#else
return data!
#endif
}
}

private let data = Data(base64Encoded:"{?}")
"""####

private let compressedTemplate = ####"""

public extension {?} {
    static func {?}Gzip() -> Data {
        return gzip_data!
    }
}

private let gzip_data = Data(base64Encoded:"{?}")
"""####

private func toVariableName(_ source: String) -> String {
    var scratch = ""
    scratch.reserveCapacity(source.count)
    var capitalize = true
    for c in source {
        if c == "." || c == "/" {
            capitalize = true
        } else {
            if capitalize {
                scratch.append(c.uppercased())
                capitalize = false
            } else {
                scratch.append(c)
            }
        }
    }
    return scratch
}

struct FilePath {
    let fullPath: String
    let parts: [String]
    let fileName: String
    let fullVariableName: String
    let variableName: String
    let swiftFileName: String
    let extensionName: String
    let parentExtensionName: String
    let myStructName: String
    
    init(_ inPath: String) {
        var path = inPath
        if path.hasPrefix("/") == false {
            path = "/" + path
        }
        
        let pathParts = path.components(separatedBy: "/").filter { $0.count > 0 }
        
        fullPath = path
        parts = pathParts.map { toVariableName($0) }
        
        fileName = pathParts.last!
        
        // swift file name
        var scratch = ""
        scratch.append("Pamphlet+")
        for part in parts {
            if part.count > 0 {
                scratch.append(part)
                scratch.append("+")
            }
        }
        scratch.removeLast()
        scratch.append(".swift")
        swiftFileName = scratch
        
        // variable name
        variableName = toVariableName(fileName)
        
        // extensionName
        scratch.removeAll(keepingCapacity: true)
        scratch.append("Pamphlet.")
        for part in parts.dropLast() {
            scratch.append(part)
            scratch.append(".")
        }
        scratch.removeLast()
        extensionName = scratch
        
        // parentExtensionName
        scratch.removeAll(keepingCapacity: true)
        scratch.append("Pamphlet.")
        for part in parts.dropLast().dropLast() {
            scratch.append(part)
            scratch.append(".")
        }
        scratch.removeLast()
        parentExtensionName = scratch
        
        // myStructName
        if let myStructPart = parts.dropLast().last {
            myStructName = toVariableName(myStructPart)
        } else {
            myStructName = ""
        }
        
        // fullVariableName
        scratch.removeAll(keepingCapacity: true)
        scratch.append("Pamphlet.")
        for part in parts.dropLast() {
            scratch.append(part)
            scratch.append(".")
        }
        scratch.append(variableName)
        fullVariableName = scratch
    }
    
    private func fileNameToVariableName(_ fileName: String) -> String {
        
        return variableName
    }
}

public struct PamphletFramework {
    
    public init() {
        
    }
    
    
    
    private func createPamphletFile(_ textPages: [FilePath], _ dataPages: [FilePath], _ outFile: String) {
        
        var allDirectoryExtensions = ""
        for page in (textPages + dataPages) {
            if page.parts.count > 1 {
                let template = ####"""
                public extension {?} { enum {?} { } }
                
                """####
                let code = String(ipecac: template,
                                  page.parentExtensionName,
                                  page.myStructName)
                if allDirectoryExtensions.contains(code) == false {
                    allDirectoryExtensions.append(code)
                }
            }
        }
        
        
        
        let template = ####"""
        import Foundation
        
        // swiftlint:disable all
        
        public enum Pamphlet {
            public static func get(string member: String) -> String? {
                switch member {
        {?}
                default: break
                }
                return nil
            }
            public static func get(gzip member: String) -> Data? {
                #if DEBUG
                    return nil
                #else
                    switch member {
        {?}
                    default: break
                    }
                    return nil
                #endif
            }
            public static func get(data member: String) -> Data? {
                switch member {
        {?}
                default: break
                }
                return nil
            }
        }
        {?}
        """####
        let textPagesCode = textPages.map { "        case \"\($0.fullPath)\": return \($0.fullVariableName)()" }.joined(separator: "\n")
        let compressedPagesCode = textPages.map { "            case \"\($0.fullPath)\": return \($0.fullVariableName)Gzip()" }.joined(separator: "\n")
        let dataPagesCode = dataPages.map { "        case \"\($0.fullPath)\": return \($0.fullVariableName)()" }.joined(separator: "\n")
        do {
            let swift = String(ipecac: template,
                               textPagesCode,
                               compressedPagesCode,
                               dataPagesCode,
                               allDirectoryExtensions)
            try swift.write(toFile: outFile, atomically: true, encoding: .utf8)
        } catch {
            fatalError("Processing failed for file: \(outFile)")
        }
    }
    
    private func processTextFile(_ shouldSkip: Bool, _ path: FilePath, _ inFile: String, _ outFile: String) -> Bool {
        
        do {
            
            var uncompressedString = ""
            var compressedString = ""
            
            var fileContents = try String(contentsOfFile: inFile)
            
            if shouldSkip == false {
                if fileContents.hasPrefix("#define PAMPHLET_PREPROCESSOR") {
                    // This file wants to use the mcpp preprocessor
                    if let cPtr = mcpp_preprocessFile(inFile) {
                        fileContents = String(cString: cPtr)
                        free(cPtr)
                    }
                }
                
                if inFile.hasSuffix(".css") ||
                    inFile.hasSuffix(".html") &&
                    FileManager.default.fileExists(atPath: "/usr/local/bin/htmlcompressor") {
                    // If this is a javascript file and closure-compiler is installed
                    do {
                        let task = Process()
                        task.executableURL = URL(fileURLWithPath: "/usr/local/bin/htmlcompressor")
                        let inputPipe = Pipe()
                        let outputPipe = Pipe()
                        task.standardInput = inputPipe
                        task.standardOutput = outputPipe
                        task.standardError = nil
                        try task.run()
                        if let fileContentsAsData = fileContents.data(using: .utf8) {
                            inputPipe.fileHandleForWriting.write(fileContentsAsData)
                            inputPipe.fileHandleForWriting.closeFile()
                            let minifiedData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                            
                            fileContents = String(data: minifiedData, encoding: .utf8) ?? fileContents
                        } else {
                            throw ""
                        }
                    } catch {
                        fatalError("Failed to use /usr/local/bin/htmlcompressor to compress the requested file")
                    }
                }
                
                if inFile.hasSuffix(".js") &&
                    FileManager.default.fileExists(atPath: "/usr/local/bin/closure-compiler") {
                    // If this is a javascript file and closure-compiler is installed
                    do {
                        let task = Process()
                        task.executableURL = URL(fileURLWithPath: "/usr/local/bin/closure-compiler")
                        let inputPipe = Pipe()
                        let outputPipe = Pipe()
                        task.standardInput = inputPipe
                        task.standardOutput = outputPipe
                        task.standardError = nil
                        try task.run()
                        if let fileContentsAsData = fileContents.data(using: .utf8) {
                            inputPipe.fileHandleForWriting.write(fileContentsAsData)
                            inputPipe.fileHandleForWriting.closeFile()
                            let minifiedData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                            
                            fileContents = String(data: minifiedData, encoding: .utf8) ?? fileContents
                        } else {
                            throw ""
                        }
                    } catch {
                        fatalError("Failed to use /usr/local/bin/closure-compiler to compress the requested file")
                    }
                }
                
                
                do {
                    let task = Process()
                    task.executableURL = URL(fileURLWithPath: "/usr/bin/gzip")
                    task.arguments = ["-9", "-n"]
                    let inputPipe = Pipe()
                    let outputPipe = Pipe()
                    task.standardInput = inputPipe
                    task.standardOutput = outputPipe
                    task.standardError = nil
                    try task.run()
                    if let fileContentsAsData = fileContents.data(using: .utf8) {
                        inputPipe.fileHandleForWriting.write(fileContentsAsData)
                        inputPipe.fileHandleForWriting.closeFile()
                        let compressedData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                        
                        compressedString = String(ipecac: compressedTemplate,
                                           path.extensionName,
                                           path.variableName,
                                           compressedData.base64EncodedString())
                        
                        
                    } else {
                        throw ""
                    }
                } catch {
                    fatalError("Failed to use /usr/bin/gzip to compress the requested file")
                }
                
                uncompressedString = String(ipecac: stringTemplate,
                                            path.extensionName,
                                            path.variableName,
                                            inFile,
                                            fileContents)
                
                
                let swift = uncompressedString + "\n\n" + compressedString
                
                try swift.write(toFile: outFile, atomically: true, encoding: .utf8)
            }
        } catch {
            return false
        }
        return true
    }
    
    private func processDataFile(_ shouldSkip: Bool, _ path: FilePath, _ inFile: String, _ outFile: String) -> Bool {
        if shouldSkip {
            return true
        }
        
        do {
            let fileData = try Data(contentsOf: URL(fileURLWithPath: inFile))
            let swift = String(ipecac: dataTemplate,
                               path.extensionName,
                               path.variableName,
                               inFile,
                               fileData.base64EncodedString())
            try swift.write(toFile: outFile, atomically: true, encoding: .utf8)
        } catch {
            return false
        }
        return true
    }
    
    private func processPackageSwift(_ outFile: String) -> Bool {
        let template = ####"""
        // swift-tools-version:5.2
        import PackageDescription
        let package = Package(
            name: "Pamphlet",
            products: [
                .library(name: "Pamphlet", targets: ["Pamphlet"])
            ],
            targets: [
                .target(
                    name: "Pamphlet"
                )
            ]
        )
        """####
        
        do {
            try template.write(toFile: outFile, atomically: true, encoding: .utf8)
        } catch {
            return false
        }
        return true
    }
    
    private func removeOldFiles(_ inDirectory: String,
                                _ outDirectory: String,
                                _ removeAll: Bool) {
                
        let resourceKeys: [URLResourceKey] = [.isDirectoryKey]
        if let enumerator = FileManager.default.enumerator(at: URL(fileURLWithPath: outDirectory),
                                                        includingPropertiesForKeys: resourceKeys,
                                                        options: [.skipsHiddenFiles],
                                                        errorHandler: { (url, error) -> Bool in
                                                            print("directoryEnumerator error at \(url): ", error)
                                                            return true
        }) {
        
            for case let fileURL as URL in enumerator {
                do {
                    let resourceValues = try fileURL.resourceValues(forKeys: Set(resourceKeys))
                    let fileName = fileURL.lastPathComponent
                    if fileName.hasSuffix(".swift") && resourceValues.isDirectory == false {
                        let outPath = fileURL.path
                        let fullOutDirectory = URL(fileURLWithPath: outDirectory).path
                        
                        if removeAll {
                            try? FileManager.default.removeItem(at: fileURL)
                        }else{
                            if let outRange = outPath.range(of: fullOutDirectory) {
                                let inPath = inDirectory + outPath.suffix(from: outRange.upperBound).dropLast(6)
                                
                                if FileManager.default.fileExists(atPath: String(inPath)) == false {
                                    try? FileManager.default.removeItem(at: fileURL)
                                }
                            } else {
                                try? FileManager.default.removeItem(at: fileURL)
                            }
                        }
                    }
                } catch {
                        
                }
            }
        }
    }
    
    @discardableResult
    public func preprocess(_ inFile: String) -> String {
        var result: String = ""
        do {
            var fileContents = try String(contentsOfFile: inFile)
            
            if fileContents.hasPrefix("#define PAMPHLET_PREPROCESSOR") {
                if let cPtr = mcpp_preprocessFile(inFile) {
                    fileContents = String(cString: cPtr)
                    free(cPtr)
                }
            }
            
            result = fileContents
        } catch {
            result = "unable to parse file"
        }
        print(result)
        return result
    }
    
    public func process(_ extensions: [String],
                        _ inDirectory: String,
                        _ outDirectory: String,
                        _ swiftpm: Bool,
                        _ clean: Bool) {
        
        let resourceKeys: [URLResourceKey] = [.contentModificationDateKey, .creationDateKey, .isDirectoryKey]
        var generateFilesDirectory = outDirectory
        
        let pamphletExecPath = ProcessInfo.processInfo.arguments[0]
        guard let pamphletExecPathValues = try? URL(fileURLWithPath: pamphletExecPath).resourceValues(forKeys: Set(resourceKeys)) else { fatalError() }
        
        try? FileManager.default.createDirectory(atPath: generateFilesDirectory, withIntermediateDirectories: true, attributes: nil)
        
        if swiftpm {
            // We assume that the output directory is where we want the Package.swft,
            // so we need to create the Sources/ and Sources/Pamphlet directories
            // and store the generated files in there
            generateFilesDirectory = outDirectory + "/Sources/Pamphlet"
            try? FileManager.default.createDirectory(atPath: generateFilesDirectory, withIntermediateDirectories: true, attributes: nil)
            
            // Generate a Package.swift
            let packageSwiftPath = outDirectory + "/Package.swift"
            if !processPackageSwift(packageSwiftPath) {
                fatalError("Unable to create Package.swift at \(packageSwiftPath)")
            }
        }
        
        
        removeOldFiles(inDirectory, generateFilesDirectory, clean)
        
        let enumerator = FileManager.default.enumerator(at: URL(fileURLWithPath: inDirectory),
                                                        includingPropertiesForKeys: resourceKeys,
                                                        options: [.skipsHiddenFiles],
                                                        errorHandler: { (url, error) -> Bool in
                                                            print("directoryEnumerator error at \(url): ", error)
                                                            return true
        })!
        
        var textPages: [FilePath] = []
        var dataPages: [FilePath] = []
        
        //print("in: " + inDirectory)
        //print("out: " + generateFilesDirectory)
        
        let inDirectoryFullPath = URL(fileURLWithPath: inDirectory).path

        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: Set(resourceKeys))
                let pathExtension = (fileURL.path as NSString).pathExtension
                if (extensions.count == 0 || extensions.contains(pathExtension)) &&
                    resourceValues.isDirectory == false {
                    let partialPath = String(fileURL.path.dropFirst(inDirectoryFullPath.count))
                    let filePath = FilePath(partialPath)
                    
                    let outputDirectory = URL(fileURLWithPath: generateFilesDirectory + "/" + partialPath).deletingLastPathComponent().path
                    let outputFile = "\(outputDirectory)/\(filePath.fileName).swift"
                    try? FileManager.default.createDirectory(atPath: outputDirectory, withIntermediateDirectories: true, attributes: nil)
                    
                    var shouldSkip = false
                    if let outResourceValues = try? URL(fileURLWithPath: outputFile).resourceValues(forKeys: Set(resourceKeys)) {
                        shouldSkip = (resourceValues.contentModificationDate! <= outResourceValues.contentModificationDate! &&
                            pamphletExecPathValues.contentModificationDate! <= outResourceValues.contentModificationDate!)
                    }
                    
                    if !processTextFile(shouldSkip, filePath, fileURL.path, outputFile) {
                        if !processDataFile(shouldSkip, filePath, fileURL.path, outputFile) {
                            fatalError("Processing failed for file: \(fileURL.path)")
                        } else {
                            dataPages.append(filePath)
                        }
                    } else {
                        textPages.append(filePath)
                    }
                }
            } catch {
                
            }
        }
        
        createPamphletFile(textPages, dataPages, generateFilesDirectory + "/Pamphlet.swift")
    }
    
}
