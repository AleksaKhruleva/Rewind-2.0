import SwiftUI
import UIComponents
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
    
    var allRewinds: [RewindOnMap]
    var visibleRewinds: [RewindOnMap]
    var group: String
    var onSelect: (UUID) -> Void
    
    @State private var option: ListOption = .visible
    
    var listRewinds: [RewindOnMap] {
        switch option {
        case .all:
            allRewinds
        case .visible:
            visibleRewinds
        }
    }
    
    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            
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
            .padding(.horizontal, 8)
            .padding(.top, 20)
        }
    }
}

#Preview {
    let demoImage1 = UIComponentsAsset.media1.image
    let demoImage2 = UIComponentsAsset.media3.image
    let demoImage3 = UIComponentsAsset.media8.image
    let demoImage4 = UIComponentsAsset.media10.image
    let demoImage5 = UIComponentsAsset.media2.image
    
    let points = [
        RewindOnMap(coordinate: CLLocationCoordinate2D(latitude: 55.7558, longitude: 37.6176), image: demoImage1),
        RewindOnMap(coordinate: CLLocationCoordinate2D(latitude: 55.8133, longitude: 37.39), image: demoImage2),
        RewindOnMap(coordinate: CLLocationCoordinate2D(latitude: 55.682, longitude: 37.5734), image: demoImage3),
        RewindOnMap(coordinate: CLLocationCoordinate2D(latitude: 55.782, longitude: 37.7734), image: demoImage4),
        RewindOnMap(coordinate: CLLocationCoordinate2D(latitude: 55.702, longitude: 37.5334), image: demoImage5)
    ]
    
    RewindsList(allRewinds: points, visibleRewinds: points, group: "Friends") { _ in }
}
