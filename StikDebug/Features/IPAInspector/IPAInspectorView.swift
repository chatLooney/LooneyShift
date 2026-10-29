import SwiftUI
import UniformTypeIdentifiers

struct IPAInspectorView: View {
    @State private var showImporter = false
    @State private var report: IPAReport?
    @State private var busy = false
    @State private var error: String?

    var body: some View {
        List {
            Section {
                Label("Look inside an IPA", systemImage: "shippingbox")
                    .font(.headline)
                Text("Inspect an IPA from Files. Analysis stays on this device; the app is never installed or executed.")
                    .foregroundStyle(.secondary)
                Button { showImporter = true } label: { Label("Choose IPA", systemImage: "doc.badge.magnifyingglass") }
                    .disabled(busy)
            }
            if busy { ProgressView("Inspecting archive and calculating SHA-256…") }
            if let error { Text(error).foregroundStyle(.red) }
            if let report {
                Section("App") {
                    LabeledContent("Name", value: report.name)
                    LabeledContent("Bundle ID", value: report.bundleID)
                    LabeledContent("Version", value: report.version)
                    LabeledContent("Minimum iOS", value: report.minimumOS)
                    LabeledContent("IPA size", value: ByteCountFormatter.string(fromByteCount: report.size, countStyle: .file))
                }
                Section("Declared privacy prompts") {
                    if report.usageDescriptions.isEmpty { Text("No usage-description strings found.") }
                    ForEach(report.usageDescriptions, id: \.self) { Text($0).font(.caption) }
                    Text("These are app declarations, not a record of granted permissions or observed behaviour.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Section("Embedded frameworks") {
                    if report.frameworks.isEmpty { Text("No bundled frameworks found.") }
                    ForEach(report.frameworks, id: \.self) { Text($0) }
                }
                Section("Provisioning profile") {
                    ForEach(report.profileSummary, id: \.self) { Text($0) }
                    LabeledContent("Signature resource file", value: report.hasSignatureFiles ? "Present" : "Not found")
                    Text("Profile claims and signature-file presence only. This does not validate the signature, certificate revocation, installability, or app safety.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Section("Provisioned entitlements") {
                    Text(report.provisionedEntitlements).font(.system(.caption, design: .monospaced)).textSelection(.enabled)
                    Text("Allowed values from the provisioning profile. These may differ from the executable’s signed entitlements.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Section("SHA-256") {
                    Text(report.sha256).font(.system(.caption, design: .monospaced)).textSelection(.enabled)
                    ShareLink(item: "\(report.name)\n\(report.bundleID)\n\(report.version)\nSHA-256: \(report.sha256)") {
                        Label("Share summary", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
        .navigationTitle("IPA Inspector")
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.item], allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                busy = true; report = nil; error = nil
                Task {
                    do { report = try await Task.detached(priority: .userInitiated) { try IPAInspectorService.inspect(url) }.value }
                    catch { self.error = error.localizedDescription }
                    busy = false
                }
            case .failure(let failure): error = failure.localizedDescription
            }
        }
    }
}
