import Foundation
import libmcpp
import Hitch
import Sextant
import Spanker

#if os(Windows)
public let pamphletTempPath = "C:/WINDOWS/Temp/"
#else
public let pamphletTempPath = "/tmp/"
#endif

enum OutputType: String {
    case debug = "debug"
    case release = "release"
}

public class PamphletFramework {
    public static let shared = PamphletFramework()
    
    public var ignoreHeader: String? = nil
    
    var gIncludeOriginal: Bool? = nil
    var gReleaseOnly: Bool? = nil
    var gIncludeGzip: Bool? = nil
    var gMinifyHtml: Bool? = nil
    var gMinifyJs: Bool? = nil
    var gMinifyJson: Bool? = nil
    var gCompressionLevel: Int? = nil

    var fileHeaderDebug = """
    // swiftlint:disable all
    
    #if DEBUG && canImport(PamphletFramework)
    import Foundation
    import PamphletFramework
    
    
    """
    
    var fileHeaderRelease = """
    // swiftlint:disable all
    
    #if !DEBUG || !canImport(PamphletFramework)
    import Foundation
    
    
    """
    
    var fileHeaderReleaseOnly = """
    // swiftlint:disable all
    
    import Foundation
    
    
    """
    
    var fileFooterDebug = """
    
    #endif
    """
    
    var fileFooterRelease = """
    
    #endif
    """
    
    var fileFooterReleaseOnly = """
    """
    
    private var writeLock = NSLock()
    private let queue1 = OperationQueue()
    private let queue2 = OperationQueue()
    
    private var gitVersionString: String = ""
    private var gitHashString: String = ""
    
    var options = PamphletOptions.default
    var pamphletJson = ^[]
    
    var debugPath: String = ""
    var releasePath: String = ""
    
    private init() {
        queue1.maxConcurrentOperationCount = ProcessInfo.processInfo.activeProcessorCount
        queue2.maxConcurrentOperationCount = ProcessInfo.processInfo.activeProcessorCount
    }
    
    private func pathOutput(path: String,
                            type: OutputType) -> String {
        let url = URL(fileURLWithPath: path)
        let ext = url.pathExtension
        return url.deletingPathExtension().appendingPathExtension(type.rawValue).appendingPathExtension(ext).path
    }
    
    private func createOutput(path: String,
                              type: OutputType) {
        // path like: /path/to/Pamphlet.swift
        // for debug adjust it to: /path/to/Pamphlet.debug.swift
        // for release adjust it to: /path/to/Pamphlet.release.swift
        writeLock.lock(); defer { writeLock.unlock() }
        
        try? "".write(toFile: path, atomically: false, encoding: .utf8)
    }
    
    private func appendOutput(data: Data,
                              path: String,
                              type: OutputType) {
        // path like: /path/to/Pamphlet.swift
        // for debug adjust it to: /path/to/Pamphlet.debug.swift
        // for release adjust it to: /path/to/Pamphlet.release.swift
        writeLock.lock(); defer { writeLock.unlock() }
        
        if let handle = FileHandle(forWritingAtPath: path) {
            handle.seekToEndOfFile()
            handle.write(data)
            handle.closeFile()
        }
    }
    
    private func appendOutput(string: String,
                              path: String,
                              type: OutputType) {
        if let data = string.data(using: .utf8) {
            appendOutput(data: data,
                         path: path,
                         type: type)
        }
    }
    
