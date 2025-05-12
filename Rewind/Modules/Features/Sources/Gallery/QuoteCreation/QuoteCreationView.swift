import SwiftUI
import UIComponents

public struct QuoteCreationView: View {
    @State var viewModel = QuoteCreationViewModel()
    
    @State var backgroundColor: Color = .random
    @State var textColor: Color = .random
    
    @Environment(\.dismiss)
    private var dismiss
    @Environment(\.showToast)
    private var showToast
    
    public init() {}
    
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
                    
                    generalTable
                    
                    TagsSectionView(tags: $viewModel.tags)
                }
            }
            .scrollIndicators(.hidden)
            .padding(.horizontal, 8)
        }
        .background(Color.background)
        .safeAreaInset(edge: .bottom) {
            continueButton
        }
        .sheet(isPresented: $viewModel.quoteInputPresented) {
            quoteInputContent
        }
    }
    
    private var header: some View {
        RewindHeader {
            RewindButton(type: .leftChevron) { dismiss() }
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
    
    private var continueButton: some View {
        GradientButton(title: UIComponentsStrings.Quote.save, width: .given(200)) {
            guard viewModel.quoteState == .ready else {
                showToast(UIComponentsStrings.Quote.Toast.empty)
                return
            }
            
            viewModel.dispatch(.saveQuote(AnyView(quoteContent)))
            
            showToast(UIComponentsStrings.Quote.Toast.success)
            dismiss()
        }
        .disabledWithOpacity(viewModel.quoteState == .empty)
    }
}

#Preview {
    QuoteCreationView()
}
