import Testing
@testable import Features

@MainActor
struct QuoteCreationViewModelTests {
    
    typealias QuoteState = QuoteCreationViewModel.QuoteState
    
    private var vm: QuoteCreationViewModel!
    
    init() {
        vm = .init()
    }
    
    @Test(arguments: [
        ("", "", QuoteState.empty),
        ("q", "", QuoteState.empty),
        ("", "a", QuoteState.empty),
        ("q", "a", QuoteState.ready)
    ])
    func testQuoteState(quote: String, author: String, expected: QuoteState) {
        vm.quote = quote
        vm.author = author
        
        #expect(vm.quoteState == expected)
    }
    
    @Test
    func testPresentQuoteInput() {
        vm.dispatch(.presentQuoteInput)
        
        #expect(vm.quoteInputPresented == true)
    }
    
    @Test(arguments: [
        ("", false),
        ("aboba", true)
    ])
    func testPresentAuthorInput(quote: String, expectedAuthorInputPresented: Bool) {
        vm.quote = quote
        
        vm.dispatch(.presentAuthorInput)
        
        #expect(vm.authorInputPresented == expectedAuthorInputPresented)
    }
    
    @Test(arguments: [
        ("", "", true),
        ("q", "a", false)
    ])
    func testDismissAll(quote: String, author: String, expectedQuoteInputPresented: Bool) {
        vm.quote = quote
        vm.author = author
        vm.quoteInputPresented = true
        
        vm.dispatch(.dismissAll)
        
        #expect(vm.quoteInputPresented == expectedQuoteInputPresented)
    }
    
    @Test
    func testSaveQuotePrintsSomething() {
        // TODO: will be here later
    }
    
    @Test
    func testResetQuote() {
        vm.quote = "q"
        vm.author = "a"
        
        vm.dispatch(.resetQuote)
        
        #expect(vm.quote.isEmpty)
        #expect(vm.author.isEmpty)
    }
}
