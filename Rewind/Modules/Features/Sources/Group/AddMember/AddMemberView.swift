import SwiftUI
import UIComponents

private let width = UIScreen.main.bounds.width / 1.5
private let color = Color.background

public struct AddMemberView: View {
    @State private var viewModel: AddMemberViewModel
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.showToast) private var showToast
    
    private weak var router: AppRouter?
    
    public init(router: AppRouter) {
        self.router = router
        viewModel = AddMemberViewModel()
    }
    
    public var body: some View {
        VStack {
            header
            
            VStack(spacing: 12) {
                title
                
                qrCode
                
                HStack(spacing: 12) {
                    makeButton(title: UIComponentsStrings.Group.AddMember.copyLink) {
                        viewModel.dispatch(.copyLink)
                    }
                    
                    makeButton(title: UIComponentsStrings.Group.AddMember.shareLink) {
                        viewModel.dispatch(.shareLink)
                    }
                }
                
                Spacer()
            }
            .modifier(VStackTopOffsetModifier(topOffsetRatio: 0.15))
        }
        .background(Color.background)
        .sheet(isPresented: $viewModel.showShareSheet) {
            ActivityView(
                activityItems: [viewModel.link],
                isPresented: $viewModel.showShareSheet
            )
            .presentationDetents([.medium])
        }
        .onChange(of: viewModel.toastMessage) { _, newValue in
            guard let newValue else {
                return
            }
            showToast(newValue)
            viewModel.toastMessage = nil
        }
        .task {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                viewModel.dispatch(
                    .generateQR(
                        color: color,
                        colorScheme: colorScheme
                    )
                )
            }
        }
        .onChange(of: colorScheme) { _, newValue in
            viewModel
                .dispatch(
                    .generateQR(
                        color: color,
                        colorScheme: newValue
                    )
                )
        }
    }
    
    private var header: some View {
        RewindHeader(backgroundColor: .clear, rightView: {
            RewindButton(type: .rightChevron) {
                router?.pop()
            }
        })
    }
    
    private var title: some View {
        Text(UIComponentsStrings.Group.AddMember.join(viewModel.groupName))
            .modifier(
                RoundFontModifier(
                    size: 20,
                    foregroundColor: .textPrimary
                )
            )
    }
    
    @ViewBuilder
    private var qrCode: some View {
        switch viewModel.qrCodeImageState {
        case .requested:
            ProgressView()
                .frame(width: width, height: width)
        case let .ready(qrCodeImage):
            withAnimation {
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "FF3299"),
                                    Color(hex: "FF65B5"),
                                    Color(hex: "FF8FC7"),
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: width, height: width)
                    
                    Image(uiImage: qrCodeImage)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(width: width * 0.88, height: width * 0.88)
                }
            }
        case .failed:
            EmptyView()
        }
    }
    
    private func makeButton(title: String, onTap: @escaping () -> Void) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.backgroundSecondary)
            
            Button {
                onTap()
            } label: {
                Text(title)
                    .modifier(RoundFontModifier(size: 15))
            }
        }
        .frame(width: width / 2 - 6, height: 56)
    }
}

#Preview {
    AddMemberView(router: AppRouter())
}
