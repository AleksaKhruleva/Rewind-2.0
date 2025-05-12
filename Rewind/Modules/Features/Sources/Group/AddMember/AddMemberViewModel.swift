import Base
import SwiftUI
import UIComponents

@MainActor
@Observable
final class AddMemberViewModel {
    
    enum Intent {
        case copyLink
        case shareLink
        case generateQR(color: Color, colorScheme: ColorScheme)
    }
    
    var showShareSheet = false
    var toastMessage: String?
    var qrCodeImage: UIImage?
    
    let link = "https://rewindapp.ru/swagger/index.html"
    let groupName = "Friends"
    
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
        guard let generatedQR = QRCodeGenerator.generate(from: link, pixelColor: color, colorScheme: colorScheme) else {
            toastMessage = UIComponentsStrings.Group.AddMember.QrCodeGeneration.failure
            return
        }
        
        qrCodeImage = generatedQR
    }
}
