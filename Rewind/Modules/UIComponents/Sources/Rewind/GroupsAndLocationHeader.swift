import SwiftUI

public struct GroupsAndLocationHeader: View {
    private let groupCount: Int
    private let onGroupsTap: () -> Void
    private let onGlobeTap: () -> Void

    public init(
        groupCount: Int,
        onGroupsTap: @escaping () -> Void = {},
        onGlobeTap: @escaping () -> Void = {}
    ) {
        self.groupCount = groupCount
        self.onGroupsTap = onGroupsTap
        self.onGlobeTap = onGlobeTap
    }

    public var body: some View {
        HStack {
            Button(action: onGroupsTap) {
                HStack {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 17))

                    Text(UIComponentsStrings.Rewind.Groups.count(groupCount))
                        .modifier(RoundFontModifier(size: 15))

                    Image(systemName: "chevron.right")
                        .font(.system(size: 15, weight: .black))
                        .padding(.trailing, 4)
                }
                .padding(.horizontal, 10)
                .frame(height: 44)
                .background(Color.backgroundSecondary)
                .clipShape(Capsule())
            }

            Spacer()

            Button(action: onGlobeTap) {
                Image(systemName: "globe.asia.australia.fill")
                    .font(.system(size: 26))
                    .frame(width: 44, height: 44)
                    .background(Color.backgroundSecondary)
                    .clipShape(Circle())
            }
        }
        .foregroundStyle(Color.textPrimary)
    }
}
