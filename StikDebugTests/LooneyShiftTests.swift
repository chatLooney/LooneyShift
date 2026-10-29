import Foundation
import Testing
import UIKit
import ImageIO
import UniformTypeIdentifiers
@testable import StikDebug

struct LooneyShiftTests {
    @Test func photoExportRemovesSensitiveMetadata() throws {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 20, height: 10)).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 20, height: 10))
        }
        let bytes = NSMutableData()
        let destination = try #require(CGImageDestinationCreateWithData(bytes, UTType.jpeg.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(destination, try #require(image.cgImage), [
            kCGImagePropertyGPSDictionary: [kCGImagePropertyGPSLatitude: 31.95, kCGImagePropertyGPSLatitudeRef: "S"],
            kCGImagePropertyTIFFDictionary: [kCGImagePropertyTIFFModel: "Private Camera"],
            kCGImagePropertyExifDictionary: [kCGImagePropertyExifDateTimeOriginal: "2026:01:01 12:00:00"]
        ] as CFDictionary)
        #expect(CGImageDestinationFinalize(destination))
        let source = bytes as Data
        #expect(try PhotoPrivacyService.inspect(source).hasGPS)
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let cleaned = try Data(contentsOf: PhotoPrivacyService.clean(source, directory: directory))
        let result = try PhotoPrivacyService.inspect(cleaned)
        #expect(!result.hasGPS)
        #expect(result.camera == nil)
        #expect(result.capturedAt == nil)
        #expect(result.width == 20 && result.height == 10)
        #expect(try PhotoPrivacyService.inspect(source).hasGPS)
    }

    @Test func ipaInspectionReadsMetadataWithoutExecuting() throws {
        let url = try fixture("UEsDBBQAAAAIAAAjXV0rtjgfHwEAACECAAAeAAAAUGF5bG9hZC9GaXh0dXJlLmFwcC9JbmZvLnBsaXN0fZHLTsMwEEXX9CuM97EpIIFQmoomjRQptClJkVha8bS1SGzLdh/5e9zHAiLK0jP3XN+ZCceHtkE7MFYoOcJDcocRyFpxIdcjvKzS4BmPo0F4m8zj6rOYIt0I61CxnORZjHBA6avWDVCaVAkq8qyskPegdDrDCG+c0y+U7vd7wo4qUqv2KLS0MEqDcV3uzQIPEO449t+c3X/F8VUuahcNbsIv6KI4nWwlbyARVjesm7EWQnps+L51xseOUnFwW+PLl3ePzDhIJ1YCTB/ksCONUhI6svrfo9wo4z7OMcuTou81JPfX4AvXJx76+jchRbtt5+UVYPhEHvvMrIz9RgxbWraGBGxthHZ/sGXNJGJo8Y78rX+MGdLzskN6OkU0+AZQSwMEFAAAAAgAACNdXS4rqisQAAAADgAAADgAAABQYXlsb2FkL0ZpeHR1cmUuYXBwL0ZyYW1ld29ya3MvRXhhbXBsZS5mcmFtZXdvcmsvRXhhbXBsZcvLL1FIrUhNLi1JTMpJBQBQSwMEFAAAAAgAACNdXbacrm4OAAAADAAAADAAAABQYXlsb2FkL0ZpeHR1cmUuYXBwL19Db2RlU2lnbmF0dXJlL0NvZGVSZXNvdXJjZXPLyy9RKEstykzLTE0BAFBLAQIUAxQAAAAIAAAjXV0rtjgfHwEAACECAAAeAAAAAAAAAAAAAACAAQAAAABQYXlsb2FkL0ZpeHR1cmUuYXBwL0luZm8ucGxpc3RQSwECFAMUAAAACAAAI11dLiuqKxAAAAAOAAAAOAAAAAAAAAAAAAAAgAFbAQAAUGF5bG9hZC9GaXh0dXJlLmFwcC9GcmFtZXdvcmtzL0V4YW1wbGUuZnJhbWV3b3JrL0V4YW1wbGVQSwECFAMUAAAACAAAI11dtpyubg4AAAAMAAAAMAAAAAAAAAAAAAAAgAHBAQAAUGF5bG9hZC9GaXh0dXJlLmFwcC9fQ29kZVNpZ25hdHVyZS9Db2RlUmVzb3VyY2VzUEsFBgAAAAADAAMAEAEAAB0CAAAAAA==")
        defer { try? FileManager.default.removeItem(at: url) }
        let report = try IPAInspectorService.inspect(url)
        #expect(report.bundleID == "dev.looney.fixture")
        #expect(report.version == "1.2 (3)")
        #expect(report.frameworks == ["Example.framework"])
        #expect(report.hasSignatureFiles)
        #expect(report.sha256.count == 64)
        #expect(report.usageDescriptions.count == 1)
    }

    @Test func ipaInspectionRejectsTraversal() throws {
        let url = try fixture("UEsDBBQAAAAIAAAjXV37OSuCBQAAAAMAAAAKAAAALi4vb3V0c2lkZUtKTAEAUEsDBBQAAAAIAAAjXV0rtjgfHwEAACECAAAeAAAAUGF5bG9hZC9GaXh0dXJlLmFwcC9JbmZvLnBsaXN0fZHLTsMwEEXX9CuM97EpIIFQmoomjRQptClJkVha8bS1SGzLdh/5e9zHAiLK0jP3XN+ZCceHtkE7MFYoOcJDcocRyFpxIdcjvKzS4BmPo0F4m8zj6rOYIt0I61CxnORZjHBA6avWDVCaVAkq8qyskPegdDrDCG+c0y+U7vd7wo4qUqv2KLS0MEqDcV3uzQIPEO449t+c3X/F8VUuahcNbsIv6KI4nWwlbyARVjesm7EWQnps+L51xseOUnFwW+PLl3ePzDhIJ1YCTB/ksCONUhI6svrfo9wo4z7OMcuTou81JPfX4AvXJx76+jchRbtt5+UVYPhEHvvMrIz9RgxbWraGBGxthHZ/sGXNJGJo8Y78rX+MGdLzskN6OkU0+AZQSwECFAMUAAAACAAAI11d+zkrggUAAAADAAAACgAAAAAAAAAAAAAAgAEAAAAALi4vb3V0c2lkZVBLAQIUAxQAAAAIAAAjXV0rtjgfHwEAACECAAAeAAAAAAAAAAAAAACAAS0AAABQYXlsb2FkL0ZpeHR1cmUuYXBwL0luZm8ucGxpc3RQSwUGAAAAAAIAAgCEAAAAiAEAAAAA")
        defer { try? FileManager.default.removeItem(at: url) }
        #expect(throws: (any Error).self) { try IPAInspectorService.inspect(url) }
    }

    @Test func malformedProfileIsRejected() {
        #expect(throws: (any Error).self) { try IPAInspectorService.profileDictionary(Data("not a profile".utf8)) }
    }

    private func fixture(_ encoded: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).ipa")
        try #require(Data(base64Encoded: encoded)).write(to: url)
        return url
    }
}
