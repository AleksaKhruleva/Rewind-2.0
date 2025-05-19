import SwiftUI
import UIComponents

public struct QuoteCreationView: View {
    @State var viewModel = QuoteCreationViewModel()
    
    @State var backgroundColor: Color = .random
    @State var textColor: Color = .random
    
    @Environment(\.showToast)
    private var showToast
    
    private let router: AppRouter
    
    public init(router: AppRouter) {
        self.router = router
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            header
            
            ScrollView {
                VStack(spacing: 16) {
                    quoteContent
                        .cornerRadius(40)
                        .onTapGesture {
                            viewModel.dispatch(.presentQuoteInput)
                        }
                        .padding(.horizontal, 8)
                    
                    generalTable
                        .padding(.horizontal, 8)
                    
                    musicSection
                    
                    TagsSectionView(tags: $viewModel.tags)
                        .padding(.horizontal, 8)
                }
            }
            .scrollIndicators(.hidden)
        }
        .background(Color.background)
        .safeAreaInset(edge: .bottom) {
            continueButton
        }
        .sheet(isPresented: $viewModel.quoteInputPresented, onDismiss: {
            viewModel.dispatch(.resumePlayback)
        }) {
            quoteInputContent
        }
        .sheet(isPresented: $viewModel.findTrackViewPresented, onDismiss: {
            viewModel.dispatch(.resumePlayback)
        }) {
            FindTrackView { selectedTrack in
                viewModel.dispatch(.trackSelected(selectedTrack))
            }
        }
    }
    
    private var header: some View {
        RewindHeader {
            RewindButton(type: .leftChevron) { router.pop() }
        } rightView: {
            RewindButton(type: .trash) {
                guard viewModel.quoteState != .empty else { return }
                withAnimation(.spring(response: 0.2, blendDuration: 0.3)) {
                    viewModel.dispatch(.resetQuote)
                }
            }
            .foregroundColor(.red)
            .disabledWithOpacity(viewModel.quoteState == .empty)
        }
    }
    
    private var quoteContent: some View {
        RoundedRectangle(cornerRadius: 40)
            .fill(Color.backgroundSecondary)
            .aspectRatio(1, contentMode: .fit)
            .foregroundColor(
                viewModel.quoteState == .empty ?
                    .backgroundSecondary : backgroundColor
            )
            .overlay {
                switch viewModel.quoteState {
                case .empty: emptyQuoteContent
                case .ready: readyQuoteContent
                }
            }
    }
    
    private var emptyQuoteContent: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 40)
                .fill(Color.backgroundSecondary)
                .aspectRatio(1, contentMode: .fit)
            
            VStack {
                Image(systemName: "quote.bubble.fill")
                    .font(.system(size: 130))
                    .foregroundColor(.textSecondary)
                
                Text(UIComponentsStrings.Quote.hint)
                    .modifier(RoundFontModifier(size: 15, weight: .bold))
            }
        }
    }
    
    private var readyQuoteContent: some View {
        ZStack {
            Text(viewModel.quote)
                .font(.system(size: 30, weight: .semibold, design: .monospaced))
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text(viewModel.author)
                        .font(.system(size: 20, weight: .semibold, design: .monospaced))
                }
            }
        }
        .foregroundColor(textColor)
        .padding(24)
    }
    
    private var quoteInputContent: some View {
        QuoteInputView(quote: $viewModel.quote) {
            viewModel.dispatch(.presentAuthorInput)
        }
        .sheet(isPresented: $viewModel.authorInputPresented) {
            AuthorInputView(author: $viewModel.author) {
                viewModel.dispatch(.dismissAll)
            }
        }
    }
    
    private var generalTable: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(UIComponentsStrings.Quote.customizing)
                .modifier(
                    RoundFontModifier(
                        size: AccountConstants.defaultFontSize,
                        weight: .black,
                        foregroundColor: .textSecondary
                    )
                )
                .padding(.leading, 15)
            
            VStack(alignment: .leading, spacing: 0) {
                ColorPickerTableCell(text: UIComponentsStrings.Quote.Customizing.background, color: $backgroundColor)
                ColorPickerTableCell(text: UIComponentsStrings.Quote.Customizing.text, color: $textColor)
            }
            .background(Color.backgroundSecondary)
            .cornerRadius(24)
        }
        .disabledWithOpacity(viewModel.quoteState == .empty)
    }
    
    private var musicSection: some View {
        VStack {
            MusicSectionView(
                selectedTrack: $viewModel.selectedTrack) {
                    viewModel.dispatch(.findTrack)
                }
                .padding(.horizontal, 8)
            
            if let selectedTrack = viewModel.selectedTrack {
                ChooseTrackPieceView(
                    shouldPlay: $viewModel.isSelectedTrackPlaying,
                    startTime: $viewModel.selectedStartTime,
                    selectorDuration: $viewModel.selectedDuration,
                    selectedTrack: selectedTrack,
                    onTrashTap: {
                        withAnimation {
                            viewModel.selectedTrack = nil
                        }
                    }
                )
                .id(selectedTrack.id)
            }
        }
    }
    
    private var continueButton: some View {
        GradientButton(title: UIComponentsStrings.Quote.save, width: .given(200)) {
            guard viewModel.quoteState == .ready else {
                showToast(UIComponentsStrings.Quote.Toast.empty)
                return
            }
            
            // TODO: delete later
            let trackInfo = (
                viewModel.selectedTrack?.id,
                viewModel.selectedStartTime,
                viewModel.selectedDuration
            )
            
            print(trackInfo)
            
            viewModel.dispatch(.saveQuote(AnyView(quoteContent)))
            
            showToast(UIComponentsStrings.Quote.Toast.success)
            router.pop()
        }
        .disabledWithOpacity(viewModel.quoteState == .empty)
    }
}
