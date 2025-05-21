import Base
import SwiftUI
import UIComponents

@MainActor @Observable
final class AddMemberViewModel {
    enum Intent {
        case copyLink
        case shareLink
        case generateQR(color: Color, colorScheme: ColorScheme)
    }
    
    enum QRCodeImageState {
        case requested
        case ready(UIImage)
        case failed
    }
    
    var toastMessage: String?
    var showShareSheet = false
    let link = "https://rewindapp.ru/swagger/index.html"
    let groupName = "Friends"
    
    private(set) var qrCodeImageState: QRCodeImageState = .requested
    
    func dispatch(_ intent: Intent) {
        switch intent {
        case .copyLink:
            copyLink()
        case .shareLink:
            showShareSheet = true
        case .generateQR(color: let color, colorScheme: let colorScheme):
            generateQR(color: color, colorScheme: colorScheme)
        }
    }
    
    private func copyLink() {
        UIPasteboard.general.string = link
        toastMessage = UIComponentsStrings.Group.AddMember.linkCopied
    }
    
    private func generateQR(color: Color, colorScheme: ColorScheme) {
        qrCodeImageState = .requested
        
        guard let generatedQR = QRCodeGenerator.generate(from: link, pixelColor: color, colorScheme: colorScheme) else {
            toastMessage = UIComponentsStrings.Group.AddMember.QrCodeGeneration.failure
            qrCodeImageState = .failed
            return
        }
        
        withAnimation {
            qrCodeImageState = .ready(generatedQR)
        }
    }
}
