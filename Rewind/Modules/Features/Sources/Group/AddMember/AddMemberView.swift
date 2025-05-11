import SwiftUI
import UIComponents

private let width = UIScreen.main.bounds.width / 1.5
private let color = Color.background

public struct AddMemberView: View {
    
    @State private var viewModel: AddMemberViewModel
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.showToast) private var showToast
    
    public init() {
        self.viewModel = AddMemberViewModel()
    }
    
    public var body: some View {
        ZStack {
            color
                .ignoresSafeArea()
            
            VStack(spacing: 12) {
                Spacer()
                
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
        }
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
        .onAppear {
            viewModel
                .dispatch(
                    .generateQR(
                        color: color,
                        colorScheme: colorScheme
                    )
                )
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
        if let image = viewModel.qrCodeImage {
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
                
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: width * 0.88, height: width * 0.88)
            }
        } else {
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
    AddMemberView()
}
