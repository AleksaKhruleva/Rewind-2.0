// swiftlint:disable identifier_name
import SwiftUI
import MapKit
import UIComponents

@MainActor @Observable
final class RewindsMapViewModel {
    enum Zoom {
        case `in`
        case out
    }

    enum Intent {
        case fetchRewinds
        case zoom(Zoom)
        case select(UUID)
        case reset
        case updateVisiblePoints
        case updateCamera
    }

    var points: [RewindOnMap]
    var visiblePoints: [RewindOnMap]
    var clusters: [ClusteredPoint]

    var selectedPointID: UUID?
    var region: MKCoordinateRegion
    var cameraPosition: MapCameraPosition

    var isSelected: Bool {
        selectedPointID != nil
    }

    init() {
        points = []
        visiblePoints = []
        clusters = []
        cameraPosition = .automatic
        region = .init(
            center: .init(latitude: 0, longitude: 0),
            span: .init(latitudeDelta: 0, longitudeDelta: 0)
        )
    }

    func dispatch(_ intent: Intent) {
        switch intent {
        case .fetchRewinds:
            let demoImage1 = UIComponentsAsset.media1.image
            let demoImage2 = UIComponentsAsset.media3.image
            let demoImage3 = UIComponentsAsset.media8.image
            let demoImage4 = UIComponentsAsset.media10.image
            let demoImage5 = UIComponentsAsset.media2.image

            let demoImage6 = UIComponentsAsset.media4.image
            let demoImage7 = UIComponentsAsset.media7.image
            let demoImage8 = UIComponentsAsset.media6.image

            // swiftlint:disable line_length
            points = [
                RewindOnMap(coordinate: CLLocationCoordinate2D(latitude: 55.7558, longitude: 37.6176), image: demoImage1),
                RewindOnMap(coordinate: CLLocationCoordinate2D(latitude: 55.8133, longitude: 37.39), image: demoImage2),
                RewindOnMap(coordinate: CLLocationCoordinate2D(latitude: 55.682, longitude: 37.5734), image: demoImage3),
                RewindOnMap(coordinate: CLLocationCoordinate2D(latitude: 55.782, longitude: 37.7734), image: demoImage4),
                RewindOnMap(coordinate: CLLocationCoordinate2D(latitude: 55.702, longitude: 37.5334), image: demoImage5),
                RewindOnMap(coordinate: CLLocationCoordinate2D(latitude: 55.902, longitude: 37.5014), image: demoImage6),
                RewindOnMap(coordinate: CLLocationCoordinate2D(latitude: 55.862, longitude: 37.6334), image: demoImage7),
                RewindOnMap(coordinate: CLLocationCoordinate2D(latitude: 55.812, longitude: 37.5123), image: demoImage8)
            ]
            // swiftlint:enable line_length
        case let .zoom(type):
            let factor = type == .in ? 0.6 : 1.4
            let span = MKCoordinateSpan(
                latitudeDelta: region.span.latitudeDelta * factor,
                longitudeDelta: region.span.longitudeDelta * factor
            )

            region = MKCoordinateRegion(center: region.center, span: span)
            calculateClusters()
            dispatch(.updateCamera)
        case let .select(id):
            if let point = points.first(where: { $0.id == id }) {
                selectedPointID = id
                region = MKCoordinateRegion(
                    center: point.coordinate,
                    span: .init(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
                dispatch(.updateCamera)
            }
        case .reset:
            selectedPointID = nil
            region = MKCoordinateRegion(
                center: region.center,
                span: .init(latitudeDelta: 0.5, longitudeDelta: 0.5)
            )
            dispatch(.updateCamera)
        case .updateVisiblePoints:
            visiblePoints = points.filter { point in
                region.contains(point.coordinate)
            }
        case .updateCamera:
            withAnimation {
                cameraPosition = .region(region)
            }
        }
    }

    func isSelected(for cluster: ClusteredPoint) -> Bool {
        cluster.points.contains(where: { $0.id == selectedPointID })
    }

    func centerCoordinate() -> CLLocationCoordinate2D? {
        guard !points.isEmpty else { return nil }
        let lat = points.map { $0.coordinate.latitude }.reduce(0, +) / Double(points.count)
        let lon = points.map { $0.coordinate.longitude }.reduce(0, +) / Double(points.count)
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    func calculateClusters() {
        let threshold: CLLocationDistance = region.span.latitudeDelta * 10000
        var clusters: [ClusteredPoint] = []

        for point in points {
            var found = false
            for (index, cluster) in clusters.enumerated() {
                let distance = CLLocation(latitude: point.coordinate.latitude, longitude: point.coordinate.longitude)
                    .distance(from: CLLocation(
                        latitude: cluster.coordinate.latitude,
                        longitude: cluster.coordinate.longitude
                    ))
                if distance < threshold {
                    clusters[index].points.append(point)
                    clusters[index] = ClusteredPoint(
                        coordinate: averageCoordinate(of: clusters[index].points),
                        points: clusters[index].points
                    )
                    found = true
                    break
                }
            }
            if !found {
                clusters.append(ClusteredPoint(coordinate: point.coordinate, points: [point]))
            }
        }
        if self.clusters != clusters {
            self.clusters = clusters
        }
    }

    private func averageCoordinate(of points: [RewindOnMap]) -> CLLocationCoordinate2D {
        let lat = points.map { $0.coordinate.latitude }.reduce(0, +) / Double(points.count)
        let lon = points.map { $0.coordinate.longitude }.reduce(0, +) / Double(points.count)
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}
// swiftlint:enable identifier_name
