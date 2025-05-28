import SwiftUI
import UIComponents
import Domain
import MapKit

struct RewindsList: View {
    enum ListOption: SegmentedItem {
        var id: Self { self }

        case all
        case visible

        var title: String {
            switch self {
            case .all: UIComponentsStrings.Map.RewindsList.all
            case .visible: UIComponentsStrings.Map.RewindsList.visible
            }
        }
    }

    var allRewinds: [GalleryItem]
    var visibleRewinds: [GalleryItem]
    var group: String
    var onSelect: (Int) -> Void

    @State private var option: ListOption = .visible

    var listRewinds: [GalleryItem] {
        switch option {
        case .all:
            allRewinds
        case .visible:
            visibleRewinds
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(UIComponentsStrings.Map.RewindsList.title)
                .modifier(RoundFontModifier(size: 21))

            Text(UIComponentsStrings.Map.RewindsList.group(group))
                .modifier(RoundFontModifier(size: 16, weight: .semibold, foregroundColor: .textSecondary))
                .padding(.top, 4)

            SegmentedPicker(selection: $option, items: [.visible, .all])
                .opacity(allRewinds.count == visibleRewinds.count ? 0.4 : 1)
                .disabled(allRewinds.count == visibleRewinds.count)
                .padding()

            ScrollView {
                ForEach(listRewinds) { rewind in
                    RewindsListCell(rewind: rewind)
                        .onTapGesture {
                            onSelect(rewind.id)
                        }

                    if let last = listRewinds.last, rewind != last {
                        Divider()
                            .frame(height: 2)
                            .padding(.horizontal, 16)
                    }
                }

                RewindNoteTextView(text: UIComponentsStrings.Note.end)
                    .padding(.top, 4)
            }
            .scrollIndicators(.hidden)
        }
        .background(Color.background)
        .padding(.horizontal, 8)
        .padding(.top, 20)
    }
}
