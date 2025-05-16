import SwiftUI
import UIComponents
import Domain
import Base

struct ChooseTrackPieceView: View {
    @Binding var isSelectedTrackPlaying: Bool
    @State private var viewModel: ChooseTrackPieceViewModel
    @State private var progress: CGFloat = 0
    @State private var timer: Timer?
    @State private var offset: CGFloat = 0
    
    private let selectorWidth: CGFloat = 130
    private let selectorDuration: CGFloat = 15
    private let timerStep: CGFloat = 1 / 60
    
    init(isSelectedTrackPlaying: Binding<Bool>, selectedTrack: Track) {
        self._isSelectedTrackPlaying = isSelectedTrackPlaying
        viewModel = ChooseTrackPieceViewModel(selectedTrack: selectedTrack)
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.backgroundSecondary)
                .frame(width: selectorWidth, height: 40)
                .mask(mask)
                .allowsHitTesting(false)
            
            ScrollViewWithDelegate(
                content: {
                    WaveformView(
                        trackDuration: viewModel.selectedTrack.duration,
                        selectorDuration: 15,
                        sidePaddingWidth: sidePaddingWidth
                    )
                },
                onBeginDragging: {
                    stopFill()
                    Task {
                        await viewModel.dispatch(.stopPlaying)
                    }
                },
                onEndDragging: { offset in
                    self.offset = offset
                    Task {
                        let startTime = computeStartTime(for: offset)
                        await viewModel.dispatch(.playTrack(startTime: startTime))
                    }
                }
            )
            .frame(height: 40)
            
            frame
        }
        .onChange(of: viewModel.startedPlaying) { _, startedPlaying in
            if startedPlaying {
                startFill()
            }
        }
        .onChange(of: isSelectedTrackPlaying) { _, isPlaying in
            if isPlaying {
                Task {
                    await viewModel.dispatch(.playTrack(startTime: offset))
                }
            } else {
                Task {
                    await viewModel.dispatch(.stopPlaying)
                }
            }
        }
//        .task {
//            await viewModel.dispatch(.playTrack())
//        }
        .onDisappear {
            Task {
                await viewModel.dispatch(.stopPlaying)
            }
            stopFill()
        }
    }
    
    private var sidePaddingWidth: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        return max((screenWidth - selectorWidth) / 2, 0)
    }
    
    private var frame: some View {
        RoundedRectangle(cornerRadius: 6)
            .stroke(Color.iconsBorder, lineWidth: 5)
            .frame(width: selectorWidth, height: 40)
            .allowsHitTesting(false)
    }
    
    private var mask: some View {
        GeometryReader { geo in
            Rectangle()
                .frame(width: geo.size.width * progress)
        }
    }
    
    private func startFill() {
        stopFill()
        
        timer = Timer.scheduledTimer(withTimeInterval: timerStep, repeats: true) { _ in
            progress += timerStep / selectorDuration
            if progress >= 1 {
                progress = 1
                startFill()
                Task {
                    let startTime = await computeStartTime(for: offset)
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
    
    private func computeStartTime(for offset: CGFloat) -> Double {
        let waveformWidth = selectorWidth * (viewModel.selectedTrack.duration / selectorDuration)
        let secondsPerPoint = viewModel.selectedTrack.duration / waveformWidth
        let clampedOffset = max(0, min(offset, waveformWidth - selectorWidth))
        return Double(clampedOffset * secondsPerPoint)
    }
}

struct ScrollViewWithDelegate<Content: View>: UIViewRepresentable {
    let content: Content
    let onBeginDragging: (() -> Void)?
    let onEndDragging: ((_ offset: CGFloat) -> Void)?
    
    init(@ViewBuilder content: () -> Content,
         onBeginDragging: (() -> Void)? = nil,
         onEndDragging: ((_ offset: CGFloat) -> Void)? = nil) {
        self.content = content()
        self.onBeginDragging = onBeginDragging
        self.onEndDragging = onEndDragging
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onBeginDragging: onBeginDragging, onEndDragging: onEndDragging)
    }
    
    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.decelerationRate = .fast
        
        let hostedView = UIHostingController(rootView: content)
        hostedView.view.translatesAutoresizingMaskIntoConstraints = false
        hostedView.view.backgroundColor = .clear
        
        scrollView.addSubview(hostedView.view)
        
        NSLayoutConstraint.activate([
            hostedView.view.topAnchor.constraint(equalTo: scrollView.topAnchor),
            hostedView.view.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            hostedView.view.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            hostedView.view.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            hostedView.view.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
        
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = true
        scrollView.isPagingEnabled = false
        scrollView.isDirectionalLockEnabled = true
        
        return scrollView
    }
    
    func updateUIView(_ uiView: UIScrollView, context: Context) {}
    
    class Coordinator: NSObject, UIScrollViewDelegate {
        let onBeginDragging: (() -> Void)?
        let onEndDragging: ((_ offset: CGFloat) -> Void)?
        
        init(
            onBeginDragging: (() -> Void)?,
            onEndDragging: ((_ offset: CGFloat) -> Void)?
        ) {
            self.onBeginDragging = onBeginDragging
            self.onEndDragging = onEndDragging
        }
        
        func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
            onBeginDragging?()
        }
        
        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            onEndDragging?(scrollView.contentOffset.x)
        }
        
        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            if !decelerate {
                onEndDragging?(scrollView.contentOffset.x)
            }
        }
    }
}
