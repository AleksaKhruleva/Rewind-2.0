import SwiftUI
import UIComponents
import Domain
import Base
import Networking

@MainActor @Observable
final class QuoteCreationViewModel {
    enum QuoteState {
        case empty
        case ready
    }

    enum Intent {
        case presentQuoteInput
        case presentAuthorInput
        case dismissAll
        case createQuote(AnyView)
        case resetQuote
        case findTrack
        case trackSelected(Track)
        case resumePlayback
    }

    var quoteInputPresented = false
    var authorInputPresented = false
    var backgroundColor: Color = .random
    var textColor: Color = .random
    var findTrackViewPresented = false
    var isSelectedTrackPlaying = true

    var quote: String = ""
    var author: String = ""
    var tags: [MediaTag] = []

    var selectedTrack: Track?
    var selectedStartTime: Double = 0
    var selectedDuration: CGFloat = 15
    var trackScrollOffset: CGFloat = 0

    var quoteState: QuoteState {
        !quote.isEmpty && !author.isEmpty ? .ready : .empty
    }

    private let backend = NetworkService()

    func dispatch(
        _ intent: Intent,
        onSuccess: @escaping () -> Void = {},
        onFailure: @escaping () -> Void = {}
    ) {
        switch intent {
        case .presentQuoteInput:
            isSelectedTrackPlaying = false
            quoteInputPresented = true
        case .presentAuthorInput:
            guard !quote.isEmpty else { return }
            authorInputPresented = true
        case .dismissAll:
            guard !quote.isEmpty, !author.isEmpty else { return }
            quoteInputPresented = false
            isSelectedTrackPlaying = true
        case let .createQuote(content):
            Task {
                let renderer = ImageRenderer(content: content)
                renderer.scale = UIScreen.main.scale
                renderer.proposedSize = .init(CGSize(
                    width: UIScreen.main.bounds.width,
                    height: UIScreen.main.bounds.width
                ))

                do {
                    if let quoteImage = renderer.uiImage,
                       let tokens = Tokens(),
                       let groupId = GroupStorage.currentGroup?.id {
                        var musicId: String?
                        if let selectedTrack {
                            musicId = String(selectedTrack.id)
                        }

                        _ = try await backend
                            .addMedia(
                                tokens: tokens,
                                groupId: groupId,
                                mediaType: "quote",
                                mediaFile: .image(quoteImage),
                                musicId: musicId,
                                offset: selectedStartTime,
                                duration: selectedDuration,
                                tags: tags
                            )
                        onSuccess()
                    }
                } catch {
                    onFailure()
                }
            }
        case .resetQuote:
            quote = ""
            author = ""
        case .findTrack:
            isSelectedTrackPlaying = false
            findTrackViewPresented = true
        case let .trackSelected(track):
            selectedTrack = track
        case .resumePlayback:
            isSelectedTrackPlaying = true
        }
    }
}
