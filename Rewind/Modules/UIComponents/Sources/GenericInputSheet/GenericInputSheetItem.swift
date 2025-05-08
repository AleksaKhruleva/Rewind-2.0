public enum GenericInputSheetItem: String, Identifiable {
    public var id: String { rawValue }
    
    case name
    case password
    case email
    case tag
    case code
}
