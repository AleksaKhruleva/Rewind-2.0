import SwiftUI
import UIComponents
import Domain
import Base

private let buttonSize: CGFloat = 38
private let selectorWidth: CGFloat = 130
private let timerStep: CGFloat = 1 / 60

struct ChooseTrackPieceView: View {
    @Binding var shouldPlay: Bool
    
    @State private var viewModel: ChooseTrackPieceViewModel
    @State private var progress: CGFloat = 0
    @State private var timer: Timer?
    @State private var offset: CGFloat = 0
    @State private var realTimeOffset: CGFloat = 0
    @State private var selectorDuration: CGFloat = 15
    @State private var durationInPicker: CGFloat = 15
    @State private var showDurationPicker = false
    
    private let isDurationPickerAvailable: Bool
    
    init(shouldPlay: Binding<Bool>, isDurationPickerAvailable: Bool, selectedTrack: Track) {
        self._shouldPlay = shouldPlay
        self.isDurationPickerAvailable = isDurationPickerAvailable
        viewModel = ChooseTrackPieceViewModel(selectedTrack: selectedTrack)
    }
    
    var body: some View {
        VStack {
            HStack(spacing: 12) {
                Button {
                    showDurationPicker = true
                    viewModel.dispatch(.stopPlaying)
                } label: {
                    Text("\(Int(selectorDuration))")
                        .modifier(RoundFontModifier(size: 14))
                        .frame(width: buttonSize, height: buttonSize)
                        .background(Circle().fill(Color.backgroundSecondary))
                }
                .disabledWithOpacity(!isDurationPickerAvailable)
                
                Capsule()
                    .fill(Color.backgroundSecondary)
                    .frame(height: 8)
                    .overlay(
                        GeometryReader { capsuleGeo in
                            Capsule()
                                .fill(Color.pinkPrimaryLight)
                                .frame(width: frameCapsuleWidth(capsuleWidth: capsuleGeo.size.width))
                                .offset(x: frameCapsuleOffset(capsuleWidth: capsuleGeo.size.width))
                                .animation(.linear(duration: 0.1), value: realTimeOffset)
                        }
                    )
                
                Button {
                    if viewModel.isTrackPlaying {
                        viewModel.dispatch(.stopPlaying)
                    } else {
                        viewModel.dispatch(.playTrack(startTime: startTime))
                    }
                } label: {
                    Image(systemName: viewModel.isTrackPlaying ? "stop.fill" : "play.fill")
                        .modifier(RoundFontModifier(size: 13))
                        .frame(width: buttonSize, height: buttonSize)
                        .background(Circle().fill(Color.backgroundSecondary))
                }
            }
            .padding(.horizontal, 8)
            
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
                            selectorDuration: $selectorDuration,
                            trackDuration: viewModel.selectedTrack.duration,
                            sidePaddingWidth: sidePaddingWidth
                        )
                    },
                    onBeginDragging: {
                        viewModel.dispatch(.stopPlaying)
                    },
                    onEndDragging: { newOffset in
                        offset = newOffset
                        viewModel.dispatch(.playTrack(startTime: startTime))
                    },
                    onScroll: { currentOffset in
                        realTimeOffset = currentOffset
                    }
                )
                .frame(height: 40)
                
                // Frame
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.textTertiary, lineWidth: 5)
                    .frame(width: selectorWidth, height: 40)
                    .allowsHitTesting(false)
            }
        }
        .sheet(isPresented: $showDurationPicker, onDismiss: {
            durationInPicker = selectorDuration
        }) {
            VStack {
                Text("Choose song duration")
                    .modifier(RoundFontModifier(size: 15))
                    .padding(.top)
                
                Picker("Duration", selection: $durationInPicker) {
                    ForEach(5...15, id: \.self) { val in
                        Text("\(val) сек").tag(CGFloat(val))
                    }
                }
                .labelsHidden()
                .pickerStyle(.wheel)
                .frame(height: 160)
                
                Button("Done") {
                    selectorDuration = durationInPicker
                    showDurationPicker = false
                    viewModel.dispatch(.playTrack(startTime: startTime))
                }
                .modifier(
                    RoundFontModifier(size: 15, foregroundColor: .pinkPrimary)
                )
                .padding()
            }
            .onAppear {
                durationInPicker = selectorDuration
            }
            .presentationDetents([.height(280)])
            .presentationDragIndicator(.visible)
            .background(Color.background)
        }
        .onChange(of: selectorDuration) { oldValue, newValue in
            let oldWaveformWidth = selectorWidth * (viewModel.selectedTrack.duration / oldValue)
            let newWaveformWidth = selectorWidth * (viewModel.selectedTrack.duration / newValue)
            
            let relativeOffset = offset / oldWaveformWidth
            offset = newWaveformWidth * relativeOffset
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
        let result = Double(clampedOffset * secondsPerPoint)
        
        let maxStartTime = max(0, viewModel.selectedTrack.duration - Double(selectorDuration))
        return min(result, maxStartTime)
    }
    
    private func frameCapsuleWidth(capsuleWidth: CGFloat) -> CGFloat {
        let trackDuration = viewModel.selectedTrack.duration
        let durationRatio = selectorDuration / trackDuration
        
        return capsuleWidth * durationRatio
    }
    
    private func frameCapsuleOffset(capsuleWidth: CGFloat) -> CGFloat {
        let trackDuration = viewModel.selectedTrack.duration
        let ratio = realTimeOffset / (selectorWidth * (trackDuration / selectorDuration))
        return min(capsuleWidth - frameCapsuleWidth(capsuleWidth: capsuleWidth), max(0, ratio * capsuleWidth))
    }
    
    private func startFill() {
        timer?.invalidate()
        progress = 0
        
        let startDate = Date()
        let duration = selectorDuration
        
        timer = Timer.scheduledTimer(withTimeInterval: timerStep, repeats: true) { timer in
            let elapsed = Date().timeIntervalSince(startDate)
            progress = min(CGFloat(elapsed) / duration, 1)
            
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
