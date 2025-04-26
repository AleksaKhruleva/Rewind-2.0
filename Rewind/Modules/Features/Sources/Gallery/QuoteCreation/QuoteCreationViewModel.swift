import SwiftUI
import UIComponents

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
    }
    
    var quoteInputPresented = false
    var authorInputPresented = false
    
    var quote: String = ""
    var author: String = ""
    var tags: [String] = []
    
    var quoteState: QuoteState {
        !quote.isEmpty && !author.isEmpty ? .ready : .empty
    }
    
    func dispatch(_ intent: Intent) {
        switch intent {
        case .presentQuoteInput:
            quoteInputPresented = true
        case .presentAuthorInput:
            guard !quote.isEmpty else { return }
            authorInputPresented = true
        case .dismissAll:
            guard !quote.isEmpty, !author.isEmpty else { return }
            quoteInputPresented = false
        case let .saveQuote(content):
            let renderer = ImageRenderer(content: content)
            
            saveImageWithToast(image: renderer.uiImage) { message in
                print(message)
            }
        case .resetQuote:
            quote = ""
            author = ""
        }
    }
}
