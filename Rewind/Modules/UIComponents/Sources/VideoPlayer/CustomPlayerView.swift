import SwiftUI
import AVFoundation

public struct CustomPlayerView: UIViewRepresentable {
    @Binding var isPlaying: Bool
    @Binding var isMuted: Bool
    
    private let player: AVPlayer
    private let startTime: CMTime
    private let shouldSeekToStartTime: Bool
    private let onSeekComplete: () -> Void
    
    public init(
        isPlaying: Binding<Bool>,
        isMuted: Binding<Bool>,
        player: AVPlayer,
        startTime: CMTime,
        shouldSeekToStartTime: Bool,
        onSeekComplete: @escaping () -> Void
    ) {
        self._isPlaying = isPlaying
        self._isMuted = isMuted
        self.player = player
        self.startTime = startTime
        self.shouldSeekToStartTime = shouldSeekToStartTime
        self.onSeekComplete = onSeekComplete
    }
    
    public func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView(player: player)
        view.setMuted(isMuted)
        view.onToggle = {
            isPlaying.toggle()
        }
        view.onMuteToggle = {
            isMuted.toggle()
        }
        return view
    }
    
    public func updateUIView(_ uiView: PlayerUIView, context: Context) {
        uiView.player = player
        
        if isPlaying {
            if shouldSeekToStartTime {
                player.seek(to: startTime) { _ in
                    DispatchQueue.main.async {
                        onSeekComplete()
                    }
                    player.play()
                }
            } else {
                uiView.setPlaying(true)
            }
        } else {
            uiView.setPlaying(false)
        }
    }
}
