import SwiftUI

struct PeersView: View {
    @ObservedObject var multipeerSession: MultipeerSession

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Available Peers")) {
                    ForEach(multipeerSession.availablePeers, id: \.self) { peer in
                        HStack {
                            Text(peer.displayName)
                            Spacer()
                            Button("Invite") {
                                multipeerSession.invite(peerID: peer)
                            }
                        }
                    }
                }
                Section(header: Text("Connected Peers")) {
                    ForEach(multipeerSession.connectedPeers, id: \.self) { peer in
                        HStack {
                            Text(peer.displayName)
                            Spacer()
                            Button("Disconnect") {
                                multipeerSession.disconnect()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Peers")
            .alert(isPresented: $multipeerSession.showInvitationAlert) {
                Alert(
                    title: Text("Invitation Received"),
                    message: Text("Accept invitation from \(multipeerSession.invitationPeerID?.displayName ?? "unknown")?"),
                    primaryButton: .default(Text("Accept")) {
                        multipeerSession.showInvitationAlert = false
                        multipeerSession.isHost = false
                        multipeerSession.isClient = true
                    },
                    secondaryButton: .cancel(Text("Reject")) {
                        multipeerSession.showInvitationAlert = false
                        multipeerSession.invitationPeerID = nil
                    }
                )
            }
        }
    }
}
