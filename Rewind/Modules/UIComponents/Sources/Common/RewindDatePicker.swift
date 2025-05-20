import SwiftUI

public struct RewindDatePicker: View {
    var title: String
    @Binding var date: Date?
    
    public init(title: String, date: Binding<Date?>) {
        self.title = title
        self._date = date
    }
    
    public var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.textSecondary)
                .modifier(RoundFontModifier(size: 17, weight: .black))
                .padding(.leading, 16)
            
            HStack(spacing: 2) {
                Text(
                    dateBinding.wrappedValue
                        .formatted(.dateTime.day().month().year())
                )
                .foregroundColor(.textSecondary)
                .modifier(RoundFontModifier(size: 17, weight: .bold))
            }
            .padding(8)
            .frame(height: 52)
            .background(Color.background)
            .cornerRadius(16)
            .opacity(date == nil ? 0.5 : 1)
            .overlay {
                DatePicker(
                    selection: dateBinding,
                    in: ...Date(),
                    displayedComponents: .date
                ) {}
                .labelsHidden()
                .colorMultiply(.clear)
            }
            
            if date != nil {
                Button {
                    withAnimation { date = nil }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .black))
                        .frame(width: 34, height: 34)
                        .background(Color.background)
                        .foregroundColor(Color.textPrimary)
                        .cornerRadius(12)
                }
            }
        }
    }
        
    var dateBinding: Binding<Date> {
        Binding {
            return date ?? Date()
        } set: { newDate in
            date = newDate
        }
    }
}
