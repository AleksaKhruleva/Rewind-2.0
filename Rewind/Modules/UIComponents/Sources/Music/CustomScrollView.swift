import SwiftUI

public struct CustomScrollView<Content: View>: UIViewRepresentable {
    private var externalOffset: CGFloat
    private let content: Content
    private let onBeginDragging: (() -> Void)
    private let onEndDragging: ((_ offset: CGFloat) -> Void)
    private let onScroll: ((_ offset: CGFloat) -> Void)

    public init(
        externalOffset: CGFloat,
        @ViewBuilder content: () -> Content,
        onBeginDragging: @escaping (() -> Void),
        onEndDragging: @escaping ((_ offset: CGFloat) -> Void),
        onScroll: @escaping ((_ offset: CGFloat) -> Void)
    ) {
        self.externalOffset = externalOffset
        self.content = content()
        self.onBeginDragging = onBeginDragging
        self.onEndDragging = onEndDragging
        self.onScroll = onScroll
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(
            onBeginDragging: onBeginDragging,
            onEndDragging: onEndDragging,
            onScroll: onScroll
        )
    }

    public func makeUIView(context: Context) -> UIScrollView {
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

    public func updateUIView(_ uiView: UIScrollView, context: Context) {
        uiView.subviews.forEach { $0.removeFromSuperview() }

        let hostedView = UIHostingController(rootView: content)
        hostedView.view.translatesAutoresizingMaskIntoConstraints = false
        hostedView.view.backgroundColor = .clear

        uiView.addSubview(hostedView.view)

        NSLayoutConstraint.activate([
            hostedView.view.topAnchor.constraint(equalTo: uiView.topAnchor),
            hostedView.view.bottomAnchor.constraint(equalTo: uiView.bottomAnchor),
            hostedView.view.leadingAnchor.constraint(equalTo: uiView.leadingAnchor),
            hostedView.view.trailingAnchor.constraint(equalTo: uiView.trailingAnchor),
            hostedView.view.heightAnchor.constraint(equalTo: uiView.heightAnchor)
        ])

        if !context.coordinator.hasAppliedOffset {
            context.coordinator.hasAppliedOffset = true
            DispatchQueue.main.async {
                uiView.setContentOffset(CGPoint(x: externalOffset, y: 0), animated: false)
            }
        }
    }

    public final class Coordinator: NSObject, UIScrollViewDelegate {
        private let onBeginDragging: (() -> Void)?
        private let onEndDragging: ((_ offset: CGFloat) -> Void)?
        private let onScroll: ((_ offset: CGFloat) -> Void)?
        var hasAppliedOffset = false

        init(
            onBeginDragging: (() -> Void)?,
            onEndDragging: ((_ offset: CGFloat) -> Void)?,
            onScroll: ((_ offset: CGFloat) -> Void)?
        ) {
            self.onBeginDragging = onBeginDragging
            self.onEndDragging = onEndDragging
            self.onScroll = onScroll
        }

        public func scrollViewDidScroll(_ scrollView: UIScrollView) {
            onScroll?(scrollView.contentOffset.x)
        }

        public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
            onBeginDragging?()
        }

        public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            onEndDragging?(scrollView.contentOffset.x)
        }

        public func scrollViewDidEndDragging(
            _ scrollView: UIScrollView,
            willDecelerate decelerate: Bool
        ) {
            if !decelerate {
                onEndDragging?(scrollView.contentOffset.x)
            }
        }
    }
}
