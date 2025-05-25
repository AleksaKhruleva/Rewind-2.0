import SwiftUI
import UIComponents
import Domain

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
        case saveQuote(AnyView)
        case resetQuote
        case findTrack
        case trackSelected(Track)
        case resumePlayback
    }

    var quoteInputPresented = false
    var authorInputPresented = false
    var findTrackViewPresented = false
    var isSelectedTrackPlaying = true

    var quote: String = ""
    var author: String = ""
    var tags: [String] = []

    var selectedTrack: Track?
    var selectedStartTime: Double = 0
    var selectedDuration: CGFloat = 15

    var quoteState: QuoteState {
        !quote.isEmpty && !author.isEmpty ? .ready : .empty
    }

    func dispatch(_ intent: Intent) {
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
        case let .saveQuote(content):
            let renderer = ImageRenderer(content: content)

            saveImageWithToast(image: renderer.uiImage) { message in
                print(message)
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
