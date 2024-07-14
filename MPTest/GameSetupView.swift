import SwiftUI

struct GameSetupView: View {
    @ObservedObject var multipeerSession: MultipeerSession
    @State private var showPeersView = false
    @State private var hostStart = false
    @State private var inGame = false
    @State private var playerName = ""
    @State private var opponentName = ""
    @State private var isClientReady = false
    
    var body: some View {
        VStack {
            if multipeerSession.isHost{
                TextField("Enter your Host name", text: $playerName)
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Text("\(playerName)")
                Text("\(opponentName)")
            } else if multipeerSession.isClient{
                TextField("Enter your Client name", text: $opponentName)
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Text("\(playerName)")
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            
            
            
            Button("Connect to Player") {
                showPeersView = true
            }
            .sheet(isPresented: $showPeersView) {
                PeersView(multipeerSession: multipeerSession)
            }
            
            if multipeerSession.connectedPeers.isEmpty {
                Text("No players connected")
            } else {
                Text("Connected to: \(multipeerSession.connectedPeers[0].displayName)")
                if multipeerSession.isHost && isClientReady {
                    Button("Start Game") {
                        let gameData = GameData(player1Name: playerName, score1: 0, didWin1: false, player2Name: opponentName, score2: 0, didWin2: false, isClientReady: true, isHostReady: true)
                        multipeerSession.send(gameData: gameData)
                       
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            // Hide the loading view and show the summary
                            inGame = true
                        }
                    }
                } 
                else if multipeerSession.isClient {
                    if !isClientReady{
                        Button("Ready") {
                            let gameData = GameData(player1Name: playerName, score1: 0, didWin1: false, player2Name: opponentName, score2: 0, didWin2: false, isClientReady: true, isHostReady: false)
                            multipeerSession.send(gameData: gameData)
                            isClientReady = gameData.isClientReady
                        }
                }
                    else if isClientReady {
                        Button("Not Ready") {
                            let gameData = GameData(player1Name: playerName, score1: 0, didWin1: false, player2Name: "", score2: 0, didWin2: false, isClientReady: false, isHostReady: false)
                            multipeerSession.send(gameData: gameData)
                            isClientReady = gameData.isClientReady
                        }
                    }
                }
            }
            Button("Reconnect") {
                multipeerSession.reconnect()
            }
        }
        .fullScreenCover(isPresented: $inGame) {
            GameBoardView(multipeerSession: multipeerSession, hostStart: $hostStart ,inGame: $inGame, playerName: $playerName, opponentName: $opponentName)
        }

        .onReceive(multipeerSession.$receivedData) { data in
            guard let data = data else { return }
            if multipeerSession.isHost {
                if playerName.isEmpty {
                    playerName = data.player1Name
                }
                else {
                    print("skip")
                }
            } else if multipeerSession.isClient {
                playerName = data.player1Name
            }
            opponentName = data.player2Name
            isClientReady = data.isClientReady
            
            if (data.score1 == 0 && data.score2 == 0)  && (data.didWin1 == false && data.didWin2 == false) && data.isHostReady == true {
                    inGame = true
            }
        }
    }
}
