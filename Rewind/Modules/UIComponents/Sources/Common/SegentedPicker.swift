import SwiftUI

public protocol SegmentedItem: Identifiable, Equatable {
    var title: String { get }
}

@MainActor
public struct SegmentedPicker<Item: SegmentedItem>: View {
    @Binding var selection: Item
    var items: [Item]

    public init(selection: Binding<Item>, items: [Item]) {
        self._selection = selection
        self.items = items
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            HStack(spacing: 4) {
                ForEach(items.reversed().drop(while: { $0.id != selection.id }).dropFirst()) {
                    makeItemView($0)
                }.hidden()

                makeItemView(selection).hidden().background {
                    RoundedRectangle(cornerRadius: 10)
                        .foregroundColor(.background)
                }

                ForEach(items.drop(while: { $0.id != selection.id }).dropFirst()) {
                    makeItemView($0)
                }.hidden()
            }

            HStack(spacing: 4) {
                ForEach(items) { item in
                    makeItemView(item).simultaneousGesture(TapGesture().onEnded {
                        if selection.id != item.id {
                            withAnimation(.spring(response: 0.4)) {
                                selection = item
                            }
                        }})
                }
            }
        }
        .padding(4)
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
    }

    private func makeItemView(_ item: Item) -> some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            Text(item.title)
                .modifier(RoundFontModifier(size: 16, weight: .semibold))
            Spacer(minLength: 0)
        }
        .padding(6)
        .contentShape(Rectangle())
        .cornerRadius(10)
    }
}
