// swiftlint:disable identifier_name
import SwiftUI
import MapKit
import Domain
import UIComponents

@MainActor @Observable
final class RewindsMapViewModel {
    enum Zoom {
        case `in`
        case out
    }

    enum Intent {
        case zoom(Zoom)
        case select(Int)
        case reset
        case updateVisiblePoints
        case updateCamera
    }

    var points: [GalleryItem]
    var visiblePoints: [GalleryItem]
    var clusters: [ClusteredPoint]

    var selectedPointID: Int?
    var region: MKCoordinateRegion
    var cameraPosition: MapCameraPosition

    var isSelected: Bool {
        selectedPointID != nil
    }

    init(galleryItems: [GalleryItem]) {
        points = galleryItems
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
            print("selectedPointID = nil")
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

    private func averageCoordinate(of points: [GalleryItem]) -> CLLocationCoordinate2D {
        let lat = points.map { $0.coordinate.latitude }.reduce(0, +) / Double(points.count)
        let lon = points.map { $0.coordinate.longitude }.reduce(0, +) / Double(points.count)
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}
// swiftlint:enable identifier_name

extension GalleryItem {
    fileprivate var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: self.memory.latitude!,
            longitude: self.memory.longitude!
        )
    }
}
