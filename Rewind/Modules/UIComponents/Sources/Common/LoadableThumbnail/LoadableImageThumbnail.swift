import Foundation
import SwiftUI
import Base

public struct LoadableImageThumbnail<Content: View>: View {
    @State private var url: URL?
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
            .task {
                await loadImage(url)
            }
            .onChange(of: url) { _ in
                print("URL CHANGED")
            }
    }

    private func loadImage(_ currentURL: URL?) async {
        animateState(to: .empty)
        guard let url = currentURL else {
            animateState(to: .failure)
            return
        }
        do {
//            let fileURL = url.deletingPathExtension().lastPathComponent
//            async let uiImage = await FileManagerImageStorage.shared.getImage(url: fileURL)
//            if let uiImage = await uiImage {
//                animateState(to: .ready(uiImage))
//                return
//            }
            async let (data, _) = try await URLSession.shared.data(from: url)
            if let uiImage = try await UIImage(data: data) {
//                await FileManagerImageStorage.shared.saveImage(image: uiImage, url: fileURL)
                animateState(to: .ready(uiImage))
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
