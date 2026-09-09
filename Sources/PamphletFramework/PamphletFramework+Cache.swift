import Foundation
import Hitch

// A content-addressed cache for the result of processing a single resource file.
//
// The expensive part of Pamphlet's work (terser/html-minifier via JavaScriptCore,
// gzip -9, base64, md5) is a pure function of:
//
//   * the *expanded* file content (post-mcpp, so #include and git version
//     changes are folded in automatically)
//   * the file's path (it appears in the generated symbol names)
//   * the resolved pamphlet.json options for that file
//   * the identity of the Pamphlet tool binary itself
//
// So we hash all of that and memoize the generated Swift/Kotlin snippet on disk
// inside the plugin work directory, which survives between builds.

struct CachedFile {
    let isText: Bool
    let hasGzip: Bool
    let debug: String
    let release: String
}

final class PamphletCache {

    private static let magic = "PAMPHLET-CACHE-1"

    private let directory: String
    private let globalFingerprint: String
    private let enabled: Bool

    private let lock = NSLock()
    private var touched = Set<String>()

    // `globalFingerprint` must capture everything that affects codegen but is
    // not per-file: the pamphlet name/prefix, the option set, the kotlin
    // package, --ignore-header, and the mtime+size of the tool binary.
    init(directory: String,
         globalFingerprint: String) {
        self.directory = directory.hasSuffix("/") ? directory : directory + "/"
        self.globalFingerprint = globalFingerprint

        if ProcessInfo.processInfo.environment["PAMPHLET_NO_CACHE"] != nil {
            self.enabled = false
            return
        }

        var isEnabled = true
        do {
            try FileManager.default.createDirectory(atPath: self.directory,
                                                    withIntermediateDirectories: true)
        } catch {
            // A read-only or otherwise unusable work directory must not be fatal;
            // we simply degrade to the previous "always reprocess" behaviour.
            print("warning: pamphlet cache disabled (\(error.localizedDescription))")
            isEnabled = false
        }
        self.enabled = isEnabled
    }

    // MARK: - Keys

    // `contentHash` should be the md5 of the expanded content for text files, or
    // of the raw bytes for data files.
    func key(contentHash: String,
             absolutePath: String,
             fileFingerprint: String) -> String? {
        guard enabled else { return nil }

        let material = [
            Self.magic,
            contentHash,
            absolutePath,
            fileFingerprint,
            globalFingerprint
        ].joined(separator: "\u{0}")

        return Hitch(string: material).md5()?.toString()
    }

    // MARK: - Load / store

    func load(key: String) -> CachedFile? {
        guard enabled else { return nil }

        let path = directory + key

        guard let blob = try? Data(contentsOf: URL(fileURLWithPath: path),
                                   options: .mappedIfSafe) else { return nil }

        // Header is a single newline-terminated ASCII line:
        //   PAMPHLET-CACHE-1 <t|d> <0|1> <debugBytes> <releaseBytes>
        guard let newline = blob.firstIndex(of: 0x0A) else { return nil }
        guard let header = String(data: blob.subdata(in: 0..<newline), encoding: .utf8) else { return nil }

        let fields = header.split(separator: " ")
        guard fields.count == 5,
              fields[0] == Self.magic,
              let debugCount = Int(fields[3]),
              let releaseCount = Int(fields[4]) else { return nil }

        let isText = (fields[1] == "t")
        let hasGzip = (fields[2] == "1")

        let debugStart = newline + 1
        let debugEnd = debugStart + debugCount
        let releaseEnd = debugEnd + releaseCount

        // A truncated entry (interrupted build, full disk) must be treated as a
        // miss rather than trusted.
        guard releaseEnd == blob.count else { return nil }

        guard let debug = String(data: blob.subdata(in: debugStart..<debugEnd), encoding: .utf8),
              let release = String(data: blob.subdata(in: debugEnd..<releaseEnd), encoding: .utf8) else { return nil }

        markTouched(key)

        return CachedFile(isText: isText,
                          hasGzip: hasGzip,
                          debug: debug,
                          release: release)
    }

    func store(key: String,
               _ entry: CachedFile) {
        guard enabled else { return }

        let debugData = Data(entry.debug.utf8)
        let releaseData = Data(entry.release.utf8)

        let header = [
            Self.magic,
            entry.isText ? "t" : "d",
            entry.hasGzip ? "1" : "0",
            "\(debugData.count)",
            "\(releaseData.count)"
        ].joined(separator: " ") + "\n"

        var blob = Data(header.utf8)
        blob.append(debugData)
        blob.append(releaseData)

        // Write to a unique temp name and rename into place. Two threads racing
        // on the same key write byte-identical content, so last-rename-wins is
        // safe, and a cancelled build can never leave a torn entry behind.
        let finalPath = directory + key
        let tempPath = directory + key + ".tmp-\(UUID().uuidString)"

        do {
            try blob.write(to: URL(fileURLWithPath: tempPath))
            _ = try? FileManager.default.removeItem(atPath: finalPath)
            try FileManager.default.moveItem(atPath: tempPath, toPath: finalPath)
            markTouched(key)
        } catch {
            try? FileManager.default.removeItem(atPath: tempPath)
        }
    }

    private func markTouched(_ key: String) {
        lock.lock(); defer { lock.unlock() }
        touched.insert(key)
    }

    // MARK: - Pruning

    // Called once at the end of a run. Anything we did not read or write this
    // time is either a stale option set or a deleted resource; drop it once it
    // is older than `maxAge` so a branch switch does not permanently bloat the
    // work directory.
    func prune(maxAge: TimeInterval = 60 * 60 * 24 * 7) {
        guard enabled else { return }

        lock.lock()
        let keep = touched
        lock.unlock()

        guard let names = try? FileManager.default.contentsOfDirectory(atPath: directory) else { return }

        let cutoff = Date().addingTimeInterval(-maxAge)

        for name in names {
            if keep.contains(name) { continue }

            let path = directory + name

            // Sweep up any temp files abandoned by an interrupted build.
            if name.contains(".tmp-") {
                try? FileManager.default.removeItem(atPath: path)
                continue
            }

            guard let values = try? URL(fileURLWithPath: path)
                .resourceValues(forKeys: [.contentModificationDateKey]),
                  let modified = values.contentModificationDate else { continue }

            if modified < cutoff {
                try? FileManager.default.removeItem(atPath: path)
            }
        }
    }
}
