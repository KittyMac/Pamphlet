import Foundation
import libmcpp
import Hitch
import JXKit

func pathFor(executable name: String) -> String {
    if FileManager.default.fileExists(atPath: "/opt/homebrew/bin/\(name)") {
        return "/opt/homebrew/bin/\(name)"
    } else if FileManager.default.fileExists(atPath: "/usr/bin/\(name)") {
        return "/usr/bin/\(name)"
    } else if FileManager.default.fileExists(atPath: "/usr/local/bin/\(name)") {
        return "/usr/local/bin/\(name)"
    } else if FileManager.default.fileExists(atPath: "/bin/\(name)") {
        return "/bin/\(name)"
    }
    return "./\(name)"
}

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
    var isStaticString: Bool = false
        
    init(_ pamphletName: String,
         _ inPath: String,
         _ options: PamphletOptions) {
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
        scratch.append(options.fileExt())
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
    public var kotlinPackage: String?
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public func fileExt() -> String {
        if contains(.kotlin) {
            return ".kt"
        }
        return ".swift"
    }
    
    public static let clean = PamphletOptions(rawValue:  1 << 0)
    public static let swiftpm = PamphletOptions(rawValue:  1 << 1)
    public static let releaseOnly = PamphletOptions(rawValue:  1 << 2)
    public static let includeOriginal = PamphletOptions(rawValue:  1 << 3)
    public static let includeGzip = PamphletOptions(rawValue:  1 << 4)
    public static let minifyHtml = PamphletOptions(rawValue:  1 << 5)
    public static let minifyJs = PamphletOptions(rawValue:  1 << 6)
    public static let minifyJson = PamphletOptions(rawValue:  1 << 7)
    public static let collapse = PamphletOptions(rawValue:  1 << 8)
    public static let kotlin = PamphletOptions(rawValue:  1 << 9)
    public static let collapseAll = PamphletOptions(rawValue:  1 << 10)
    
    public static let `default`: PamphletOptions = [.swiftpm, .includeOriginal, .includeGzip, .minifyHtml, .minifyJs, .minifyJson]
}

public class PamphletFramework {
    
    var options = PamphletOptions.default
    
    var pamphletFilePath: String = ""
    
    let jxCtx = JXContext()
    
    public init() {
        try! jxCtx.eval(script: ToolsPamphlet.ToolsJs().description)
    }
    
