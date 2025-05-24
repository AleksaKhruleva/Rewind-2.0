import MapKit
import SwiftUI

struct RewindOnMap: Identifiable, Equatable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let image: UIImage

    static func == (lhs: RewindOnMap, rhs: RewindOnMap) -> Bool {
        lhs.id == rhs.id
    }
}

struct ClusteredPoint: Identifiable, Equatable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    var points: [RewindOnMap]

    static func == (lhs: ClusteredPoint, rhs: ClusteredPoint) -> Bool {
        lhs.points == rhs.points
    }
}
