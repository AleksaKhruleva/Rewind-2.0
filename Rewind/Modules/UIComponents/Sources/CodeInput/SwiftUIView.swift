import SwiftUI

public struct CodeInputTextField: View {
    @Binding
    var code: [String]
    var error: Error?
    var onCodeFilledUpdate: (Bool) -> Void
    
    @State
    private var focusedField: Int = 0
    
    public init(
        code: Binding<[String]>,
        error: Error? = nil,
        onCodeFilledUpdate: @escaping (Bool) -> Void
    ) {
        self._code = code
        self.error = error
        self.onCodeFilledUpdate = onCodeFilledUpdate
    }
    
    public var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<4, id: \.self) { index in
                CodeDigitTextFieldAdapter(code: $code, focusedField: $focusedField, tag: index)
                    .frame(width: 60, height: 75)
            }
        }
        .onChange(of: code) { _, newValue in focusedField = newValue.count }
        .onChange(of: code.count == 4) { _, newValue in onCodeFilledUpdate(newValue) }
    }
}
