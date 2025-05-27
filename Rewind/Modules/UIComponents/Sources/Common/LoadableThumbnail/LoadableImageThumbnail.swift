import Foundation
import SwiftUI
import Base

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

    private func loadImage(_ currentURL: URL?) async {
        animateState(to: .empty)
        guard let url = currentURL else {
            animateState(to: .failure)
            return
        }
        do {
            let fileURL = url.deletingPathExtension().lastPathComponent
            if let uiImage = FileManagerImageStorage.shared.getImage(url: fileURL) {
                animateState(to: .ready(Image(uiImage: uiImage)))
                return
            }
            let (data, _) = try await URLSession.shared.data(from: url)
            if let uiImage = UIImage(data: data) {
                FileManagerImageStorage.shared.saveImage(image: uiImage, url: fileURL)
                animateState(to: .ready(Image(uiImage: uiImage)))
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
