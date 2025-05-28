import SwiftUI
import UIComponents

struct GroupNameInputView: View {
    @Binding var isPresented: Bool
    @Binding var isLoading: Bool
    @Binding var error: String?
    private let message: String
    private let onSubmit: (String) -> Void

    init(
        isPresented: Binding<Bool>,
        isLoading: Binding<Bool>,
        error: Binding<String?>,
        message: String,
        onSubmit: @escaping (String) -> Void
    ) {
        self._isPresented = isPresented
        self._isLoading = isLoading
        self._error = error
        self.message = message
        self.onSubmit = onSubmit
    }

    var body: some View {
        ZStack {
            if isLoading {
                ZStack {
                    Color.backgroundSecondary.ignoresSafeArea()

                    ProgressView(message)
                        .modifier(RoundFontModifier(size: 15))
                }
            } else {
                GenericInputSheetView(
                    item: .groupName,
                    title: "Enter group name",
                    placeholder: "Friends",
                    error: $error) { groupName in
                        onSubmit(groupName)
                    }
            }
        }
        .interactiveDismissDisabled(isLoading)
    }
}
