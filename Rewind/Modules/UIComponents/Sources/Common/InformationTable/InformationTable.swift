import SwiftUI

public struct InformationTable: View {
    private let title: String
    private let data: [(icon: String, title: String, action: (() -> Void)?)]
    private let isRisky: Bool
    
    public init(
        title: String,
        data: [(String, String, (() -> Void)?)],
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
                        foregroundColor:
                            isRisky ?
                            UIComponentsAsset.riskyTableNameTextColor.swiftUIColor :
                            UIComponentsAsset.tableNameTextColor.swiftUIColor
                        )
                    )
                .padding(.leading, 15)
            
            VStack(alignment: .leading, spacing: 0) {
                ForEach(data, id: \.1) { item in
                    InformationTableCell(
                        icon: item.icon,
                        text: item.title,
                        needChevron: item.action != nil,
                        isRisky: isRisky,
                        action: {
                            item.action?()
                        }
                    )
                }
            }
            .background(
                isRisky ?
                UIComponentsAsset.riskyTableBackgroundColor.swiftUIColor :
                UIComponentsAsset.tableBackgroundColor.swiftUIColor
            )
            .cornerRadius(24)
        }
    }
}

#Preview {
    VStack {
        InformationTable(
            title: "Risky Zone",
            data: [
                ("star.fill", "Chevron there", {}),
                ("star.fill", "Chevron there", {})
            ],
            isRisky: true
        )
        
        InformationTable(title: "Table", data: [("person.fill", "Smth", nil)], isRisky: false)
        
        InformationTable(
            title: "Table",
            data: [
                ("star.fill", "Chevron there", {}),
                ("star.fill", "Chevron there", {})
            ],
            isRisky: false
        )
    }
    .padding()
}
