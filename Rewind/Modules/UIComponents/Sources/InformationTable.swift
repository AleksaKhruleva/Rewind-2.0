import SwiftUI

public struct InformationTable: View {
    let title: String
    let data: [(String, String, Bool)]
    let isRisky: Bool
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .foregroundColor(Color(isRisky ? "riskyTableNameTextColor" : "tableNameTextColor"))
                .font(.custom("Nunito-Black", size: 17))
                .padding(.leading, 15)
            
            VStack(alignment: .leading, spacing: 0) {
                ForEach(data, id: \.1) { item in
                    InformationTableCell(icon: item.0, text: item.1, needChevron: item.2)
                        .foregroundColor(Color(isRisky ? "riskyTableTextColor" : "tableTextColor"))
                }
            }
            .background(Color(isRisky ? "riskyTableBackgroundColor" : "tableBackgroundColor"))
            .cornerRadius(24)
        }
    }
}

struct InformationTableCell: View {
    let icon: String
    let text: String
    let needChevron: Bool
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .frame(width: 30, height: 30)
            
            Text(text)
                .font(.custom("Nunito-Black", size: 17))
            
            Spacer()
            
            if needChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 17))
                    .fontWeight(.black)
                    .frame(width: 30, height: 30)
            }
        }
        .onTapGesture {
            if needChevron {
                print("smth")
            }
        }
        .frame(height: 42)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        
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
}
