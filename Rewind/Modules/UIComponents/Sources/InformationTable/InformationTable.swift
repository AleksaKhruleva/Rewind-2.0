import SwiftUI

public struct InformationTable: View {
    private let title: String
    private let data: [(String, String, Bool)]
    private let isRisky: Bool
    
    public init(title: String, data: [(String, String, Bool)], isRisky: Bool) {
        self.title = title
        self.data = data
        self.isRisky = isRisky
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .foregroundColor(
                    isRisky ?
                    UIComponentsAsset.riskyTableNameTextColor.swiftUIColor :
                    UIComponentsAsset.tableNameTextColor.swiftUIColor
                )
                .modifier(RoundFontModifier(size: AccountConstants.defaultFontSize, weight: .black))
                .padding(.leading, 15)
            
            VStack(alignment: .leading, spacing: 0) {
                ForEach(data, id: \.1) { item in
                    InformationTableCell(
                        icon: item.0,
                        text: item.1,
                        needChevron: item.2,
                        action: {
                            print(item.1)
                        }
                    )
                    .foregroundColor(
                        isRisky ?
                        UIComponentsAsset.riskyTableTextColor.swiftUIColor :
                        UIComponentsAsset.primaryColor.swiftUIColor
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
                ("star.fill", "Chevron there", true),
                ("star.fill", "Chevron there", true)
            ],
            isRisky: true
        )
        
        InformationTable(title: "Table", data: [("person.fill", "Smth", false)], isRisky: false)
        
        InformationTable(
            title: "Table",
            data: [
                ("star.fill", "Chevron there", true),
                ("star.fill", "Chevron there", true)
            ],
            isRisky: false
        )
    }
    .padding()
}
