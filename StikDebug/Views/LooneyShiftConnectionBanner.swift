import SwiftUI

struct LooneyShiftConnectionBanner: View {
    @ObservedObject private var tunnel = TunnelManager.shared
    @ObservedObject private var mounting = MountingProgress.shared
    @ObservedObject private var simulation = LocationSimulationSession.shared

    private var status: String {
        if simulation.isActive { return "Location shifted" }
        if !FileManager.default.fileExists(atPath: PairingFileStore.prepareURL().path) { return "Import a pairing file in Settings" }
        if !tunnel.isConnected { return "Enable LocalDevVPN, then connect" }
        if !mounting.coolisMounted { return "Preparing developer connection…" }
        return "Ready to shift • tap the map"
    }

    var body: some View {
        HStack(spacing: 10) {
            Image("LooneyShift").resizable().frame(width: 32, height: 32).clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 2) {
                Text("LooneyShift").font(.headline)
                Text(status).font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            if !tunnel.isConnected {
                Button("Connect") { startTunnelInBackground() }
                    .font(.caption.weight(.semibold))
                    .disabled(!FileManager.default.fileExists(atPath: PairingFileStore.prepareURL().path))
            }
            Button {
                NotificationCenter.default.post(name: NSNotification.Name("LooneyShiftOpenSettings"), object: nil)
            } label: { Image(systemName: "gearshape") }
            .accessibilityLabel("Connection settings")
        }
        .padding(12)
        .background(.regularMaterial)
    }
}
