import MapKit
import SwiftUI
import UIComponents

struct ClusterView: View {
    var cluster: ClusteredPoint
    @State private var isSelected: Bool = false
    var action: () -> Void

    public init(cluster: ClusteredPoint, isSelected: Bool, action: @escaping () -> Void) {
        self.cluster = cluster
        self.action = action
    }

    @State private var animate = false
    @State private var currentColor: Color = .red
    @State private var badgeWidth: CGFloat = .zero

    private let colors: [Color] = Array(repeating: .random, count: 15)

    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .bottomLeading) {
                if let imageURL = cluster.points.first?.memory.mediaURL {
                    SquareAsyncMedia(url: imageURL, type: .image, cornerRadius: 22)
                        .frame(68 * (isSelected ? 1.7 : 1))
                        .border(ViewBorder(color: .backgroundSecondary, width: 2, cornerRadius: 22))
                        .glow(
                            condition: cluster.points.count > 1,
                            color: currentColor,
                            animate: animate
                        )
                }

                if cluster.points.count > 1 {
                    makeClusterMark(cluster.points.count)
                        .offset(x: -5, y: 5)
                }
            }
            .onTapGesture {
                action()
                withAnimation {
                    isSelected.toggle()
                }
            }

            if isSelected, let firstItem = cluster.points.first {
                makeSelectedBadge(
                    imageURL: firstItem.memory.userImage,
                    name: firstItem.memory.username,
                    date: firstItem.memory.createdAt.description
                )
            }
        }
        .onAppear {
            animate = true
            startColorCycle()
        }
    }

    private func makeClusterMark(_ count: Int) -> some View {
        Circle()
            .frame(30)
            .foregroundColor(.backgroundInverted)
            .overlay {
                Text("\(count)")
                    .modifier(RoundFontModifier(size: 15, foregroundColor: .textPrimaryInverted))
                    .padding(6)
            }
    }

    private func makeSelectedBadge(imageURL: URL?, name: String, date: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .frame(width: 200, height: 50)
                .border(ViewBorder(color: .textTertiaryLight, width: 2, cornerRadius: 22))

            AuthorBadgeView(
                imageURL: imageURL,
                name: name,
                date: date,
                track: nil
            )
            .frame(width: 200)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .modifier(MeasureWidthModifier(width: $badgeWidth))
        }
    }

    private func startColorCycle() {
        Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 2)) {
                currentColor = colors.randomElement() ?? .green
            }
        }
    }
}

extension View {
    @ViewBuilder
    fileprivate func glow(condition: Bool, color: Color, animate: Bool) -> some View {
        if condition {
            self
                .shadow(color: color, radius: animate ? 20 : 5)
                .scaleEffect(animate ? .random(in: 0.8...1) : 1.0)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animate)
        } else {
            self
        }
    }
}