    private func createPamphletFile(_ pamphletName: String,
                                    _ inTextPages: [FilePath],
                                    _ inDataPages: [FilePath],
                                    _ inCompressedDataPages: [FilePath],
                                    _ inDirectoryPages: [FilePath]) {
        
        
        var allDirectoryExtensions = ""
        
        let textPages = inTextPages.sorted { (lhs, rhs) -> Bool in
            return lhs.fileName < rhs.fileName
        }
        
        let dataPages = inDataPages.sorted { (lhs, rhs) -> Bool in
            return lhs.fileName < rhs.fileName
        }
        
        let compressedDataPages = inCompressedDataPages.sorted { (lhs, rhs) -> Bool in
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
        let version = gitVersionString
        
        let templateDebugOnlySwift = """
        {0}
        
        public enum \(pamphletName) {
            public static let version = "\(version)"
            
            public static func get(string member: String) -> String? {
        {1}
                return nil
            }
            public static func get(gzip member: String) -> Data? {
                return nil
            }
            public static func get(data member: String) -> Data? {
        {4}
                return nil
            }
            public static func get(md5 member: String) -> StaticString? {
        {6}
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
        {2}
                return nil
            }
            public static func get(gzip member: String) -> Data? {
        {3}
                return nil
            }
            public static func get(data member: String) -> Data? {
        {4}
                return nil
            }
            public static func get(md5 member: String) -> StaticString? {
        {6}
                return nil
            }
        }
        {5}
        """
        
        // ------------- KOTLIN -------------
        
        let templateDebugOnlyKotlin = """
        {0}
        
        object \(pamphletName) {
            val version = "\(version)"
        
            fun getAsString(member: String): String? {
        {1}
                return null
            }
            fun getAsGzip(member: String): ByteArray? {
                if (BuildConfig.DEBUG) {
                    return null
                } else {
        {3}
                    return null
                }
            }
            fun getAsByteArray(member: String): ByteArray? {
        {4}
                    return null
            }
        }
        {5}
        """
        
        
        
        let templateReleaseOnlyKotlin = """
        {0}
        
        object \(pamphletName) {
            val version = "\(version)"

            fun getAsString(member: String): String? {
        {2}
                    return null
            }
            fun getAsGzip(member: String): ByteArray? {
        {3}
                    return null
            }
            fun getAsByteArray(member: String): ByteArray? {
        {4}
                    return null
            }
        }
        {5}
        """
        
        var templateDebugOnly = templateDebugOnlySwift
        var templateReleaseOnly = templateReleaseOnlySwift
        if options.contains(.kotlin) {
            templateDebugOnly = templateDebugOnlyKotlin
            templateReleaseOnly = templateReleaseOnlyKotlin
            
            if let packagePath = options.kotlinPackage {
                fileHeaderDebug = "package \(packagePath)\n\n"
                fileHeaderRelease = "package \(packagePath)\n\n"
            } else {
                fileHeaderDebug = ""
                fileHeaderRelease = ""
            }
        }
        
        let textPagesCodeDebug = textPages.filter { _ in includeOriginal(for: nil) }.map {
            if options.contains(.kotlin) {
                return "                if (member == \"\($0.fullPath)\") { return \($0.fullVariablePath)() }"
            } else {
                if $0.isStaticString {
                    return preprocessorWraps(for: $0.fileName,
                                             string: "        if member == \"\($0.fullPath)\" { return \($0.fullVariablePath)().description }")
                } else {
                    return preprocessorWraps(for: $0.fileName,
                                             string: "        if member == \"\($0.fullPath)\" { return \($0.fullVariablePath)() }")
                }
            }
        }.joined(separator: "\n")
        
        let textPagesCodeRelease = textPages.filter { _ in includeOriginal(for: nil) }.map {
            if options.contains(.kotlin) {
                return "                if (member == \"\($0.fullPath)\") { return \($0.fullVariablePath)() }"
            } else {
                return preprocessorWraps(for: $0.fileName,
                                         string: "        if member == \"\($0.fullPath)\" { return \($0.fullVariablePath)() }")
            }
        }.joined(separator: "\n")
        
        let compressedPagesCode = (compressedDataPages + textPages).filter { _ in includeGzip(for: nil) }.map {
            if options.contains(.kotlin) {
                return "                if (member == \"\($0.fullPath)\") { return \($0.fullVariablePath)Gzip() }"
            } else {
                return preprocessorWraps(for: $0.fileName,
                                         string: "        if member == \"\($0.fullPath)\" { return \($0.fullVariablePath)Gzip() }")
            }
        }.joined(separator: "\n")
        let dataPagesCode = dataPages.filter { _ in includeOriginal(for: nil) }.map {
            if options.contains(.kotlin) {
                return "                if (member == \"\($0.fullPath)\") { return \($0.fullVariablePath)() }"
            } else {
                return preprocessorWraps(for: $0.fileName,
                                         string: "        if member == \"\($0.fullPath)\" { return \($0.fullVariablePath)() }")
            }
        }.joined(separator: "\n")
        let md5PagesCode = (dataPages + textPages).map {
            if options.contains(.kotlin) {
                return "                if (member == \"\($0.fullPath)\") { return \($0.fullVariablePath)MD5() }"
            } else {
                return preprocessorWraps(for: $0.fileName,
                                         string: "        if member == \"\($0.fullPath)\" { return \($0.fullVariablePath)MD5() }")
            }
        }.joined(separator: "\n")
        
        let debugSwift = templateDebugOnly << [
            "",
            textPagesCodeDebug,
            textPagesCodeRelease,
            compressedPagesCode,
            dataPagesCode,
            allDirectoryExtensions,
            md5PagesCode,
        ]

        let releaseSwift = templateReleaseOnly << [
            "",
            textPagesCodeDebug,
            textPagesCodeRelease,
            compressedPagesCode,
            dataPagesCode,
            allDirectoryExtensions,
            md5PagesCode,
        ]
        
        appendOutput(string: debugSwift.description,
                     path: debugPath,
                     type: .debug)
        
        appendOutput(string: releaseSwift.description,
                     path: releasePath,
                     type: .release)
    }
    
    private func contentsFor(name inFile: String, fileContents string: String) -> String? {
        var fileContents = string
        if fileContents.hasPrefix("#define PAMPHLET_PREPROCESSOR") {
            // This file wants to use the mcpp preprocessor
            if let cPtr = mcpp_preprocessFile(inFile, gitVersionString, gitHashString, ignoreHeader) {
                fileContents = String(cString: cPtr)
                free(cPtr)
            }
        } else {
            if fileContents.contains("#define") || fileContents.contains("#if") {
                print("warning: \(inFile) is missing PAMPHLET_PREPROCESSOR")
            }
        }
        
        if inFile.contains(".min") == false {
            minifyHtml(inFile: inFile, fileContents: &fileContents)
            minifyJs(inFile: inFile, fileContents: &fileContents)
            minifyJson(inFile: inFile, fileContents: &fileContents)
        }
        
        return fileContents
    }
    
    private func fileContentsForTextFile(_ inFile: String) -> String? {
        guard let fileContents = try? String(contentsOfFile: inFile) else { return nil }
        return contentsFor(name: inFile, fileContents: fileContents)
    }
    
    private func generateFile(_ path: FilePath,
                              _ fileOnDisk: String?,
                              _ uncompressed: String?,
                              _ compressed: String?,
                              _ dataType: String,
                              _ options: PamphletOptions) -> (String, String) {
        var scratchDebug = ""
        var scratchRelease = ""
        
        let appendBoth: (String) -> () = { string in
            scratchDebug.append(string)
            scratchRelease.append(string)
        }
                
        if options.contains(.kotlin) {
            
        } else {
            appendBoth("public extension \(path.extensionName) {\n")
        }
        
        if let uncompressed = uncompressed,
           let md5 = HalfHitch(string: uncompressed).md5() {
            if options.contains(.kotlin) {
                appendBoth("fun \(path.extensionName).\(path.variableName)MD5(): String {\n")
                appendBoth("    return \"\(md5)\"\n")
                appendBoth("}\n")
            } else {
                appendBoth("    static func \(path.variableName)MD5() -> StaticString {\n")
                appendBoth("        return \"\(md5)\"\n")
                appendBoth("    }\n")
            }
        }
        
        if uncompressed != nil && includeOriginal(for: path.fileName) {
            var reifiedDataType = dataType
            if dataType == "String" && options.contains(.kotlin) == false {
                reifiedDataType = "StaticString"
            }
            
            if let fileOnDisk = fileOnDisk {
                scratchDebug.append("    static func \(path.variableName)() -> \(dataType) {\n")
                scratchDebug.append("        let fileOnDiskPath = \"\(fileOnDisk)\"\n")
                scratchDebug.append("        return PamphletFramework.shared.process(file: fileOnDiskPath)\n")
                scratchDebug.append("    }\n")
                
                scratchRelease.append("    static func \(path.variableName)() -> \(reifiedDataType) {\n")
                scratchRelease.append("        return uncompressed\(path.fullVariableName)\n")
                scratchRelease.append("    }\n")
                
            } else {
                appendBoth("    static func \(path.variableName)() -> \(reifiedDataType) {\n")
                appendBoth("        return uncompressed\(path.fullVariableName)\n")
                appendBoth("    }\n")
            }
        }
        
        if compressed != nil && includeGzip(for: path.fileName) {
            if options.contains(.kotlin) {
                appendBoth("fun \(path.extensionName).\(path.variableName)Gzip(): ByteArray {\n")
                appendBoth("    return compressed\(path.fullVariableName)\n")
                appendBoth("}\n")
            } else {
                scratchRelease.append("    static func \(path.variableName)Gzip() -> Data {\n")
                scratchRelease.append("        return compressed\(path.fullVariableName)\n")
                scratchRelease.append("    }\n")
                
                if dataType.contains("String") {
                    scratchDebug.append("    static func \(path.variableName)Gzip() -> Data {\n")
                    scratchDebug.append("        return \(path.variableName)().description.data(using: .utf8) ?? Data()\n")
                    scratchDebug.append("    }\n")
                } else {
                    scratchDebug.append("    static func \(path.variableName)Gzip() -> Data {\n")
                    scratchDebug.append("        return \(path.variableName)()\n")
                    scratchDebug.append("    }\n")
                }
            }
        }
        
        if options.contains(.kotlin) {
            
        } else {
            appendBoth("}\n")
            appendBoth("\n")
        }
        
        if let uncompressed = uncompressed, includeOriginal(for: path.fileName) {
            var conditionalAppend = appendBoth
            if fileOnDisk != nil {
                conditionalAppend = { string in
                    scratchRelease.append(string)
                }
            }
            if dataType == "String" {
                if options.contains(.kotlin) {
                    conditionalAppend("private val uncompressed\(path.fullVariableName) = \"\n\(uncompressed)\n\"\n\n")
                } else {
                    conditionalAppend("private let uncompressed\(path.fullVariableName): StaticString = ###\"\"\"\n\(uncompressed)\n\"\"\"###\n\n")
                }
            } else {
                if options.contains(.kotlin) {
                    conditionalAppend("private val uncompressed\(path.fullVariableName) = Base64.decode(\"\(uncompressed)\", Base64.DEFAULT)\n\n")
                } else {
                    conditionalAppend("private let uncompressed\(path.fullVariableName) = Data(base64Encoded:\"\(uncompressed)\")!\n\n")
                }
            }
        }
        if let compressed = compressed, includeGzip(for: path.fileName) {
            if options.contains(.kotlin) {
                scratchRelease.append("private val compressed\(path.fullVariableName) = Base64.decode(\"\(compressed)\", Base64.DEFAULT)\n\n")
            } else {
                scratchRelease.append("private let compressed\(path.fullVariableName) = Data(base64Encoded:\"\(compressed)\")!\n\n")
            }
        }
        
        return (
            preprocessorWraps(for: path.fileName,
                              string: scratchDebug),
            preprocessorWraps(for: path.fileName,
                              string: scratchRelease)
        )
    }
    
    private func processStringAsFile(_ path: FilePath,
                                     _ inFile: String?,
                                     _ fileContents: String,
                                     _ options: PamphletOptions) -> (String, String)? {
        return generateFile(path,
                            inFile,
                            fileContents,
                            gzip(path: path,
                                 contents: fileContents),
                            "String",
                            options)
    }
    
    private func processTextFile(_ path: FilePath,
                                 _ inFile: String,
                                 _ options: PamphletOptions) -> (String, String)? {
        if let fileContents = fileContentsForTextFile(inFile) {
            return processStringAsFile(path,
                                       inFile,
                                       fileContents,
                                       options)
        }
        return nil
    }
    
    private func fileContentsForDataFile(_ inFile: String) -> String? {
        guard let fileData = try? Data(contentsOf: URL(fileURLWithPath: inFile)) else { return nil }
        return fileData.base64EncodedString()
    }
    
    private func gzipContentsForDataFile(_ inFile: String) -> String? {
        guard let fileData = try? Data(contentsOf: URL(fileURLWithPath: inFile)) else { return nil }
        guard let fileDataAsGzip = try? fileData.gzipped(level: .bestCompression) else { return nil }
        guard fileDataAsGzip.count < fileData.count else {
            return nil
        }
        return fileDataAsGzip.base64EncodedString()
    }
    
    private func processDataFile(_ path: FilePath,
                                 _ inFile: String,
                                 _ options: PamphletOptions,
                                 _ compressedDataPages: BoxedArray<FilePath>) -> (String, String)? {
        let gzipContent = gzipContentsForDataFile(inFile)
        if gzipContent != nil {
            compressedDataPages.append(path)
        }
        return generateFile(path,
                            inFile,
                            fileContentsForDataFile(inFile),
                            gzipContent,
                            "Data",
                            options)
    }
    
    private func process(directory: URL,
                         files: BoxedArray<URL>,
                         pamphletName: String,
                         pamphletExecPathValues: URLResourceValues,
                         inDirectoryFullPath: String,
                         generateFilesDirectory: String,
                         options: PamphletOptions,
                         textPages: BoxedArray<FilePath>,
                         dataPages: BoxedArray<FilePath>,
                         compressedDataPages: BoxedArray<FilePath>) {
        
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
                if let (contentDebug, contentRelease) = processStringAsFile(directoryFilePath, nil, jsonDirectoryEncoded, options) {
                    
                    appendOutput(string: contentDebug,
                                 path: debugPath,
                                 type: .debug)
                    
                    appendOutput(string: contentRelease,
                                 path: releasePath,
                                 type: .release)
                    
                    directoryFilePath.isStaticString = true
                    textPages.append(directoryFilePath)
                }
            }
            return
        }
        
