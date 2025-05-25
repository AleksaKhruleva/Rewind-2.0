public enum AuthFlow: Hashable {
    case registration(email: String = "")
    case login(email: String = "")
}
