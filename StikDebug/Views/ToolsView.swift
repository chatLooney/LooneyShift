// LooneyShift modifications. Original project: StikDebug, AGPL-3.0.
import SwiftUI

struct ToolsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Privacy & Inspection") {
                    NavigationLink { PhotoPrivacyView() } label: {
                        tool("Photo Privacy", "Remove GPS and camera metadata from a shareable copy", "photo.badge.checkmark")
                    }
                    NavigationLink { IPAInspectorView() } label: {
                        tool("IPA Inspector", "Inspect app details, privacy prompts and provisioning", "shippingbox")
                    }
                }
                Section("Device Utilities") {
                    ForEach(AppFeature.toolList) { feature in
                        NavigationLink { feature.destination } label: {
                            tool(feature.toolTitle, feature.detail, feature.systemImage)
                        }
                    }
                }
                Section {
                    Link("Made by Looney • looney.is-a.dev", destination: URL(string: "https://looney.is-a.dev/")!)
                }
            }
            .navigationTitle("Tools")
        }
    }

    private func tool(_ title: String, _ subtitle: String, _ icon: String) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }.padding(.vertical, 5)
        } icon: { Image(systemName: icon).foregroundStyle(.cyan) }
    }
}
