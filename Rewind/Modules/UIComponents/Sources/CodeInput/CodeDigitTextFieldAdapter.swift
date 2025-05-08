import SwiftUI
import UIKit

public struct CodeDigitTextFieldAdapter: UIViewRepresentable {
    @Binding var code: [String]
    @Binding var focusedField: Int
    var backgroundColor: UIColor
    var index: Int
    
    public init(
        code: Binding<[String]>,
        focusedField: Binding<Int>,
        backgroundColor: UIColor,
        tag: Int
    ) {
        self._code = code
        self._focusedField = focusedField
        self.backgroundColor = backgroundColor
        self.index = tag
    }
    
    public func makeUIView(context: Context) -> CodeDigitTextField {
        let textField = CodeDigitTextField()
        textField.textAlignment = .center
        textField.keyboardType = .numberPad
        textField.font = UIFont.monospacedSystemFont(ofSize: 22, weight: .semibold)
        textField.backgroundColor = backgroundColor
        textField.tintColor = UIComponentsAsset.pinkPrimary.color
        textField.layer.cornerRadius = 14
        textField.delegate = context.coordinator
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textChanged), for: .editingChanged)
        textField.onBackspace = { isEmpty in
            if isEmpty {
                context.coordinator.stepBackward()
            }
            code[isEmpty ? max(0, index - 1) : index] = ""
        }
        return textField
    }
    
    public func updateUIView(_ uiView: CodeDigitTextField, context _: Context) {
        uiView.text = code[index]
        if focusedField == index, !uiView.isFirstResponder {
            DispatchQueue.main.async {
                uiView.becomeFirstResponder()
            }
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(code: $code, focusedField: $focusedField, tag: index)
    }
    
    public final class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var code: [String]
        @Binding var focusedField: Int
        var tag: Int
        
        init(code: Binding<[String]>, focusedField: Binding<Int>, tag: Int) {
            _code = code
            _focusedField = focusedField
            self.tag = tag
        }
        
        @objc func textChanged(_ textField: UITextField) {
            if let textValue = textField.text, !textValue.isEmpty {
                code[tag] = String(textValue.prefix(1))
                stepForward()
            }
        }
        
        public func textField(_: UITextField, shouldChangeCharactersIn _: NSRange, replacementString string: String) -> Bool {
            // No need to move cursor, when backspacing on current cell
            if string.isEmpty, !code[tag].isEmpty {
                return true
            }
            
            // Step forward, when replacing non-empty current cell with new value
            if !string.isEmpty, !code[tag].isEmpty {
                code[tag] = string
                stepForward()
                return false
            }
            
            // Step backward, when current cell is empty
            if string.isEmpty, code[tag].isEmpty {
                stepBackward()
                return false
            }
            
            return true
        }
        
        func stepForward() {
            focusedField = tag + 1
        }
        
        func stepBackward() {
            focusedField = max(0, tag - 1)
        }
    }
}

public final class CodeDigitTextField: UITextField {
    var onBackspace: ((Bool) -> Void)?
    
    public override func deleteBackward() {
        onBackspace?(text?.isEmpty == true)
        super.deleteBackward()
    }
}
