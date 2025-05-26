import SwiftUI

public enum LoadableMediaState: Equatable {
    case empty
    case ready(Image)
    case failure
}
