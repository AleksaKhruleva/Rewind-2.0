import SwiftUI

public struct CodeView: View {
    @Binding private var code: String
    @FocusState private var isFocused: Bool
    
    private let numberOfDigits: Int
    
    public init(
        code: Binding<String>,
        isFocused: FocusState<Bool>,
        numberOfDigits: Int = 4
    ) {
        self._code = code
        self._isFocused = isFocused
        self.numberOfDigits = numberOfDigits
    }
    
    public var body: some View {
        HStack(spacing: 10) {
            ForEach(0 ..< numberOfDigits, id: \.self) { index in
                CodeDigitView(
                    digit: getDigit(at: index),
                    isFocused: isFocused,
                    showCaret: code.count == index && index < numberOfDigits
                )
            }
        }
        .onTapGesture {
            isFocused = true
        }
    }
    
    private func getDigit(at index: Int) -> String {
        guard index < code.count else { return "" }
        let charIndex = code.index(code.startIndex, offsetBy: index)
        return String(code[charIndex])
    }
}
