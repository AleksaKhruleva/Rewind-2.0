import SwiftUI

public enum LoadableMediaState: Equatable {
    case empty
    case ready(UIImage)
    case failure
}
