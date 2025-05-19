import SwiftUI

public struct RewindToggle: View {
    var title: String
    var description: String?
    
    @Binding var isOn: Bool
    
    public init(title: String, description: String? = nil, isOn: Binding<Bool>) {
        self.title = title
        self.description = description
        self._isOn = isOn
    }
    
    public var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .modifier(RoundFontModifier(size: 17, weight: .bold))
                    .foregroundColor(.textPrimary)
                
                if let description {
                    Text(description)
                        .modifier(RoundFontModifier(size: 14, weight: .bold))
                        .foregroundColor(.textTertiaryLight)
                        .opacity(0.7)
                }
            }
            
            Spacer()
            
            Toggle(isOn: $isOn) {}
                .toggleStyle(SwitchToggleStyle(tint: Color.pinkPrimaryLight))
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}
