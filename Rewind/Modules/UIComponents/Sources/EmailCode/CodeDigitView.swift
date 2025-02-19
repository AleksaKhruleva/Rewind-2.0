import SwiftUI

struct CodeDigitView: View {
    private let digit: String
    private let isFocused: Bool
    private let showCaret: Bool
    
    init(
        digit: String,
        isFocused: Bool,
        showCaret: Bool
    ) {
        self.digit = digit
        self.isFocused = isFocused
        self.showCaret = showCaret
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(UIColor.systemGray6))
                .frame(width: 59, height: 75)
            
            Text(digit)
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundColor(.primary)
            
            if isFocused && showCaret {
                CaretView()
            }
        }
    }
}
