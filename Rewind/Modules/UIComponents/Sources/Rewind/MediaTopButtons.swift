import SwiftUI

public struct MediaTopButtons: View {
    let onDetailsTap: () -> Void
    let onSettingsTap: () -> Void

    public init(onDetailsTap: @escaping () -> Void = {}, onSettingsTap: @escaping () -> Void = {}) {
        self.onDetailsTap = onDetailsTap
        self.onSettingsTap = onSettingsTap
    }

    public var body: some View {
        HStack {
            Button(action: onSettingsTap) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20))
                    .frame(width: 36, height: 36)
                    .background(Color.backgroundSecondary)
                    .clipShape(Circle())
            }

            Button(action: onDetailsTap) {
                Text(UIComponentsStrings.Rewind.details)
                    .multilineTextAlignment(.center)
                    .modifier(RoundFontModifier(size: 15))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 10)
                    .background(Color.backgroundSecondary)
                    .clipShape(Capsule())
            }
        }
        .foregroundStyle(Color.textPrimary)
    }
}

#Preview {
    MediaTopButtons {
        print("View detaild")
    } onSettingsTap: {
        print("Open settings")
    }
}