        // When we collapse a directory, all swift files in the directory go into a single files
        let outputDirectory = URL(fileURLWithPath: generateFilesDirectory).path
        let outputFile = "\(outputDirectory)/\(fileDirectoryPartialPath).collapsed\(options.fileExt())"
                    
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
        var collapsedDebugContent = ""
        var collapsedReleaseContent = ""
        let appendLock = NSLock()
        for fileURL in files {
            
            queue1.addOperation {
                let partialPath = String(fileURL.path.dropFirst(inDirectoryFullPath.count))
                let filePath = FilePath(pamphletName, partialPath, options)
                
                if let (contentDebug, contentRelease) = self.processTextFile(filePath, fileURL.path, options) {
                    appendLock.lock()
                    collapsedDebugContent += contentDebug + "\n"
                    collapsedReleaseContent += contentRelease + "\n"
                    textPages.append(filePath)
                    appendLock.unlock()
                } else if let (contentDebug, contentRelease) = self.processDataFile(filePath, fileURL.path, options, compressedDataPages) {
                    appendLock.lock()
                    collapsedDebugContent += contentDebug + "\n"
                    collapsedReleaseContent += contentRelease + "\n"
                    dataPages.append(filePath)
                    appendLock.unlock()
                } else {
                    fatalError("Processing failed for file: \(fileURL.path)")
                }
            }
        }
        
