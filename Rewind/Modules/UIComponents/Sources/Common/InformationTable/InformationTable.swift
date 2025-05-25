import SwiftUI
import AccessibilitySupport

public struct InformationTable: View {
    private let title: String
    private let data: [(
        icon: String,
        title: String,
        accessibilityElement: RewindElement?,
        action: (() -> Void)?
    )]
    private let isRisky: Bool

    public init(
        title: String,
        data: [(String, String, RewindElement?, (() -> Void)?)],
        isRisky: Bool
    ) {
        self.title = title
        self.data = data
        self.isRisky = isRisky
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .modifier(
                    RoundFontModifier(
                        size: AccountConstants.defaultFontSize,
                        weight: .black,
                        foregroundColor: isRisky ? .riskySecondary : .textSecondary)
                    )
                .padding(.leading, 15)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(data, id: \.1) { item in
                    InformationTableCell(
                        icon: item.icon,
                        text: item.title,
                        needChevron: item.action != nil,
                        isRisky: isRisky,
                        accessibilityElement: item.accessibilityElement,
                        action: {
                            item.action?()
                        }
                    )
                }
            }
            .background(isRisky ? Color.riskyBackground : Color.backgroundSecondary)
            .cornerRadius(24)
        }
    }
}

#Preview {
    VStack {
        InformationTable(
            title: "Risky Zone",
            data: [
                ("star.fill", "Chevron there", nil, {}),
                ("star.fill", "Chevron there", nil, {})
            ],
            isRisky: true
        )

        InformationTable(title: "Table", data: [("person.fill", "Smth", nil, nil)], isRisky: false)

        InformationTable(
            title: "Table",
            data: [
                ("star.fill", "Chevron there", nil, {}),
                ("star.fill", "Chevron there", nil, {})
            ],
            isRisky: false
        )
    }
    .padding()
}
