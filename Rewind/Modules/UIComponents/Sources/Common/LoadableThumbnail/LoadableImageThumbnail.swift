import Foundation
import SwiftUI
import Base

public struct LoadableImageThumbnail<Content: View>: View {
    private var url: URL?
    @ViewBuilder let content: (LoadableMediaState) -> Content
    @State private var state: LoadableMediaState = .empty

    public init(
        url: URL? = nil,
        content: @escaping (LoadableMediaState) -> Content
    ) {
        self.url = url
        self.content = content
    }

    public var body: some View {
        content(state)
            .onChange(of: url) { _, newValue in
                Task { await loadImage(newValue) }
            }
            .task {
                await loadImage(url)
            }
    }

    private func loadImage(_ currentURL: URL?) async {
        animateState(to: .empty)
        guard let url = currentURL else {
            animateState(to: .failure)
            return
        }
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await ImageProvider.loadAndCacheImage(for: url.absoluteString, .media)
            }
        }
        let uiImage = await ImageProvider.loadOrGetImage(
            for: url.absoluteString,
            .media
        )
        animateState(to: .ready(uiImage))
    }

    private func animateState(to state: LoadableMediaState) {
        withAnimation {
            self.state = state
        }
    }
}
