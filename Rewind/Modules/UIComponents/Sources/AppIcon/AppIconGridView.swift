import SwiftUI

public struct AppIconsGridView: View {
    @StateObject private var viewModel = AppIconsViewModel()

    public init() {}
    
    public var body: some View {
        let columns = [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ]

        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(viewModel.appIcons) { icon in
                    AppIconView(viewModel: icon)
                        .onTapGesture {
                            viewModel.dispatch(.change(icon: icon))
                        }
                }
            }
            .padding(.top, 6)
            .padding(.bottom, 10)
        }
    }
}

#Preview {
    AppIconsGridView()
}
