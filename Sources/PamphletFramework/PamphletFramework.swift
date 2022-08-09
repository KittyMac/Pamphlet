import Foundation
import libmcpp
import Hitch
import JXKit

public class PamphletFramework {
    
    var fileHeader = """
    import Foundation
    #if DEBUG && canImport(PamphletFramework)
    import PamphletFramework
    #endif
    // swiftlint:disable all
    
    """
    
    var options = PamphletOptions.default
    
    var pamphletFilePath: String = ""
    
    public init() {
        
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
            
            #if DEBUG && canImport(PamphletFramework)
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
                #if DEBUG && canImport(PamphletFramework)
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
                if $0.isStaticString {
                    return "        case \"\($0.fullPath)\": return \($0.fullVariablePath)()"
                } else {
                    return "        case \"\($0.fullPath)\": return \($0.fullVariablePath)()"
                }
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
        
        minifyHtml(inFile: inFile, fileContents: &fileContents)
        minifyJs(inFile: inFile, fileContents: &fileContents)
        minifyJson(inFile: inFile, fileContents: &fileContents)
        
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
                scratch.append(fileHeader)
            }
        }
        
        if options.contains(.kotlin) {
            
        } else {
            scratch.append("public extension \(path.extensionName) {\n")
        }
        
        if uncompressed != nil && options.contains(.includeOriginal) {
            var reifiedDataType = dataType
            if dataType == "String" {
                reifiedDataType = "StaticString"
            }
            
            if let fileOnDisk = fileOnDisk, options.contains(.releaseOnly) == false {
                scratch.append("    #if DEBUG && canImport(PamphletFramework)\n")
                scratch.append("    static func \(path.variableName)() -> \(dataType) {\n")
                scratch.append("        let fileOnDiskPath = \"\(fileOnDisk)\"\n")
                scratch.append("        print(fileOnDiskPath)\n")
                scratch.append("        return PamphletFramework().process(file: fileOnDiskPath)\n")
                scratch.append("    }\n")
                
                scratch.append("    #else\n")
                scratch.append("    static func \(path.variableName)() -> \(reifiedDataType) {\n")
                scratch.append("        return uncompressed\(path.fullVariableName)\n")
                scratch.append("    }\n")
                scratch.append("    #endif\n")
                
            } else {
                
                scratch.append("    static func \(path.variableName)() -> \(reifiedDataType) {\n")
                scratch.append("        return uncompressed\(path.fullVariableName)\n")
                scratch.append("    }\n")
            }
            
        }
        
        if compressed != nil && options.contains(.includeGzip) {
            if options.contains(.kotlin) {
                scratch.append("fun Pamphlet.\(path.variableName)Gzip(): ByteArray {\n")
                scratch.append("    return compressed\(path.fullVariableName)\n")
                scratch.append("}\n")
            } else {
                scratch.append("    static func \(path.variableName)Gzip() -> Data {\n")
                scratch.append("        return compressed\(path.fullVariableName)\n")
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
                    scratch.append("private val uncompressed\(path.fullVariableName) = \"\n\(uncompressed)\n\"\n")
                } else {
                    scratch.append("private let uncompressed\(path.fullVariableName): StaticString = ###\"\"\"\n\(uncompressed)\n\"\"\"###\n")
                }
            } else {
                if options.contains(.kotlin) {
                    scratch.append("private val uncompressed\(path.fullVariableName) = Base64.decode(\"\(uncompressed)\", Base64.DEFAULT)\n")
                } else {
                    scratch.append("private let uncompressed\(path.fullVariableName) = Data(base64Encoded:\"\(uncompressed)\")!\n")
                }
            }
        }
        if let compressed = compressed, options.contains(.includeGzip) {
            if options.contains(.kotlin) {
                scratch.append("private val compressed\(path.fullVariableName) = Base64.decode(\"\(compressed)\", Base64.DEFAULT)\n")
            } else {
                scratch.append("private let compressed\(path.fullVariableName) = Data(base64Encoded:\"\(compressed)\")!\n")
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
