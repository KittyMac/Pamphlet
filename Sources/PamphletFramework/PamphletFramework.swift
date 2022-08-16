import Foundation
import libmcpp
import Hitch

enum OutputType: String {
    case debug = "debug"
    case release = "release"
}

public class PamphletFramework {
    public static let shared = PamphletFramework()

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
    
    var options = PamphletOptions.default
    
    var pamphletFilePath: String = ""
    
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
        
        let outputPath = pathOutput(path: path,
                                    type: type)
        try? "".write(toFile: outputPath, atomically: false, encoding: .utf8)
    }
    
    private func appendOutput(data: Data,
                              path: String,
                              type: OutputType) {
        // path like: /path/to/Pamphlet.swift
        // for debug adjust it to: /path/to/Pamphlet.debug.swift
        // for release adjust it to: /path/to/Pamphlet.release.swift
        writeLock.lock(); defer { writeLock.unlock() }
        
        let outputPath = pathOutput(path: path,
                                    type: type)
        if let handle = FileHandle(forWritingAtPath: outputPath) {
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
        
        let templateDebugOnlySwift = """
        {0}
        
        public enum \(pamphletName) {
            public static let version = "\(version)"
            
            public static func get(string member: String) -> String? {
                switch member {
        {1}
                default: break
                }
                return nil
            }
            public static func get(gzip member: String) -> Data? {
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
        
        let templateReleaseOnlySwift = """
        {0}
        
        public enum \(pamphletName) {
            public static let version = "\(version)"

            public static func get(string member: String) -> StaticString? {
                switch member {
        {2}
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
        
        let templateDebugOnlyKotlin = """
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
            val version = "\(version)"

            fun getAsString(member: String): String? {
                return when (member) {
        {2}
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
        
        let textPagesCodeDebug = textPages.filter { _ in options.contains(.includeOriginal) }.map {
            if options.contains(.kotlin) {
                return "                \"\($0.fullPath)\" -> return \($0.fullVariablePath)()"
            } else {
                if $0.isStaticString {
                    return "        case \"\($0.fullPath)\": return \($0.fullVariablePath)().description"
                } else {
                    return "        case \"\($0.fullPath)\": return \($0.fullVariablePath)()"
                }
            }
        }.joined(separator: "\n")
        
        let textPagesCodeRelease = textPages.filter { _ in options.contains(.includeOriginal) }.map {
            if options.contains(.kotlin) {
                return "                \"\($0.fullPath)\" -> return \($0.fullVariablePath)()"
            } else {
                return "        case \"\($0.fullPath)\": return \($0.fullVariablePath)()"
            }
        }.joined(separator: "\n")
        
        let compressedPagesCode = textPages.filter { _ in options.contains(.includeGzip) }.map {
            if options.contains(.kotlin) {
                return "                \"\($0.fullPath)\" -> return \($0.fullVariablePath)Gzip()"
            } else {
                return "        case \"\($0.fullPath)\": return \($0.fullVariablePath)Gzip()"
            }
        }.joined(separator: "\n")
        let dataPagesCode = dataPages.filter { _ in options.contains(.includeOriginal) }.map {
            if options.contains(.kotlin) {
                return "                \"\($0.fullPath)\" -> return \($0.fullVariablePath)()"
            } else {
                return "        case \"\($0.fullPath)\": return \($0.fullVariablePath)()"
            }
        }.joined(separator: "\n")
        
        let debugSwift = templateDebugOnly << [
            "",
            textPagesCodeDebug,
            textPagesCodeRelease,
            compressedPagesCode,
            dataPagesCode,
            allDirectoryExtensions
        ]

        let releaseSwift = templateReleaseOnly << [
            "",
            textPagesCodeDebug,
            textPagesCodeRelease,
            compressedPagesCode,
            dataPagesCode,
            allDirectoryExtensions
        ]
        
        appendOutput(string: debugSwift.description,
                     path: outFile,
                     type: .debug)
        
        appendOutput(string: releaseSwift.description,
                     path: outFile,
                     type: .release)
    }
    
    private func contentsFor(name inFile: String, fileContents string: String) -> String? {
        var fileContents = string
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
        minifyJs(inFile: inFile, fileContents: &fileContents)
        minifyJson(inFile: inFile, fileContents: &fileContents)
        
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
        
        if uncompressed != nil && options.contains(.includeOriginal) {
            var reifiedDataType = dataType
            if dataType == "String" {
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
        
        if compressed != nil && options.contains(.includeGzip) {
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
        
        if let uncompressed = uncompressed, options.contains(.includeOriginal) {
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
        if let compressed = compressed, options.contains(.includeGzip) {
            if options.contains(.kotlin) {
                scratchRelease.append("private val compressed\(path.fullVariableName) = Base64.decode(\"\(compressed)\", Base64.DEFAULT)\n\n")
            } else {
                scratchRelease.append("private let compressed\(path.fullVariableName) = Data(base64Encoded:\"\(compressed)\")!\n\n")
            }
        }
        
        return (scratchDebug, scratchRelease)
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
    
    private func processDataFile(_ path: FilePath,
                                 _ inFile: String,
                                 _ options: PamphletOptions) -> (String, String)? {
        return generateFile(path,
                            inFile,
                            fileContentsForDataFile(inFile),
                            nil,
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
                if let (contentDebug, contentRelease) = processStringAsFile(directoryFilePath, nil, jsonDirectoryEncoded, options) {
                    
                    appendOutput(string: contentDebug,
                                 path: pamphletFilePath,
                                 type: .debug)
                    
                    appendOutput(string: contentRelease,
                                 path: pamphletFilePath,
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
                } else if let (contentDebug, contentRelease) = self.processDataFile(filePath, fileURL.path, options) {
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
                     path: pamphletFilePath,
                     type: .debug)
        
        appendOutput(string: collapsedReleaseContent,
                     path: pamphletFilePath,
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
        let logPath = "/tmp/Pamphlet.log"
        
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
                        options: PamphletOptions) {
        
        measure(message: inDirectory) {
            self.options = options
            
            let pamphletName = (prefix != nil ? prefix! + "Pamphlet" : "Pamphlet")
            
            let resourceKeys: [URLResourceKey] = [.contentModificationDateKey, .creationDateKey, .isDirectoryKey]
            let generateFilesDirectory = outDirectory
            
            let pamphletExecPath = ProcessInfo.processInfo.arguments[0]
            guard let pamphletExecPathValues = try? URL(fileURLWithPath: pamphletExecPath).resourceValues(forKeys: Set(resourceKeys)) else { fatalError() }
                                    
            pamphletFilePath = generateFilesDirectory + "/\(pamphletName)\(options.fileExt())"
            
            let debugPath = pathOutput(path: pamphletFilePath,
                                       type: .debug)
            let releasePath = pathOutput(path: pamphletFilePath,
                                         type: .release)
            
            try? FileManager.default.removeItem(atPath: debugPath)
            try? FileManager.default.removeItem(atPath: releasePath)
            
            if options.contains(.releaseOnly) == false {
                createOutput(path: pamphletFilePath,
                             type: .debug)
            }
            
            createOutput(path: pamphletFilePath,
                         type: .release)
            
            if options.contains(.releaseOnly) {
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
                                 path: pamphletFilePath,
                                 type: .debug)
                    appendOutput(string: header,
                                 path: pamphletFilePath,
                                 type: .release)
                }
            } else {
                appendOutput(string: fileHeaderDebug,
                             path: pamphletFilePath,
                             type: .debug)
                appendOutput(string: fileHeaderRelease,
                             path: pamphletFilePath,
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
                queue2.addOperation {
                    self.process(directory: directoryURL,
                                 files: files,
                                 pamphletName: pamphletName,
                                 pamphletExecPathValues: pamphletExecPathValues,
                                 inDirectoryFullPath: inDirectoryFullPath,
                                 generateFilesDirectory: generateFilesDirectory,
                                 options: options,
                                 textPages: textPages,
                                 dataPages: dataPages)
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
                               directoryPages.array,
                               pamphletFilePath)
            
            appendOutput(string: fileFooterDebug,
                         path: pamphletFilePath,
                         type: .debug)
            
            appendOutput(string: fileFooterRelease,
                         path: pamphletFilePath,
                         type: .release)
        }
    }
}
