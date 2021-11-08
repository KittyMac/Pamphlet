import Foundation
import Ipecac
import libmcpp

class JsonDirectory: Codable {
    var files:[String:String] = [:]
}

extension String {
    private func substring(with nsrange: NSRange) -> Substring? {
        guard let range = Range(nsrange, in: self) else { return nil }
        return self[range]
    }
    
    func matches(_ pattern: String, _ callback: @escaping ((NSTextCheckingResult, [String]) -> Void)) {
        do {
            let body = self
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let nsrange = NSRange(location: Int(0), length: Int(count))
            regex.enumerateMatches(in: body, options: [], range: nsrange) { (match, _, _) in
                guard let match = match else { return }

                var groups: [String] = []
                for iii in 0..<match.numberOfRanges {
                    if let groupString = body.substring(with: match.range(at: iii)) {
                        groups.append(String(groupString))
                    }
                }
                callback(match, groups)
            }
        } catch { }
    }
}

private func toVariableName(_ source: String) -> String {
    var scratch = ""
    scratch.reserveCapacity(source.count)
    var capitalize = true
    for c in source {
        if c == "." || c == "/" || c == "-" || c == "_" {
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
    
    init(_ pamphletName: String, _ inPath: String) {
        var path = inPath
        if path.hasPrefix("/") == false {
            path = "/" + path
        }
        
        let pathParts = path.components(separatedBy: "/").filter { $0.count > 0 }
        
        fullPath = path
        parts = pathParts.map { toVariableName($0) }
        
        fileName = pathParts.last ?? "Pamphlet"
        
        // swift file name
        var scratch = ""
        scratch.append("\(pamphletName)+")
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
        scratch.append("\(pamphletName).")
        for part in parts.dropLast() {
            scratch.append(part)
            scratch.append(".")
        }
        scratch.removeLast()
        extensionName = scratch
        
        // parentExtensionName
        scratch.removeAll(keepingCapacity: true)
        scratch.append("\(pamphletName).")
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
        scratch.append("\(pamphletName).")
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

public struct PamphletOptions: OptionSet {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static let clean = PamphletOptions(rawValue:  1 << 0)
    public static let swiftpm = PamphletOptions(rawValue:  1 << 1)
    public static let releaseOnly = PamphletOptions(rawValue:  1 << 2)
    public static let includeOriginal = PamphletOptions(rawValue:  1 << 3)
    public static let includeGzip = PamphletOptions(rawValue:  1 << 4)
    public static let minifyHtml = PamphletOptions(rawValue:  1 << 5)
    public static let minifyJs = PamphletOptions(rawValue:  1 << 6)
    public static let minifyTs = PamphletOptions(rawValue:  1 << 7)
    public static let minifyJson = PamphletOptions(rawValue:  1 << 8)
    public static let collapse = PamphletOptions(rawValue:  1 << 9)
    
    public static let `default`: PamphletOptions = [.swiftpm, .includeOriginal, .includeGzip, .minifyHtml, .minifyJs, .minifyTs, .minifyJson]
}

public class PamphletFramework {
    
    var options = PamphletOptions.default
    
    public init() {
        
    }
    
    
    
    private func createPamphletFile(_ pamphletName: String,
                                    _ inTextPages: [FilePath],
                                    _ inDataPages: [FilePath],
                                    _ outFile: String) {
        
        
        var allDirectoryExtensions = ""
        
        let textPages = inTextPages.sorted { (lhs, rhs) -> Bool in
            return lhs.fileName < rhs.fileName
        }
        
        let dataPages = inDataPages.sorted { (lhs, rhs) -> Bool in
            return lhs.fileName < rhs.fileName
        }
        
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
        
        
        
        let template = """
        import Foundation
        
        // swiftlint:disable all
        
        public enum \(pamphletName) {
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
        """
        
        let templateReleaseOnly = """
        import Foundation
        
        // swiftlint:disable all
        
        public enum \(pamphletName) {
            public static func get(string member: String) -> String? {
                switch member {
        {?}
                default: break
                }
                return nil
            }
            public static func get(gzip member: String) -> Data? {
                switch member {
        {?}
                default: break
                }
                return nil
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
        """
        
        let textPagesCode = textPages.filter { _ in options.contains(.includeOriginal) }.map {
            "        case \"\($0.fullPath)\": return \($0.fullVariableName)()"
        }.joined(separator: "\n")
        let compressedPagesCode = textPages.filter { _ in options.contains(.includeGzip) }.map {
            "        case \"\($0.fullPath)\": return \($0.fullVariableName)Gzip()"
        }.joined(separator: "\n")
        let dataPagesCode = dataPages.filter { _ in options.contains(.includeOriginal) }.map {
            "        case \"\($0.fullPath)\": return \($0.fullVariableName)()"
        }.joined(separator: "\n")
        do {
            let swift = String(ipecac: (options.contains(.releaseOnly) ? templateReleaseOnly : template),
                               textPagesCode,
                               compressedPagesCode,
                               dataPagesCode,
                               allDirectoryExtensions)
            try swift.write(toFile: outFile, atomically: true, encoding: .utf8)
        } catch {
            fatalError("Processing failed for file: \(outFile)")
        }
    }
    
    private func fileContentsForTextFile(_ inFile: String) -> String? {
        guard var fileContents = try? String(contentsOfFile: inFile) else { return nil }
        
        if fileContents.hasPrefix("#define PAMPHLET_PREPROCESSOR") {
            // This file wants to use the mcpp preprocessor
            if let cPtr = mcpp_preprocessFile(inFile) {
                fileContents = String(cString: cPtr)
                free(cPtr)
            }
        } else {
            if fileContents.contains("#define") || fileContents.contains("#if") {
                print("warning: \(inFile) is missing PAMPHLET_PREPROCESSOR")
            }
        }
        
        minifyHtml(inFile: inFile, fileContents: &fileContents)
        minifyTs(inFile: inFile, fileContents: &fileContents)
        minifyJs(inFile: inFile, fileContents: &fileContents)
        minifyJson(inFile: inFile, fileContents: &fileContents)
        
        return fileContents
    }
    
    private func generateFile(_ path: FilePath,
                              _ fileOnDisk: String?,
                              _ uncompressed: String?,
                              _ compressed: String?,
                              _ dataType: String,
                              _ includeHeader: Bool) -> String? {
        var scratch = ""
        
        if includeHeader {
            scratch.append("import Foundation\n\n")
            scratch.append("// swiftlint:disable all\n\n")
        }
        
        scratch.append("public extension \(path.extensionName) {\n")
        
        if uncompressed != nil && options.contains(.includeOriginal) {
            scratch.append("    static func \(path.variableName)() -> \(dataType) {\n")
            
            let possiblePaths = [
                "/usr/local/bin/pamphlet",
                "/opt/homebrew/bin/pamphlet"
            ]
            
            var pamphletPath = ""
            for path in possiblePaths where FileManager.default.fileExists(atPath: path) {
                pamphletPath = path
            }
            
            if let fileOnDisk = fileOnDisk, options.contains(.releaseOnly) == false {
                scratch.append("    #if DEBUG\n")
                scratch.append("        let fileOnDiskPath = \"\(fileOnDisk)\"\n")
                scratch.append("        if let contents = try? \(dataType)(contentsOf:URL(fileURLWithPath: fileOnDiskPath)) {\n")
                
                if dataType == "String" {
                    scratch.append("            if contents.hasPrefix(\"#define PAMPHLET_PREPROCESSOR\") {\n")
                    scratch.append("                do {\n")
                    scratch.append("                    let task = Process()\n")
                    scratch.append("                    task.executableURL = URL(fileURLWithPath: \"\(pamphletPath)\")\n")
                    scratch.append("                    task.arguments = [\"preprocess\", fileOnDiskPath]\n")
                    scratch.append("                    let outputPipe = Pipe()\n")
                    scratch.append("                    task.standardOutput = outputPipe\n")
                    scratch.append("                    try task.run()\n")
                    scratch.append("                    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()\n")
                    scratch.append("                    let output = String(decoding: outputData, as: UTF8.self)\n")
                    scratch.append("                    return output\n")
                    scratch.append("                } catch {\n")
                    scratch.append("                    return \"Failed to use \(pamphletPath) to preprocess the requested file\"\n")
                    scratch.append("                }\n")
                    scratch.append("            }\n")
                }
                
                scratch.append("            return contents\n")
                scratch.append("        }\n")
                scratch.append("        return \(dataType)()\n")
                scratch.append("    #else\n")
                scratch.append("        return uncompressed\(path.variableName)\n")
                scratch.append("    #endif\n")
            } else {
                scratch.append("        return uncompressed\(path.variableName)\n")
            }
            scratch.append("    }\n")
        }
        
        if compressed != nil && options.contains(.includeGzip) {
            scratch.append("    static func \(path.variableName)Gzip() -> Data {\n")
            scratch.append("        return compressed\(path.variableName)\n")
            scratch.append("    }\n")
        }
        
        scratch.append("}\n")
        scratch.append("\n")
        
        if let uncompressed = uncompressed, options.contains(.includeOriginal) {
            if dataType == "String" {
                scratch.append("private let uncompressed\(path.variableName) = ###\"\"\"\n\(uncompressed)\n\"\"\"###\n")
            } else {
                scratch.append("private let uncompressed\(path.variableName) = Data(base64Encoded:\"\(uncompressed)\")!\n")
            }
        }
        if let compressed = compressed, options.contains(.includeGzip) {
            scratch.append("private let compressed\(path.variableName) = Data(base64Encoded:\"\(compressed)\")!\n")
        }
        
        return scratch
    }
    
    private func processStringAsFile(_ path: FilePath,
                                     _ inFile: String?,
                                     _ fileContents: String,
                                     _ includeHeader: Bool) -> String? {
        return generateFile(path,
                            inFile,
                            fileContents,
                            gzip(fileContents: fileContents),
                            "String",
                            includeHeader)
    }
    
    private func processTextFile(_ path: FilePath,
                                 _ inFile: String,
                                 _ includeHeader: Bool) -> String? {
        if let fileContents = fileContentsForTextFile(inFile) {
            return processStringAsFile(path,
                                       inFile,
                                       fileContents,
                                       includeHeader)
        }
        return nil
    }
    
    private func fileContentsForDataFile(_ inFile: String) -> String? {
        guard let fileData = try? Data(contentsOf: URL(fileURLWithPath: inFile)) else { return nil }
        return fileData.base64EncodedString()
    }
    
    private func processDataFile(_ path: FilePath,
                                 _ inFile: String,
                                 _ includeHeader: Bool) -> String? {
        return generateFile(path,
                            inFile,
                            fileContentsForDataFile(inFile),
                            nil,
                            "Data",
                            includeHeader)
    }
    
    private func processPackageSwift(_ pamphletName: String, _ outFile: String) -> Bool {
        let template = """
        // swift-tools-version:5.2
        import PackageDescription
        let package = Package(
            name: "\(pamphletName)",
            products: [
                .library(name: "\(pamphletName)", targets: ["\(pamphletName)"])
            ],
            targets: [
                .target(
                    name: "\(pamphletName)"
                )
            ]
        )
        """
        
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
                            if outPath.contains(".collapsed.swift") {
                                continue
                            }
                            
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
    
    public func process(prefix: String?,
                        extensions: [String],
                        inDirectory: String,
                        outDirectory: String,
                        options: PamphletOptions) {
        
        self.options = options
        
        let pamphletName = (prefix != nil ? prefix! + "Pamphlet" : "Pamphlet")
        
        let resourceKeys: [URLResourceKey] = [.contentModificationDateKey, .creationDateKey, .isDirectoryKey]
        var generateFilesDirectory = outDirectory
        
        let pamphletExecPath = ProcessInfo.processInfo.arguments[0]
        guard let pamphletExecPathValues = try? URL(fileURLWithPath: pamphletExecPath).resourceValues(forKeys: Set(resourceKeys)) else { fatalError() }
        
        try? FileManager.default.createDirectory(atPath: generateFilesDirectory, withIntermediateDirectories: true, attributes: nil)
        
        if options.contains(.swiftpm) {
            // We assume that the output directory is where we want the Package.swft,
            // so we need to create the Sources/ and Sources/Pamphlet directories
            // and store the generated files in there
            generateFilesDirectory = outDirectory + "/Sources/" + pamphletName
            try? FileManager.default.createDirectory(atPath: generateFilesDirectory, withIntermediateDirectories: true, attributes: nil)
            
            // Generate a Package.swift
            let packageSwiftPath = outDirectory + "/Package.swift"
            if !processPackageSwift(pamphletName, packageSwiftPath) {
                fatalError("Unable to create Package.swift at \(packageSwiftPath)")
            }
        }
        
        
        removeOldFiles(inDirectory, generateFilesDirectory, options.contains(.clean))
        
        let enumerator = FileManager.default.enumerator(at: URL(fileURLWithPath: inDirectory),
                                                        includingPropertiesForKeys: resourceKeys,
                                                        options: [.skipsHiddenFiles],
                                                        errorHandler: { (url, error) -> Bool in
                                                            print("directoryEnumerator error at \(url): ", error)
                                                            return true
        })!
        
        let textPages = BoxedArray<FilePath>()
        let dataPages = BoxedArray<FilePath>()
        
        //print("in: " + inDirectory)
        //print("out: " + generateFilesDirectory)
        
        let inDirectoryFullPath = URL(fileURLWithPath: inDirectory).path
                
        // we want to process all files in a directory at the same time, so we need to pre-walk
        // the enumeration
        
        var filesByDirectory: [URL: BoxedArray<URL>] = [:]
        
        for case let fileURL as URL in enumerator {
            if let resourceValues = try? fileURL.resourceValues(forKeys: Set(resourceKeys)) {
                if let isDirectory = resourceValues.isDirectory, isDirectory == false {
                    let pathExtension = (fileURL.path as NSString).pathExtension
                    if (extensions.count == 0 || extensions.contains(pathExtension)) {
                        let directoryURL = fileURL.deletingLastPathComponent()
                        if filesByDirectory[directoryURL] == nil {
                            filesByDirectory[directoryURL] = BoxedArray<URL>()
                        }
                        filesByDirectory[directoryURL]?.append(fileURL)
                    }
                }
            }
        }
        
        for directoryURL in filesByDirectory.keys {
            guard let files = filesByDirectory[directoryURL] else { continue }
            process(directory: directoryURL,
                    files: files,
                    pamphletName: pamphletName,
                    pamphletExecPathValues: pamphletExecPathValues,
                    inDirectoryFullPath: inDirectoryFullPath,
                    generateFilesDirectory: generateFilesDirectory,
                    options: options,
                    textPages: textPages,
                    dataPages: dataPages)
        }
        
        createPamphletFile(pamphletName, textPages.array, dataPages.array, generateFilesDirectory + "/\(pamphletName).swift")
    }
    
    private func process(directory: URL,
                         files: BoxedArray<URL>,
                         pamphletName: String,
                         pamphletExecPathValues: URLResourceValues,
                         inDirectoryFullPath: String,
                         generateFilesDirectory: String,
                         options: PamphletOptions,
                         textPages: BoxedArray<FilePath>,
                         dataPages: BoxedArray<FilePath>) {
        let resourceKeys: [URLResourceKey] = [.contentModificationDateKey, .creationDateKey, .isDirectoryKey]
        
        let directoryPartialPath = String(directory.path.dropFirst(inDirectoryFullPath.count))
        let directoryFilePath = FilePath(pamphletName, directoryPartialPath)
        
        var fileDirectoryPartialPath = directoryPartialPath.replacingOccurrences(of: "/", with: ".")
        if fileDirectoryPartialPath.hasPrefix(".") {
            fileDirectoryPartialPath = String(fileDirectoryPartialPath.dropFirst())
        }
        if fileDirectoryPartialPath == "" {
            fileDirectoryPartialPath = "Pamphlet"
        }
        
        if directory.pathExtension == "json" {
            // Pamphlet has a rule that if a directory ends in ".json", the files in said directory should be
            // preprocessed but then stored in a pamphlet file named the same as the directory itself.
            // For example:
            // en.json -|
            //          - main.md
            //          - supplemental.md
            //
            // Will generate one pamphlet entry called EnJson.  That entry itself will have json content like this:
            //
            // { "main.md": "<content of main.md>", "supplemental.md": "<content of supplemental.md>" }
            let jsonDirectory = JsonDirectory()
            for fileURL in files {
                let partialPath = String(fileURL.path.dropFirst(inDirectoryFullPath.count))
                let filePath = FilePath(pamphletName, partialPath)
                
                if let fileContent = fileContentsForTextFile(fileURL.path) {
                    jsonDirectory.files[filePath.fileName] = fileContent
                } else if let fileContent = fileContentsForDataFile(fileURL.path) {
                    jsonDirectory.files[filePath.fileName] = fileContent
                } else {
                    fatalError("Processing failed for file: \(fileURL.path)")
                }
            }
            if let jsonDirectoryEncoded = try? jsonDirectory.json() {
                let outputDirectory = URL(fileURLWithPath: generateFilesDirectory + "/" + directoryPartialPath).deletingLastPathComponent().path
                try? FileManager.default.createDirectory(atPath: outputDirectory, withIntermediateDirectories: true, attributes: nil)

                let jsonDirectoryOutputPath = "\(outputDirectory)/\(directoryFilePath.fileName).swift"
                if let fileContent = processStringAsFile(directoryFilePath, nil, jsonDirectoryEncoded, true) {
                    try! fileContent.write(toFile: jsonDirectoryOutputPath, atomically: true, encoding: .utf8)
                    textPages.append(directoryFilePath)
                }
            }
            return
        }
        
        if options.contains(.collapse) {
            // When we collapse a directory, all swift files in the directory go into a single files
            let outputDirectory = URL(fileURLWithPath: generateFilesDirectory).path
            let outputFile = "\(outputDirectory)/\(fileDirectoryPartialPath).collapsed.swift"
            
            try? FileManager.default.createDirectory(atPath: outputDirectory, withIntermediateDirectories: true, attributes: nil)
            
            // 0. check for skipping
            var shouldSkipAll = true
            for fileURL in files {
                var shouldSkip = false
                if let outResourceValues = try? URL(fileURLWithPath: outputFile).resourceValues(forKeys: Set(resourceKeys)) {
                    // We need to check the main source output file, but also any files which are #include to this one
                    // and any and all files #included from the dependencies
                    shouldSkip = shouldSkipFile(outResourceValues.contentModificationDate!, fileURL.path)
                    if !shouldSkip {
                        print("DATE CHECK FAILED: \(fileURL.path)")
                    }
                    // also check against the modification date of pamphlet itself
                    if shouldSkip {
                        shouldSkip = pamphletExecPathValues.contentModificationDate! <= outResourceValues.contentModificationDate!
                    }
                }
                if shouldSkip == false {
                    shouldSkipAll = false
                    break
                }
            }
            
            if shouldSkipAll {
                // Even if we skip generating files, we need to note them so that they are added to the
                // Pamphlet.swift file
                for fileURL in files {
                    let partialPath = String(fileURL.path.dropFirst(inDirectoryFullPath.count))
                    let filePath = FilePath(pamphletName, partialPath)
                    if let _ = try? String(contentsOfFile: fileURL.path) {
                        textPages.append(filePath)
                    } else {
                        dataPages.append(filePath)
                    }
                }
                return
            }
            
            // 1. at least one file was updated, regenerate all of the files
            var collapsedContent = ""
            var includeHeader = true
            for fileURL in files {
                let partialPath = String(fileURL.path.dropFirst(inDirectoryFullPath.count))
                let filePath = FilePath(pamphletName, partialPath)
                
                if let fileContent = processTextFile(filePath, fileURL.path, includeHeader) {
                    collapsedContent += fileContent + "\n"
                    textPages.append(filePath)
                    includeHeader = false
                } else if let fileContent = processDataFile(filePath, fileURL.path, includeHeader) {
                    collapsedContent += fileContent + "\n"
                    dataPages.append(filePath)
                    includeHeader = false
                } else {
                    fatalError("Processing failed for file: \(fileURL.path)")
                }
            }
            
            try! collapsedContent.write(toFile: outputFile, atomically: true, encoding: .utf8)
            
            return
        }
        
        
        
        // normal processing: each file is matched to its own generated .swift file
        for fileURL in files {
            let partialPath = String(fileURL.path.dropFirst(inDirectoryFullPath.count))
            let filePath = FilePath(pamphletName, partialPath)
            let outputDirectory = URL(fileURLWithPath: generateFilesDirectory + "/" + partialPath).deletingLastPathComponent().path
            let outputFile = "\(outputDirectory)/\(filePath.fileName).swift"

            try? FileManager.default.createDirectory(atPath: outputDirectory, withIntermediateDirectories: true, attributes: nil)
            
            var shouldSkip = false
            if let outResourceValues = try? URL(fileURLWithPath: outputFile).resourceValues(forKeys: Set(resourceKeys)) {
                // We need to check the main source output file, but also any files which are #include to this one
                // and any and all files #included from the dependencies
                shouldSkip = shouldSkipFile(outResourceValues.contentModificationDate!, fileURL.path)
                if !shouldSkip {
                    print("DATE CHECK FAILED: \(fileURL.path)")
                }
                // also check against the modification date of pamphlet itself
                if shouldSkip {
                    shouldSkip = pamphletExecPathValues.contentModificationDate! <= outResourceValues.contentModificationDate!
                }
            }
            
            if shouldSkip == false {
                if let fileContent = processTextFile(filePath, fileURL.path, true) {
                    try! fileContent.write(toFile: outputFile, atomically: true, encoding: .utf8)
                    textPages.append(filePath)
                } else if let fileContent = processDataFile(filePath, fileURL.path, true) {
                    try! fileContent.write(toFile: outputFile, atomically: true, encoding: .utf8)
                    dataPages.append(filePath)
                } else {
                    fatalError("Processing failed for file: \(fileURL.path)")
                }
            } else {
                // Even if we skip, we still need to add to the textPages and dataPages...
                if let _ = try? String(contentsOfFile: fileURL.path) {
                    textPages.append(filePath)
                } else {
                    dataPages.append(filePath)
                }
            }
            
        }
    }
    
    private func shouldSkipFile(_ date: Date, _ filePath: String) -> Bool {
        let resourceKeys: [URLResourceKey] = [.contentModificationDateKey]
        let fileURL = URL(fileURLWithPath: filePath)
        if let values = try? fileURL.resourceValues(forKeys: Set(resourceKeys)) {
            if values.contentModificationDate! > date {
                return false
            }
        }
        // Load the file and find all dependencies
        if let fileContents = try? String(contentsOfFile: filePath) {
            var includedFiles:[String] = []
            fileContents.matches(#"#include\s*<([^>]*)>"#) { (result, groups) in
                includedFiles.append(groups[1])
            }
            
            for otherFilePath in includedFiles {
                if !self.shouldSkipFile(date, fileURL.deletingLastPathComponent().appendingPathComponent(otherFilePath).path) {
                    return false
                }
            }
        }
        return true
    }
    
}
