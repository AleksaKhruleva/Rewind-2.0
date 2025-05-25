public enum RewindElement {
    public enum Auth {
        public enum Input {
            case email
            case password
            case name
            case code(Int)

            var rawValue: String {
                switch self {
                case .email: "email"
                case .password: "password"
                case .name: "name"
                case let .code(digit): "code.\(digit)"
                }
            }
        }

        public enum Button: String {
            case signup
            case signin
        }

        case input(Input)
        case button(Button)

        var rawValue: String {
            switch self {
            case let .input(input):
                "input.\(input.rawValue)"
            case let .button(button):
                "button.\(button.rawValue)"
            }
        }
    }

    case auth(Auth)

    public var accessibilityID: String {
        switch self {
        case let .auth(element):
            "auth.\(element.rawValue)"
        }
    }
}
