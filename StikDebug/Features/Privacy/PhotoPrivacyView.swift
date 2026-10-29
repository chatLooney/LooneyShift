import SwiftUI
import PhotosUI

struct PhotoPrivacyView: View {
    @State private var selection: PhotosPickerItem?
    @State private var summary: PhotoPrivacySummary?
    @State private var output: URL?
    @State private var error: String?
    @State private var busy = false
    @State private var job = UUID()
    private let exportDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("LooneyShift-Photos")

    var body: some View {
        List {
            Section {
                Label("Share the photo. Keep its metadata private.", systemImage: "photo.badge.checkmark")
                    .font(.headline)
                Text("Creates a new JPEG with GPS, camera details, and capture dates removed. Your original stays unchanged. Photo content itself may still reveal personal information.")
                    .font(.subheadline).foregroundStyle(.secondary)
                PhotosPicker(selection: $selection, matching: .images, preferredItemEncoding: .current) {
                    Label("Choose a photo", systemImage: "photo.on.rectangle")
                }.disabled(busy)
            }
            if busy { ProgressView("Cleaning and verifying…") }
            if let summary {
                Section("Metadata found in imported photo") {
                    LabeledContent("Resolution", value: "\(summary.width) × \(summary.height)")
                    LabeledContent("GPS metadata", value: summary.hasGPS ? "Present" : "Not present")
                    LabeledContent("Camera", value: summary.camera ?? "Not present")
                    LabeledContent("Captured", value: summary.capturedAt ?? "Not present")
                }
            }
            if let output {
                Section("Clean copy ready") {
                    Label("GPS, camera and capture date removal verified", systemImage: "checkmark.shield.fill")
                        .foregroundStyle(.green)
                    ShareLink(item: output) { Label("Share cleaned JPEG", systemImage: "square.and.arrow.up") }
                    Text("Exports a still JPEG. Transparency, animation, Live Photo motion and HDR are not preserved. Temporary copies are removed when you leave this screen.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            if let error { Text(error).foregroundStyle(.red) }
        }
        .navigationTitle("Photo Privacy")
        .onChange(of: selection) { _, item in
            guard let item else { return }
            let currentJob = UUID(); job = currentJob
            summary = nil; output = nil; error = nil; busy = true
            Task {
                do {
                    guard let data = try await item.loadTransferable(type: Data.self) else {
                        throw ToolError.message("Could not load this photo.")
                    }
                    guard data.count <= 100_000_000 else { throw ToolError.message("Choose a photo smaller than 100 MB.") }
                    let directory = exportDirectory
                    let result = try await Task.detached(priority: .userInitiated) {
                        (try PhotoPrivacyService.inspect(data), try PhotoPrivacyService.clean(data, directory: directory))
                    }.value
                    guard job == currentJob else {
                        try? FileManager.default.removeItem(at: result.1)
                        return
                    }
                    summary = result.0; output = result.1
                } catch {
                    if job == currentJob { self.error = error.localizedDescription }
                }
                if job == currentJob { busy = false }
            }
        }
        .onDisappear {
            job = UUID()
            try? FileManager.default.removeItem(at: exportDirectory)
        }
    }
}
