import MapKit
import Domain
import SwiftUI

struct ClusteredPoint: Identifiable, Equatable {
    let id: Int
    let coordinate: CLLocationCoordinate2D
    var points: [GalleryItem]

    init(coordinate: CLLocationCoordinate2D, points: [GalleryItem]) {
        self.id = points.first?.id ?? -1
        self.coordinate = coordinate
        self.points = points
    }

    static func == (lhs: ClusteredPoint, rhs: ClusteredPoint) -> Bool {
        lhs.points == rhs.points
    }
}
