
public enum AuthFlow: Hashable {
    case registration
    case login(email: String = "")
}
