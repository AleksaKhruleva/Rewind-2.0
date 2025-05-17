import SwiftUI
import UIComponents
import Domain
import Base

struct ChooseTrackPieceView: View {
    @Binding var shouldPlay: Bool
    
    @State private var viewModel: ChooseTrackPieceViewModel
    @State private var progress: CGFloat = 0
    @State private var timer: Timer?
    @State private var offset: CGFloat = 0
    
    private let selectorWidth: CGFloat = 130
    private let selectorDuration: CGFloat = 15
    private let timerStep: CGFloat = 1 / 60
    
    init(shouldPlay: Binding<Bool>, selectedTrack: Track) {
        self._shouldPlay = shouldPlay
        viewModel = ChooseTrackPieceViewModel(selectedTrack: selectedTrack)
    }
    
    var body: some View {
        ZStack {
            // Progress Frame
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.backgroundSecondary)
                .frame(width: selectorWidth, height: 40)
                .mask(
                    GeometryReader { geo in
                        Rectangle()
                            .frame(width: geo.size.width * progress)
                    }
                )
                .allowsHitTesting(false)
            
            // Scroll View
            CustomScrollView(
                content: {
                    WaveformView(
                        trackDuration: viewModel.selectedTrack.duration,
                        selectorDuration: 15,
                        sidePaddingWidth: sidePaddingWidth
                    )
                },
                onBeginDragging: {
                    viewModel.dispatch(.stopPlaying)
                },
                onEndDragging: { newOffset in
                    offset = newOffset
                    viewModel.dispatch(.playTrack(startTime: startTime))
                }
            )
            .frame(height: 40)
            
            // Frame
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.iconsBorder, lineWidth: 5)
                .frame(width: selectorWidth, height: 40)
                .allowsHitTesting(false)
        }
        .onChange(of: shouldPlay) { _, newValue in
            if shouldPlay {
                viewModel.dispatch(.playTrack(startTime: startTime))
            } else {
                viewModel.dispatch(.stopPlaying)
            }
        }
        .onChange(of: viewModel.isTrackPlaying) { _, isTrackPlaying in
            if isTrackPlaying {
                startFill()
            } else {
                stopFill()
            }
        }
        .onDisappear {
            viewModel.dispatch(.destroyPlayer)
        }
    }
    
    private var sidePaddingWidth: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        return max((screenWidth - selectorWidth) / 2, 0)
    }
    
    private var startTime: Double {
        let waveformWidth = selectorWidth * (viewModel.selectedTrack.duration / selectorDuration)
        let secondsPerPoint = viewModel.selectedTrack.duration / waveformWidth
        let clampedOffset = max(0, min(offset, waveformWidth - selectorWidth))
        return Double(clampedOffset * secondsPerPoint)
    }
    
    private func startFill() {
        timer = Timer.scheduledTimer(withTimeInterval: timerStep, repeats: true) { _ in
            progress += timerStep / selectorDuration
            if progress >= 1 {
                progress = 1
                stopFill()
                Task {
                    await viewModel.dispatch(.playTrack(startTime: startTime))
                }
            }
        }
    }
    
    private func stopFill() {
        progress = 0
        timer?.invalidate()
        timer = nil
    }
}