        queue1.waitUntilAllOperationsAreFinished()
        
        appendOutput(string: collapsedDebugContent,
                     path: debugPath,
                     type: .debug)
        
        appendOutput(string: collapsedReleaseContent,
                     path: releasePath,
                     type: .release)
        
        return
    
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
    
    
    // MARK: - PUBLIC API
    
    private func measure(message: String, _ block: ()->()) {
        let startTime = Date()
        block()
        let timeElapsed = abs(startTime.timeIntervalSinceNow)
        
        let log = "[\(timeElapsed)s] \(message)\n"
        let logPath = "\(pamphletTempPath)Pamphlet.log"
        
        if FileManager.default.fileExists(atPath: logPath) == false {
            try? "".write(toFile: logPath, atomically: false, encoding: .utf8)
        }
        
        if let stringData = log.data(using: .utf8),
           let handle = FileHandle(forWritingAtPath: logPath) {
            handle.seekToEndOfFile()
            handle.write(stringData)
            handle.closeFile()
        }
    }
    
    @discardableResult
    public func preprocess(file inFile: String) -> String {
        var result: String = ""
        do {
            var fileContents = try String(contentsOfFile: inFile)
            
            if fileContents.hasPrefix("#define PAMPHLET_PREPROCESSOR") {
                if let cPtr = mcpp_preprocessFile(inFile, gitVersionString, gitHashString, ignoreHeader) {
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
    
    @discardableResult
    public func fullprocess(file inFile: String) -> String {
        var result: String = ""
        do {
            var fileContents = try String(contentsOfFile: inFile)
            
            if fileContents.hasPrefix("#define PAMPHLET_PREPROCESSOR") {
                if let cPtr = mcpp_preprocessFile(inFile, gitVersionString, gitHashString, ignoreHeader) {
                    fileContents = String(cString: cPtr)
                    free(cPtr)
                }
            }
            
            if inFile.contains(".min") == false {
                minifyHtml(inFile: inFile, fileContents: &fileContents)
                minifyJs(inFile: inFile, fileContents: &fileContents)
                minifyJson(inFile: inFile, fileContents: &fileContents)
            }
            
            result = fileContents
        } catch {
            result = "unable to parse file"
        }
        print(result)
        return result
    }
    
    @discardableResult
    public func process(name: String, string: String) -> String {
        if let stringContents = contentsFor(name: name, fileContents: string) {
            return stringContents
        }
        return String()
    }
    
    @discardableResult
    public func process(file: String) -> String {
        if let stringContents = fileContentsForTextFile(file) {
            return stringContents
        }
        return String()
    }
    
    @discardableResult
    public func process(file: String) -> Data {
        guard let fileData = try? Data(contentsOf: URL(fileURLWithPath: file)) else { return Data() }
        return fileData
    }
    
    public func process(prefix: String?,
                        extensions: [String],
                        inDirectory: String,
                        outDirectory: String,
                        gitPath: String,
                        options: PamphletOptions) {
        
        gitVersionString = git(repoPath: gitPath) ?? ""
        gitHashString = gitHash(repoPath: gitPath)
        
        measure(message: inDirectory) {
            
            if let pamphletJsonHitch = Hitch(contentsOfFile: "\(inDirectory)/pamphlet.json") {
                pamphletJson = Spanker.parse(halfhitch: pamphletJsonHitch.halfhitch()) ?? ^[]
            }
            
            self.options = options
            
            let pamphletName = (prefix != nil ? prefix! + "Pamphlet" : "Pamphlet")
            
            let resourceKeys: [URLResourceKey] = [.contentModificationDateKey, .creationDateKey, .isDirectoryKey]
            let generateFilesDirectory = outDirectory
            
            let pamphletExecPath = ProcessInfo.processInfo.arguments[0]
            guard let pamphletExecPathValues = try? URL(fileURLWithPath: pamphletExecPath).resourceValues(forKeys: Set(resourceKeys)) else { fatalError() }
                                    
            let pamphletFilePath = generateFilesDirectory + "/\(pamphletName)\(options.fileExt())"
            
            debugPath = "\(pamphletTempPath)\(UUID().uuidString).pamphlet.debug.swift"
            releasePath = "\(pamphletTempPath)\(UUID().uuidString).pamphlet.release.swift"
            
            if releaseOnly(for: nil) == false {
                createOutput(path: debugPath,
                             type: .debug)
            }
            
            createOutput(path: releasePath,
                         type: .release)
            
            if releaseOnly(for: nil) {
                fileHeaderRelease = fileHeaderReleaseOnly
                fileFooterRelease = fileFooterReleaseOnly
            }
            
            if options.contains(.kotlin) {
                if let packagePath = options.kotlinPackage {
                    let header = """
                    package \(packagePath)
                    import android.util.Base64
                    
                    """
                    appendOutput(string: header,
                                 path: debugPath,
                                 type: .debug)
                    appendOutput(string: header,
                                 path: releasePath,
                                 type: .release)
                }
            } else {
                appendOutput(string: fileHeaderDebug,
                             path: debugPath,
                             type: .debug)
                appendOutput(string: fileHeaderRelease,
                             path: releasePath,
                             type: .release)
            }
                        
            let enumerator = FileManager.default.enumerator(at: URL(fileURLWithPath: inDirectory),
                                                            includingPropertiesForKeys: resourceKeys,
                                                            options: [.skipsHiddenFiles],
                                                            errorHandler: { (url, error) -> Bool in
                                                                print("directoryEnumerator error at \(url): ", error)
                                                                return true
            })!
            
            let textPages = BoxedArray<FilePath>()
            let dataPages = BoxedArray<FilePath>()
            let compressedDataPages = BoxedArray<FilePath>()
            let directoryPages = BoxedArray<FilePath>()
            
            //print("in: " + inDirectory)
            //print("out: " + generateFilesDirectory)
            
            let inDirectoryFullPath = URL(fileURLWithPath: inDirectory).path
                    
            // we want to process all files in a directory at the same time, so we need to pre-walk
            // the enumeration
            
            var allDirectories: [URL] = []
            var filesByDirectory: [URL: BoxedArray<URL>] = [:]
            
            for case let fileURL as URL in enumerator {
                if fileURL.lastPathComponent == "pamphlet.json" {
                    continue
                }
                
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
                queue2.addOperation {
                    self.process(directory: directoryURL,
                                 files: files,
                                 pamphletName: pamphletName,
                                 pamphletExecPathValues: pamphletExecPathValues,
                                 inDirectoryFullPath: inDirectoryFullPath,
                                 generateFilesDirectory: generateFilesDirectory,
                                 options: options,
                                 textPages: textPages,
                                 dataPages: dataPages,
                                 compressedDataPages: compressedDataPages)
                }
            }
            queue2.waitUntilAllOperationsAreFinished()
                        
            for directory in allDirectories {
                let partialPath = String(directory.path.dropFirst(inDirectoryFullPath.count))
                let filePath = FilePath(pamphletName, partialPath, options)
                directoryPages.append(filePath)
            }
            
            createPamphletFile(pamphletName,
                               textPages.array,
                               dataPages.array,
                               compressedDataPages.array,
                               directoryPages.array)
            
            appendOutput(string: fileFooterDebug,
                         path: debugPath,
                         type: .debug)
            
            appendOutput(string: fileFooterRelease,
                         path: releasePath,
                         type: .release)
            
            
            // Copy the temp files out their final outputs
            let finalDebugPath = pathOutput(path: pamphletFilePath,
                                            type: .debug)
            let finalReleasePath = pathOutput(path: pamphletFilePath,
                                              type: .release)
            
            if let contents = try? String(contentsOfFile: debugPath) {
                try? contents.write(toFile: finalDebugPath, atomically: false, encoding: .utf8)
            }
            try? FileManager.default.removeItem(atPath: debugPath)
            
            if let contents = try? String(contentsOfFile: releasePath) {
                try? contents.write(toFile: finalReleasePath, atomically: false, encoding: .utf8)
            }
            try? FileManager.default.removeItem(atPath: releasePath)
            
            // NOTE: kotlin appears to have a hidden limit to the size of their source files,
            // somewhere around 20 MB the file just gets ignored. To handle this, we split
            // the generated files up in post
            sanityCheckKotlinFile(finalDebugPath)
            sanityCheckKotlinFile(finalReleasePath)
        }
    }
    
    func sanityCheckKotlinFile(_ filepath: String) {
        guard filepath.hasSuffix(".kt") else { return }
        guard let hitch = Hitch(contentsOfFile: filepath) else { return }
        guard hitch.count > 1024 * 1024 * 20 else { return }
        
        // Ok, the file is too large. Split into 15 MB chunks
        let lines: [HalfHitch] = hitch.components(separatedBy: "\n")
        
        let header = Hitch()
        
        let scratch = Hitch(capacity: 1024 * 1024 * 20)
        var chunk = 0
        
        let saveChunk: () -> () = {
            let chunkFilePath = "\(filepath).\(chunk).kt"
            try? scratch.toTempString().write(toFile: chunkFilePath,
                                              atomically: false,
                                              encoding: .utf8)
            chunk += 1
            scratch.count = 0
            scratch.append(header)
        }
        
        for line in lines {
            if line.starts(with: "package") ||
                line.starts(with: "import") {
                header.append(line)
                header.append(.newLine)
            }
            
            scratch.append(line)
            scratch.append(.newLine)
            
            if scratch.count > 1024 * 1024 * 15 {
                saveChunk()
            }
        }
        saveChunk()
        
        try? FileManager.default.removeItem(atPath: filepath)
    }
}
