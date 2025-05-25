import Testing
@testable import Features

@MainActor
struct QuoteCreationViewModelTests {
    typealias QuoteState = QuoteCreationViewModel.QuoteState

    private var viewModel: QuoteCreationViewModel!

    init() {
        viewModel = .init()
    }

    @Test(arguments: [
        ("", "", QuoteState.empty),
        ("q", "", QuoteState.empty),
        ("", "a", QuoteState.empty),
        ("q", "a", QuoteState.ready)
    ])
    func testQuoteState(quote: String, author: String, expected: QuoteState) {
        viewModel.quote = quote
        viewModel.author = author

        #expect(viewModel.quoteState == expected)
    }

    @Test
    func testPresentQuoteInput() {
        viewModel.dispatch(.presentQuoteInput)

        #expect(viewModel.quoteInputPresented)
    }

    @Test(arguments: [
        ("", false),
        ("aboba", true)
    ])
    func testPresentAuthorInput(quote: String, expectedAuthorInputPresented: Bool) {
        viewModel.quote = quote

        viewModel.dispatch(.presentAuthorInput)

        #expect(viewModel.authorInputPresented == expectedAuthorInputPresented)
    }

    @Test(arguments: [
        ("", "", true),
        ("q", "a", false)
    ])
    func testDismissAll(quote: String, author: String, expectedQuoteInputPresented: Bool) {
        viewModel.quote = quote
        viewModel.author = author
        viewModel.quoteInputPresented = true

        viewModel.dispatch(.dismissAll)

        #expect(viewModel.quoteInputPresented == expectedQuoteInputPresented)
    }

    @Test
    func testSaveQuotePrintsSomething() {
        // TODO: will be here later
    }

    @Test
    func testResetQuote() {
        viewModel.quote = "q"
        viewModel.author = "a"

        viewModel.dispatch(.resetQuote)

        #expect(viewModel.quote.isEmpty)
        #expect(viewModel.author.isEmpty)
    }
}
