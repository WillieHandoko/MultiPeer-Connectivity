import Foundation
import MultipeerConnectivity

struct GameData: Codable {
    var player1Name: String
    var score1: Int
    var didWin1: Bool
    var player2Name: String
    var score2: Int
    var didWin2: Bool
    var isClientReady: Bool
    var isHostReady: Bool
}


class MultipeerSession: NSObject, ObservableObject {
    private let serviceType = "badminton-game"
    private let myPeerId = MCPeerID(displayName: UIDevice.current.name)
    private var serviceAdvertiser: MCNearbyServiceAdvertiser!
    private var serviceBrowser: MCNearbyServiceBrowser!
    private var session: MCSession!

    @Published var availablePeers: [MCPeerID] = []
    @Published var connectedPeers: [MCPeerID] = []
    @Published var receivedData: GameData?
    @Published var isHost = false
    @Published var isClient = false
    @Published var showInvitationAlert = false
    @Published var invitationPeerID: MCPeerID?

    override init() {
        super.init()
        setupSession()
    }

    func setupSession() {
        session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .required)
        serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType)
        serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)

        session.delegate = self
        serviceAdvertiser.delegate = self
        serviceBrowser.delegate = self

        serviceAdvertiser.startAdvertisingPeer()
        serviceBrowser.startBrowsingForPeers()
    }

    func send(gameData: GameData) {
        do {
            let data = try JSONEncoder().encode(gameData)
            try session.send(data, toPeers: connectedPeers, with: .reliable)
        } catch {
            print("Error sending data: \(error.localizedDescription)")
        }
    }

    func disconnect() {
        session.disconnect()
        serviceAdvertiser.stopAdvertisingPeer()
        serviceBrowser.stopBrowsingForPeers()
        connectedPeers.removeAll()
        availablePeers.removeAll()
    }

    func reconnect() {
        setupSession()
    }
}

extension MultipeerSession: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationPeerID = peerID
        showInvitationAlert = true
        invitationHandler(true, session)
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("Failed to advertise: \(error.localizedDescription)")
    }
}

extension MultipeerSession: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        availablePeers.append(peerID)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        if let index = availablePeers.firstIndex(of: peerID) {
            availablePeers.remove(at: index)
        }
    }

    func invite(peerID: MCPeerID) {
        isHost = true
        isClient = false
        serviceBrowser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }
}

extension MultipeerSession: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                self.connectedPeers.append(peerID)
                self.availablePeers.removeAll(where: { $0 == peerID })
            case .notConnected:
                if let index = self.connectedPeers.firstIndex(of: peerID) {
                    self.connectedPeers.remove(at: index)
                }
            default:
                break
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            do {
                let gameData = try JSONDecoder().decode(GameData.self, from: data)
                self.receivedData = gameData
            } catch {
                print("Error decoding data: \(error.localizedDescription)")
            }
        }
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}

    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}

    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}