    private func createPamphletFile(_ pamphletName: String,
                                    _ inTextPages: [FilePath],
                                    _ inDataPages: [FilePath],
                                    _ inDirectoryPages: [FilePath],
                                    _ outFile: String) {
        
        
        var allDirectoryExtensions = ""
        
        let textPages = inTextPages.sorted { (lhs, rhs) -> Bool in
            return lhs.fileName < rhs.fileName
        }
        
        let dataPages = inDataPages.sorted { (lhs, rhs) -> Bool in
            return lhs.fileName < rhs.fileName
        }
        
        for page in inDirectoryPages {
            if page.parts.count > 1 {
                let code = ####"""
                    public extension {?} { enum {?} { } }
                    
                    """#### << [page.parentExtensionName, page.myStructName]
                if allDirectoryExtensions.contains(code.description) == false {
                    allDirectoryExtensions.append(code.description)
                }
            }
        }
        
        for page in (textPages + dataPages) {
            if page.parts.count > 1 {
                let code = ####"""
                    public extension {?} { enum {?} { } }
                    
                    """#### << [page.parentExtensionName, page.myStructName]
                if allDirectoryExtensions.contains(code.description) == false {
                    allDirectoryExtensions.append(code.description)
                }
            }
        }
        
        // ------------- Swift -------------
        let version = git() ?? "v0.0.0"
        
        let templateSwift = """
        {0}
        
        public enum \(pamphletName) {
            public static let version = "\(version)"
            
            #if DEBUG
            public static func get(string member: String) -> String? {
                switch member {
        {1}
                default: break
                }
                return nil
            }
            #else
            public static func get(string member: String) -> StaticString? {
                switch member {
        {2}
                default: break
                }
                return nil
            }
            #endif
            public static func get(gzip member: String) -> Data? {
                #if DEBUG
                    return nil
                #else
                    switch member {
        {3}
                    default: break
                    }
                    return nil
                #endif
            }
            public static func get(data member: String) -> Data? {
                switch member {
        {4}
                default: break
                }
                return nil
            }
        }
        {5}
        """
        
        let templateReleaseOnlySwift = """
        {0}
        
        public enum \(pamphletName) {
            public static let version = "\(version)"

            public static func get(string member: String) -> StaticString? {
                switch member {
        {1}
                default: break
                }
                return nil
            }
            public static func get(gzip member: String) -> Data? {
                switch member {
        {3}
                default: break
                }
                return nil
            }
            public static func get(data member: String) -> Data? {
                switch member {
        {4}
                default: break
                }
                return nil
            }
        }
        {5}
        """
        
        // ------------- KOTLIN -------------
        
        let templateKotlin = """
        {0}
        
        object \(pamphletName) {
            val version = "\(version)"
        
            fun getAsString(member: String): String? {
                return when (member) {
        {1}
                    else -> null
                }
            }
            fun getAsGzip(member: String): ByteArray? {
                if (BuildConfig.DEBUG) {
                    return null
                } else {
                    return when (member) {
        {3}
                        else -> null
                    }
                }
            }
            fun getAsByteArray(member: String): ByteArray? {
                return when (member) {
        {4}
                    else -> null
                }
            }
        }
        {5}
        """
        
        
        
        let templateReleaseOnlyKotlin = """
        {0}
        
        object \(pamphletName) {
            fun getAsString(member: String): String? {
                return when (member) {
        {1}
                    else -> null
                }
            }
            fun getAsGzip(member: String): ByteArray? {
                return when (member) {
        {3}
                    else -> null
                }
            }
            fun getAsByteArray(member: String): ByteArray? {
                return when (member) {
        {4}
                    else -> null
                }
            }
        }
        {5}
        """
        
        var fileHeader = "import Foundation\n\n// swiftlint:disable all\n\n"
        var template = templateSwift
        var templateReleaseOnly = templateReleaseOnlySwift
        if options.contains(.kotlin) {
            template = templateKotlin
            templateReleaseOnly = templateReleaseOnlyKotlin
            
            fileHeader = ""
            if let packagePath = options.kotlinPackage {
                fileHeader += "package \(packagePath)\n\n"
                if options.contains(.releaseOnly) == false {
                    //kotlinHeader += "import \(packagePath).BuildConfig\n"
                }
            }
        }
        
        let textPagesCodeDebug = textPages.filter { _ in options.contains(.includeOriginal) }.map {
            if options.contains(.kotlin) {
                return "                \"\($0.fullPath)\" -> return \($0.fullVariableName)()"
            } else {
                if $0.isStaticString {
                    return "        case \"\($0.fullPath)\": return \($0.fullVariableName)().description"
                } else {
                    return "        case \"\($0.fullPath)\": return \($0.fullVariableName)()"
                }
            }
        }.joined(separator: "\n")
        
        let textPagesCodeRelease = textPages.filter { _ in options.contains(.includeOriginal) }.map {
            if options.contains(.kotlin) {
                return "                \"\($0.fullPath)\" -> return \($0.fullVariableName)()"
            } else {
                if $0.isStaticString {
                    return "        case \"\($0.fullPath)\": return \($0.fullVariableName)()"
                } else {
                    return "        case \"\($0.fullPath)\": return \($0.fullVariableName)()"
                }
            }
        }.joined(separator: "\n")
        
        let compressedPagesCode = textPages.filter { _ in options.contains(.includeGzip) }.map {
            if options.contains(.kotlin) {
                return "                \"\($0.fullPath)\" -> return \($0.fullVariableName)Gzip()"
            } else {
                return "        case \"\($0.fullPath)\": return \($0.fullVariableName)Gzip()"
            }
        }.joined(separator: "\n")
        let dataPagesCode = dataPages.filter { _ in options.contains(.includeOriginal) }.map {
            if options.contains(.kotlin) {
                return "                \"\($0.fullPath)\" -> return \($0.fullVariableName)()"
            } else {
                return "        case \"\($0.fullPath)\": return \($0.fullVariableName)()"
            }
        }.joined(separator: "\n")

        let pamphletTemplate = options.contains(.releaseOnly) ? templateReleaseOnly : template
        let swift = pamphletTemplate << [
            fileHeader,
            textPagesCodeDebug,
            textPagesCodeRelease,
            compressedPagesCode,
            dataPagesCode,
            allDirectoryExtensions
        ]
        
        if let stringData = swift.description.data(using: .utf8),
           let handle = FileHandle(forWritingAtPath: outFile) {
            if options.contains(.collapseAll) {
                handle.seekToEndOfFile()
            }
            handle.write(stringData)
            handle.closeFile()
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
        
        minifyHtml(jxCtx: jxCtx, inFile: inFile, fileContents: &fileContents)
        minifyJs(jxCtx: jxCtx, inFile: inFile, fileContents: &fileContents)
        minifyJson(jxCtx: jxCtx, inFile: inFile, fileContents: &fileContents)
        
        return fileContents
    }
    
    private func generateFile(_ path: FilePath,
                              _ fileOnDisk: String?,
                              _ uncompressed: String?,
                              _ compressed: String?,
                              _ dataType: String,
                              _ includeHeader: Bool,
                              _ options: PamphletOptions) -> String? {
        var scratch = ""
        
        if includeHeader {
            if options.contains(.kotlin) {
                if let packagePath = options.kotlinPackage {
                    scratch.append("package \(packagePath)\n\n")
                    scratch.append("import android.util.Base64\n\n")
                }
            } else {
                scratch.append("import Foundation\n\n")
                scratch.append("// swiftlint:disable all\n\n")
            }
        }
        
        if options.contains(.kotlin) {
            
        } else {
            scratch.append("public extension \(path.extensionName) {\n")
        }
        
        if uncompressed != nil && options.contains(.includeOriginal) {
            let possiblePaths = [
                "/usr/local/bin/pamphlet",
                "/opt/homebrew/bin/pamphlet"
            ]
            
            var pamphletPath = ""
            for path in possiblePaths where FileManager.default.fileExists(atPath: path) {
                pamphletPath = path
            }
            
            var reifiedDataType = dataType
            if dataType == "String" {
                reifiedDataType = "StaticString"
            }
            
            if let fileOnDisk = fileOnDisk, options.contains(.releaseOnly) == false {
                scratch.append("    #if DEBUG\n")
                scratch.append("    static func \(path.variableName)() -> \(dataType) {\n")
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
                scratch.append("    }\n")
                
                scratch.append("    #else\n")
                scratch.append("    static func \(path.variableName)() -> \(reifiedDataType) {\n")
                scratch.append("        return uncompressed\(path.variableName)\n")
                scratch.append("    }\n")
                scratch.append("    #endif\n")
                
            } else {
                
                scratch.append("    static func \(path.variableName)() -> \(reifiedDataType) {\n")
                scratch.append("        return uncompressed\(path.variableName)\n")
                scratch.append("    }\n")
            }
            
        }
        
        if compressed != nil && options.contains(.includeGzip) {
            if options.contains(.kotlin) {
                scratch.append("fun Pamphlet.\(path.variableName)Gzip(): ByteArray {\n")
                scratch.append("    return compressed\(path.variableName)\n")
                scratch.append("}\n")
            } else {
                scratch.append("    static func \(path.variableName)Gzip() -> Data {\n")
                scratch.append("        return compressed\(path.variableName)\n")
                scratch.append("    }\n")
            }
        }
        
        if options.contains(.kotlin) {
            
        } else {
            scratch.append("}\n")
            scratch.append("\n")
        }
        
        if let uncompressed = uncompressed, options.contains(.includeOriginal) {
            if dataType == "String" {
                if options.contains(.kotlin) {
                    scratch.append("private val uncompressed\(path.variableName) = \"\n\(uncompressed)\n\"\n")
                } else {
                    scratch.append("private let uncompressed\(path.variableName): StaticString = ###\"\"\"\n\(uncompressed)\n\"\"\"###\n")
                }
            } else {
                if options.contains(.kotlin) {
                    scratch.append("private val uncompressed\(path.variableName) = Base64.decode(\"\(uncompressed)\", Base64.DEFAULT)\n")
                } else {
                    scratch.append("private let uncompressed\(path.variableName) = Data(base64Encoded:\"\(uncompressed)\")!\n")
                }
            }
        }
        if let compressed = compressed, options.contains(.includeGzip) {
            if options.contains(.kotlin) {
                scratch.append("private val compressed\(path.variableName) = Base64.decode(\"\(compressed)\", Base64.DEFAULT)\n")
            } else {
                scratch.append("private let compressed\(path.variableName) = Data(base64Encoded:\"\(compressed)\")!\n")
            }
        }
        
        return scratch
    }
    
    private func processStringAsFile(_ path: FilePath,
                                     _ inFile: String?,
                                     _ fileContents: String,
                                     _ includeHeader: Bool,
                                     _ options: PamphletOptions) -> String? {
        return generateFile(path,
                            inFile,
                            fileContents,
                            gzip(fileContents: fileContents),
                            "String",
                            includeHeader,
                            options)
    }
    
    private func processTextFile(_ path: FilePath,
                                 _ inFile: String,
                                 _ includeHeader: Bool,
                                 _ options: PamphletOptions) -> String? {
        if let fileContents = fileContentsForTextFile(inFile) {
            return processStringAsFile(path,
                                       inFile,
                                       fileContents,
                                       includeHeader,
                                       options)
        }
        return nil
    }
    
    private func fileContentsForDataFile(_ inFile: String) -> String? {
        guard let fileData = try? Data(contentsOf: URL(fileURLWithPath: inFile)) else { return nil }
        return fileData.base64EncodedString()
    }
    
    private func processDataFile(_ path: FilePath,
                                 _ inFile: String,
                                 _ includeHeader: Bool,
                                 _ options: PamphletOptions) -> String? {
        return generateFile(path,
                            inFile,
                            fileContentsForDataFile(inFile),
                            nil,
                            "Data",
                            includeHeader,
                            options)
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
                    if fileName.hasSuffix(options.fileExt()) && resourceValues.isDirectory == false {
                        let outPath = fileURL.path
                        let fullOutDirectory = URL(fileURLWithPath: outDirectory).path
                        
                        if removeAll {
                            try? FileManager.default.removeItem(at: fileURL)
                        }else{
                            if outPath.contains(".collapsed" + options.fileExt()) {
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
        
        if options.contains(.swiftpm) && options.contains(.kotlin) == false {
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
        
        pamphletFilePath = generateFilesDirectory + "/\(pamphletName)\(options.fileExt())"
        
        try? FileManager.default.removeItem(atPath: pamphletFilePath)
        try? "".write(toFile: pamphletFilePath, atomically: false, encoding: .utf8)
        
        let enumerator = FileManager.default.enumerator(at: URL(fileURLWithPath: inDirectory),
                                                        includingPropertiesForKeys: resourceKeys,
                                                        options: [.skipsHiddenFiles],
                                                        errorHandler: { (url, error) -> Bool in
                                                            print("directoryEnumerator error at \(url): ", error)
                                                            return true
        })!
        
        let textPages = BoxedArray<FilePath>()
        let dataPages = BoxedArray<FilePath>()
        let directoryPages = BoxedArray<FilePath>()
        
        //print("in: " + inDirectory)
        //print("out: " + generateFilesDirectory)
        
        let inDirectoryFullPath = URL(fileURLWithPath: inDirectory).path
                
        // we want to process all files in a directory at the same time, so we need to pre-walk
        // the enumeration
        
        var allDirectories: [URL] = []
        var filesByDirectory: [URL: BoxedArray<URL>] = [:]
        
        for case let fileURL as URL in enumerator {
            if let resourceValues = try? fileURL.resourceValues(forKeys: Set(resourceKeys)) {
                if let isDirectory = resourceValues.isDirectory {
                    if isDirectory {
                        allDirectories.append(fileURL)
                    } else {
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
        
        for directory in allDirectories {
            let partialPath = String(directory.path.dropFirst(inDirectoryFullPath.count))
            let filePath = FilePath(pamphletName, partialPath, options)
            directoryPages.append(filePath)
        }
        
        createPamphletFile(pamphletName,
                           textPages.array,
                           dataPages.array,
                           directoryPages.array,
                           pamphletFilePath)
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
        var directoryFilePath = FilePath(pamphletName, directoryPartialPath, options)
        
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
                let filePath = FilePath(pamphletName, partialPath, options)
                
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

                let jsonDirectoryOutputPath = "\(outputDirectory)/\(directoryFilePath.fileName)\(options.fileExt())"
                if let fileContent = processStringAsFile(directoryFilePath, nil, jsonDirectoryEncoded, true, options) {
                    
                    if options.contains(.collapseAll) {
                        if let stringData = fileContent.data(using: .utf8),
                           let handle = FileHandle(forWritingAtPath: pamphletFilePath) {
                            handle.seekToEndOfFile()
                            handle.write(stringData)
                            handle.closeFile()
                        }
                    } else {
                        try! fileContent.write(toFile: jsonDirectoryOutputPath, atomically: true, encoding: .utf8)
                    }
                    
                    directoryFilePath.isStaticString = true
                    
                    textPages.append(directoryFilePath)
                }
            }
            return
        }
        
        if options.contains(.collapse) || options.contains(.collapseAll) {
            // When we collapse a directory, all swift files in the directory go into a single files
            let outputDirectory = URL(fileURLWithPath: generateFilesDirectory).path
            let outputFile = "\(outputDirectory)/\(fileDirectoryPartialPath).collapsed\(options.fileExt())"
            
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
                        //print("DATE CHECK FAILED: \(fileURL.path)")
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
                    let filePath = FilePath(pamphletName, partialPath, options)
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
                let filePath = FilePath(pamphletName, partialPath, options)
                
                if let fileContent = processTextFile(filePath, fileURL.path, includeHeader, options) {
                    collapsedContent += fileContent + "\n"
                    textPages.append(filePath)
                    includeHeader = false
                } else if let fileContent = processDataFile(filePath, fileURL.path, includeHeader, options) {
                    collapsedContent += fileContent + "\n"
                    dataPages.append(filePath)
                    includeHeader = false
                } else {
                    fatalError("Processing failed for file: \(fileURL.path)")
                }
            }
            
            
            if options.contains(.collapseAll) {
                if let stringData = collapsedContent.data(using: .utf8),
                   let handle = FileHandle(forWritingAtPath: pamphletFilePath) {
                    handle.seekToEndOfFile()
                    handle.write(stringData)
                    handle.closeFile()
                }
            } else {
                try! collapsedContent.write(toFile: outputFile, atomically: true, encoding: .utf8)
            }
            
            return
        }
        
        
        
        // normal processing: each file is matched to its own generated .swift file
        for fileURL in files {
            let partialPath = String(fileURL.path.dropFirst(inDirectoryFullPath.count))
            let filePath = FilePath(pamphletName, partialPath, options)
            let outputDirectory = URL(fileURLWithPath: generateFilesDirectory + "/" + partialPath).deletingLastPathComponent().path
            let outputFile = "\(outputDirectory)/\(filePath.fileName)\(options.fileExt())"

            try? FileManager.default.createDirectory(atPath: outputDirectory, withIntermediateDirectories: true, attributes: nil)
            
            var shouldSkip = false
            if let outResourceValues = try? URL(fileURLWithPath: outputFile).resourceValues(forKeys: Set(resourceKeys)) {
                // We need to check the main source output file, but also any files which are #include to this one
                // and any and all files #included from the dependencies
                shouldSkip = shouldSkipFile(outResourceValues.contentModificationDate!, fileURL.path)
                if !shouldSkip {
                    //print("DATE CHECK FAILED: \(fileURL.path)")
                }
                // also check against the modification date of pamphlet itself
                if shouldSkip {
                    shouldSkip = pamphletExecPathValues.contentModificationDate! <= outResourceValues.contentModificationDate!
                }
            }
            
            if shouldSkip == false {
                if let fileContent = processTextFile(filePath, fileURL.path, true, options) {
                    try! fileContent.write(toFile: outputFile, atomically: true, encoding: .utf8)
                    textPages.append(filePath)
                } else if let fileContent = processDataFile(filePath, fileURL.path, true, options) {
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
