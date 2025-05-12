import SwiftUI
import UIComponents
import Domain

struct ChooseTrackPieceView: View {
    private let selectorWidth: CGFloat = 130
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.backgroundSecondary)
                .frame(width: selectorWidth, height: 40)
                .allowsHitTesting(false)
            
            ScrollViewWithDelegate(
                content: {
                    WaveformView(sidePaddingWidth: sidePaddingWidth)
                },
                onBeginDragging: {
                    
                },
                onEndDragging: {
                    print("end")
                }
            )
            .frame(height: 40)
            
            frame
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
}

#Preview {
    ChooseTrackPieceView()
}

struct ScrollViewWithDelegate<Content: View>: UIViewRepresentable {
    let content: Content
    var onBeginDragging: (() -> Void)?
    var onEndDragging: (() -> Void)?
    
    init(@ViewBuilder content: () -> Content,
         onBeginDragging: (() -> Void)? = nil,
         onEndDragging: (() -> Void)? = nil) {
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
        let onEndDragging: (() -> Void)?
        
        init(onBeginDragging: (() -> Void)?, onEndDragging: (() -> Void)?) {
            self.onBeginDragging = onBeginDragging
            self.onEndDragging = onEndDragging
        }
        
        func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
            onBeginDragging?()
        }
        
        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            onEndDragging?()
        }
        
        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            if !decelerate {
                onEndDragging?()
            }
        }
    }
}
