import SwiftUI
import UIComponents

public struct QuoteCreationView: View {
    @State var viewModel = QuoteCreationViewModel()
    @State var quoteWidth: CGFloat = .zero
    
    @State var backgroundColor: Color = .random
    @State var textColor: Color = .random
    
    @Environment(\.dismiss)
    private var dismiss
    @Environment(\.showToast)
    private var showToast
    
    public init() {}
    
    public var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            
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
                .modifier(MeasureWidthModifier(width: $quoteWidth))
                .padding(.horizontal, 8)
            }
            .safeAreaInset(edge: .bottom) {
                continueButton
            }
            .sheet(isPresented: $viewModel.quoteInputPresented) {
                quoteInputContent
            }
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
        Rectangle()
            .frame(width: quoteWidth, height: quoteWidth)
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
    
    @ViewBuilder
    private var emptyQuoteContent: some View {
        VStack {
            Image(systemName: "quote.bubble.fill")
                .font(.system(size: 130))
                .foregroundColor(.textSecondary)
            
            Text("Tap here to enter your quote")
                .modifier(RoundFontModifier(size: 15, weight: .bold))
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
            Text("Customizing")
                .modifier(
                    RoundFontModifier(
                        size: AccountConstants.defaultFontSize,
                        weight: .black,
                        foregroundColor: .textSecondary
                    )
                )
                .padding(.leading, 15)
            
            VStack(alignment: .leading, spacing: 0) {
                ColorPickerTableCell(text: "Background color", color: $backgroundColor)
                ColorPickerTableCell(text: "Text color", color: $textColor)
            }
            .background(Color.backgroundSecondary)
            .cornerRadius(24)
        }
        .disabledWithOpacity(viewModel.quoteState == .empty)
    }
    
    private var continueButton: some View {
        GradientButton(title: "Save quote", width: 200) {
            guard viewModel.quoteState == .ready else {
                showToast("You cannot continue with empty quote 👺")
                return
            }
            
            viewModel.dispatch(.saveQuote(AnyView(quoteContent)))
            
            showToast("Your quote was saved successfully! 💬")
            dismiss()
        }
        .disabledWithOpacity(viewModel.quoteState == .empty)
    }
}

extension Color {
    fileprivate static var random: Self {
        Color(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1)
        )
    }
}

#Preview {
    QuoteCreationView()
}
