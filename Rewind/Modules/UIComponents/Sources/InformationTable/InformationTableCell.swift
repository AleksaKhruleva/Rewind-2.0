import SwiftUI

struct InformationTableCell: View {
    let icon: String
    let text: String
    let needChevron: Bool
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .frame(width: 30, height: 30)
            
            Text(text)
                .font(.system(size: 17, weight: .bold, design: .rounded))
            
            Spacer()
            
            if needChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 17))
                    .fontWeight(.bold)
                    .frame(width: 30, height: 30)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if needChevron {
                action()
            }
        }
        .frame(height: 42)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
}
