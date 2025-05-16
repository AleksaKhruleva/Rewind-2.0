import SwiftUI
import MapKit
import UIComponents

public struct RewindsMap: View {
    @State private var viewModel: RewindsMapViewModel
    @State private var badgeWidth: CGFloat = .zero
    
    @State private var isRewindsListPresented = false
    
    private let router: AppRouter
    
    public init(router: AppRouter) {
        viewModel = RewindsMapViewModel()
        self.router = router
    }
    
    public var body: some View {
        ZStack(alignment: .top) {
            map.simultaneousGesture(TapGesture().onEnded({ _ in
                if viewModel.isSelected { viewModel.dispatch(.reset) }
            })).onMapCameraChange { context in
                viewModel.region = context.region
                viewModel.dispatch(.updateVisiblePoints)
                viewModel.calculateClusters()
            }
            
            zoomButtons
            
            header
                .padding(.horizontal, 16)
        }
        .sheet(isPresented: $isRewindsListPresented) {
            RewindsList(
                allRewinds: viewModel.points,
                visibleRewinds: viewModel.visiblePoints,
                group: "Friends"
            ) {
                isRewindsListPresented = false
                viewModel.dispatch(.select($0))
            }
            .presentationCornerRadius(30)
            .presentationDragIndicator(.visible)
            .presentationDetents([.height(760), .height(500)])
        }
        .onAppear {
            viewModel.dispatch(.fetchRewinds)
            if let center = viewModel.centerCoordinate() {
                viewModel.region = MKCoordinateRegion(
                    center: center,
                    span: .init(latitudeDelta: 0.5, longitudeDelta: 0.5)
                )
                viewModel.dispatch(.updateCamera)
            }
            viewModel.dispatch(.updateVisiblePoints)
            viewModel.calculateClusters()
        }
    }
    
    private var map: some View {
        Map(position: $viewModel.cameraPosition) {
            ForEach(viewModel.clusters) { cluster in
                Annotation("", coordinate: cluster.coordinate) {
                    ClusterView(cluster: cluster, isSelected: viewModel.isSelected(for: cluster)) {
                        if let first = cluster.points.first {
                            viewModel.dispatch(.select(first.id))
                        }
                    }
                }
            }
        }
    }
    
    private var header: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .border(ViewBorder(color: .textTertiaryLight, width: 1, cornerRadius: 20))
                .frame(maxWidth: .infinity, maxHeight: 70)
            
            HStack {
                makeButton("chevron.left") { router.pop() }
                Spacer()
                RoundedRectangle(cornerRadius: 15)
                    .frame(height: 54)
                    .border(ViewBorder(color: .textTertiary.opacity(0.4), width: 1, cornerRadius: 14))
                    .foregroundColor(.clear)
                    .overlay {
                        HeaderBadgeView(
                            image: UIComponentsAsset.media1.image,
                            imageSize: 44,
                            cornerRadius: 15,
                            text: "Friends",
                            fontSize: 18
                        )
                    }
                Spacer()
                makeButton("list.bullet") {
                    isRewindsListPresented = true
                }
            }
            .padding(.horizontal, 9)
        }
    }
    
    private var zoomButtons: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Spacer()
                makeButton("plus") { viewModel.dispatch(.zoom(.in)) }
                makeButton("minus") { viewModel.dispatch(.zoom(.out)) }
                Spacer()
            }
            .padding(.trailing, 8)
        }
    }
    
    private func makeButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            RoundedRectangle(cornerRadius: 15)
                .fill(.ultraThinMaterial)
                .frame(width: 54, height: 54)
                .border(ViewBorder(color: .textTertiary.opacity(0.4), width: 1, cornerRadius: 14))
                .foregroundColor(.clear)
                .overlay {
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .black))
                        .tint(.primary)
                }
        }
    }
}
