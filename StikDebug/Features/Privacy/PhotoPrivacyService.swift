import Foundation
import ImageIO
import UIKit
import UniformTypeIdentifiers

struct PhotoPrivacySummary: Sendable {
    let width: Int
    let height: Int
    let hasGPS: Bool
    let camera: String?
    let capturedAt: String?
}

enum PhotoPrivacyService {
    static func inspect(_ data: Data) throws -> PhotoPrivacySummary {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            throw ToolError.message("This photo could not be read. Choose a JPEG, HEIC, or PNG image.")
        }
        let tiff = properties[kCGImagePropertyTIFFDictionary as String] as? [String: Any]
        let exif = properties[kCGImagePropertyExifDictionary as String] as? [String: Any]
        return PhotoPrivacySummary(
            width: properties[kCGImagePropertyPixelWidth as String] as? Int ?? 0,
            height: properties[kCGImagePropertyPixelHeight as String] as? Int ?? 0,
            hasGPS: properties[kCGImagePropertyGPSDictionary as String] != nil,
            camera: tiff?[kCGImagePropertyTIFFModel as String] as? String,
            capturedAt: exif?[kCGImagePropertyExifDateTimeOriginal as String] as? String
        )
    }

    // Decode pixels, apply orientation, and create a new image without source metadata.
    // Exports a still JPEG: animation, Live Photo motion, HDR, and alpha are not preserved.
    static func clean(_ data: Data, directory: URL) throws -> URL {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any],
              let width = properties[kCGImagePropertyPixelWidth as String] as? Int,
              let height = properties[kCGImagePropertyPixelHeight as String] as? Int,
              width > 0, height > 0, Int64(width) * Int64(height) <= 60_000_000 else {
            throw ToolError.message("Choose a still image up to 60 megapixels.")
        }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: max(width, height)
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            throw ToolError.message("Could not decode this image.")
        }
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, UTType.jpeg.identifier as CFString, 1, nil) else {
            throw ToolError.message("Could not create a cleaned photo.")
        }
        CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: 0.95] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw ToolError.message("Photo export failed.") }
        // Verify the exported bytes, rather than assuming the encoder removed sensitive fields.
        let result = try inspect(output as Data)
        guard !result.hasGPS, result.camera == nil, result.capturedAt == nil else {
            throw ToolError.message("Privacy verification failed. No photo was exported.")
        }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("LooneyShift-clean-\(UUID().uuidString).jpg")
        try (output as Data).write(to: url, options: .atomic)
        return url
    }
}

enum ToolError: LocalizedError {
    case message(String)
    var errorDescription: String? { if case .message(let message) = self { return message }; return nil }
}
