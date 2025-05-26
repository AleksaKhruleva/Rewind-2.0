import Foundation
import SwiftUI

public struct LoadableImageThumbnail<Content: View>: View {
    let url: URL?
    @ViewBuilder let content: (LoadableMediaState) -> Content
    @State private var state: LoadableMediaState = .empty

    public var body: some View {
        content(state)
            .task(id: url) {
                await loadImage(url)
            }
    }

    @MainActor
    private func loadImage(_ currentUrl: URL?) async {
        animateState(to: .empty)
        guard let url = currentUrl else {
            animateState(to: .failure)
            return
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let uiImage = UIImage(data: data) {
                let image = Image(uiImage: uiImage)
                animateState(to: .ready(image))
            } else {
                animateState(to: .failure)
            }
        } catch {
            animateState(to: .failure)
        }
    }

    private func animateState(to state: LoadableMediaState) {
        withAnimation {
            self.state = state
        }
    }
}
