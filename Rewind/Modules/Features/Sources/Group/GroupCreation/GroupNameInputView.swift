import SwiftUI
import UIComponents

struct GroupNameInputView: View {
    @Binding var isPresented: Bool
    @Binding var isLoading: Bool
    private let onSubmit: (String) -> Void
    
    init(isPresented: Binding<Bool>, isLoading: Binding<Bool>, onSubmit: @escaping (String) -> Void) {
        self._isPresented = isPresented
        self._isLoading = isLoading
        self.onSubmit = onSubmit
    }
    
    var body: some View {
        Group {
            if isLoading {
                ZStack {
                    Color.backgroundSecondary.ignoresSafeArea()
                    
                    ProgressView("Creating new group...")
                        .modifier(RoundFontModifier(size: 15))
                }
            } else {
                GenericInputSheetView(
                    item: .groupName,
                    title: "Enter group name",
                    placeholder: "Friends") { groupName in
                        onSubmit(groupName)
                    }
            }
        }
    }
}
