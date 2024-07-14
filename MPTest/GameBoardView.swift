import SwiftUI

struct GameBoardView: View {
    @ObservedObject var multipeerSession: MultipeerSession
    @Binding var hostStart: Bool
    @Binding var inGame: Bool
    @Binding var playerName: String
    @Binding var opponentName: String
    @State private var scorePlayer1 = 0
    @State private var scorePlayer2 = 0

    var body: some View {
        VStack {
            Text("\(playerName): \(scorePlayer1)")
            Text("\(opponentName): \(scorePlayer2)")
            
            if multipeerSession.isHost {
                Button("\(playerName) Scores") {
                    scorePlayer1 += 1
                    sendScoreUpdate()
                    checkForWinner()
                }
            } else {
                Button("\(opponentName) Scores") {
                    scorePlayer2 += 1
                    sendScoreUpdate()
                    checkForWinner()
                }
            }
        }
        .onReceive(multipeerSession.$receivedData) { data in
            guard let data = data else { return }
            scorePlayer1 = data.score1
            scorePlayer2 = data.score2
            
            if data.didWin1 || data.didWin2 {
                inGame = false
                checkForWinner()
            }
        }
    }

    private func sendScoreUpdate() {
       let gameData = GameData(player1Name: playerName, score1: scorePlayer1, didWin1: false, player2Name: opponentName, score2: scorePlayer2, didWin2: false, isClientReady: true, isHostReady: true)
        multipeerSession.send(gameData: gameData)
    }

    private func checkForWinner() {
        if scorePlayer1 == 21 {
            let gameData = GameData(player1Name: playerName, score1: scorePlayer1, didWin1: true, player2Name: opponentName, score2: scorePlayer2, didWin2: false, isClientReady: false, isHostReady: false)
            multipeerSession.send(gameData: gameData)
            inGame = false
        } else if scorePlayer2 == 21 {
            let gameData = GameData(player1Name: playerName, score1: scorePlayer1, didWin1: false, player2Name: opponentName, score2: scorePlayer2, didWin2: true, isClientReady: false, isHostReady: false)
            multipeerSession.send(gameData: gameData)
            inGame = false
        }
    }
}
