import Foundation
import CryptoKit
import ZIPFoundation

struct IPAReport: Sendable {
    let name: String
    let bundleID: String
    let version: String
    let minimumOS: String
    let size: Int64
    let sha256: String
    let usageDescriptions: [String]
    let frameworks: [String]
    let profileSummary: [String]
    let provisionedEntitlements: String
    let hasSignatureFiles: Bool
}

enum IPAInspectorService {
    static let metadataLimit = 8 * 1024 * 1024

    static func inspect(_ url: URL) throws -> IPAReport {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        guard size > 0, size <= 2_000_000_000 else { throw ToolError.message("Choose an IPA smaller than 2 GB.") }
        let archive = try Archive(url: url, accessMode: .read)
        var infoEntries: [Entry] = []
        var frameworks = Set<String>()
        var signaturePaths = Set<String>()
        var entryCount = 0
        for entry in archive {
            entryCount += 1
            guard entryCount <= 100_000 else { throw ToolError.message("This archive contains too many files.") }
            let parts = entry.path.split(separator: "/").map(String.init)
            guard !entry.path.hasPrefix("/"), !parts.contains("..") else {
                throw ToolError.message("This archive contains an unsafe path.")
            }
            if parts.count == 3, parts[0] == "Payload", parts[1].hasSuffix(".app"), parts[2] == "Info.plist", entry.type == .file {
                infoEntries.append(entry)
            }
            if parts.count >= 5, parts[0] == "Payload", parts[2] == "Frameworks" {
                frameworks.insert(parts[3])
            }
            if parts.count == 4, parts[0] == "Payload", parts[2] == "_CodeSignature", parts[3] == "CodeResources" {
                signaturePaths.insert(parts[0] + "/" + parts[1])
            }
        }
        guard infoEntries.count == 1, let infoEntry = infoEntries.first else {
            throw ToolError.message("Expected exactly one main app inside Payload. This is not a supported IPA.")
        }
        let info = try dictionary(read(infoEntry, archive: archive))
        let root = String(infoEntry.path.dropLast("/Info.plist".count))
        var profileSummary: [String] = ["No embedded provisioning profile"]
        var entitlements = "No embedded provisioning profile. Executable entitlements are not decoded in this version."
        if let profileEntry = archive[root + "/embedded.mobileprovision"] {
            do {
                let profile = try profileDictionary(read(profileEntry, archive: archive))
                profileSummary = []
                if let name = profile["Name"] as? String { profileSummary.append("Profile: \(name)") }
                if let teams = profile["TeamIdentifier"] as? [String] { profileSummary.append("Team: \(teams.joined(separator: ", "))") }
                if let date = profile["ExpirationDate"] as? Date { profileSummary.append("Expires: \(date.formatted(date: .abbreviated, time: .shortened))") }
                if let devices = profile["ProvisionedDevices"] as? [String] { profileSummary.append("Registered devices: \(devices.count)") }
                if profile["ProvisionsAllDevices"] as? Bool == true { profileSummary.append("Profile declares all-device provisioning") }
                if let values = profile["Entitlements"] as? [String: Any] {
                    let xml = try PropertyListSerialization.data(fromPropertyList: values, format: .xml, options: 0)
                    entitlements = String(decoding: xml, as: UTF8.self)
                }
            } catch {
                profileSummary = ["Embedded profile could not be decoded: \(error.localizedDescription)"]
            }
        }
        let permissions = info.keys.filter { $0.hasPrefix("NS") && $0.hasSuffix("UsageDescription") }.sorted().map {
            "\($0): \(info[$0] as? String ?? "Unknown")"
        }
        return IPAReport(
            name: info["CFBundleDisplayName"] as? String ?? info["CFBundleName"] as? String ?? "Unnamed app",
            bundleID: info["CFBundleIdentifier"] as? String ?? "Unknown",
            version: "\(info["CFBundleShortVersionString"] as? String ?? "?") (\(info["CFBundleVersion"] as? String ?? "?"))",
            minimumOS: info["MinimumOSVersion"] as? String ?? "Not declared",
            size: Int64(size), sha256: try hash(url), usageDescriptions: permissions,
            frameworks: frameworks.sorted(), profileSummary: profileSummary,
            provisionedEntitlements: entitlements, hasSignatureFiles: signaturePaths.contains(root)
        )
    }

    // Read only selected metadata into memory. Never extract archive paths to disk.
    static func read(_ entry: Entry, archive: Archive) throws -> Data {
        guard entry.type == .file, entry.uncompressedSize <= UInt64(metadataLimit) else {
            throw ToolError.message("Archive metadata is too large or is not a regular file.")
        }
        var data = Data()
        let crc = try archive.extract(entry) { chunk in
            guard data.count + chunk.count <= metadataLimit else { throw ToolError.message("Archive metadata exceeded its limit.") }
            data.append(chunk)
        }
        guard crc == entry.checksum else { throw ToolError.message("Archive metadata checksum failed.") }
        return data
    }

    static func dictionary(_ data: Data) throws -> [String: Any] {
        guard let value = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
            throw ToolError.message("Expected a property-list dictionary.")
        }
        return value
    }

    static func profileDictionary(_ data: Data) throws -> [String: Any] {
        guard let start = data.range(of: Data("<?xml".utf8)),
              let end = data.range(of: Data("</plist>".utf8), options: [], in: start.lowerBound..<data.endIndex) else {
            throw ToolError.message("No XML provisioning profile found.")
        }
        return try dictionary(data.subdata(in: start.lowerBound..<end.upperBound))
    }

    static func hash(_ url: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        var hasher = SHA256()
        while let chunk = try handle.read(upToCount: 1024 * 1024), !chunk.isEmpty { hasher.update(data: chunk) }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }
}
