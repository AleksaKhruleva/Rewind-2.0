public enum RewindElement {
    public enum Auth {
        public enum Input {
            case email
            case password
            case name
            case code(Int = -1)

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

    public enum Account {
        public enum Button {
            public enum EditImageDialogFlow: String {
                case set
                case delete
            }

            case editImage
            case editName
            case editPassword
            case editEmail

            case editImageDialog(EditImageDialogFlow)

            var rawValue: String {
                switch self {
                case .editImage: "editImage"
                case .editName: "editName"
                case .editPassword: "editPassword"
                case .editEmail: "editEmail"
                case let .editImageDialog(flow):
                    "editImageDialog.\(flow.rawValue)"
                }
            }
        }

        public enum EditFlow {
            public enum EditName: String {
                case name
            }

            public enum EditPassword {
                case code(Int = -1)
                case password

                var rawValue: String {
                    switch self {
                    case .password: "password"
                    case let .code(digit): "code.\(digit)"
                    }
                }
            }

            public enum EditEmail {
                case password
                case email
                case code(Int = -1)

                var rawValue: String {
                    switch self {
                    case .password: "password"
                    case .email: "email"
                    case let .code(digit): "code.\(digit)"
                    }
                }
            }

            case name(EditName)
            case password(EditPassword)
            case email(EditEmail)

            var rawValue: String {
                switch self {
                case let .name(editName):
                    "editName.\(editName.rawValue)"
                case let .password(editPassword):
                    "editPassword.\(editPassword.rawValue)"
                case let .email(editEmail):
                    "editEmail.\(editEmail.rawValue)"
                }
            }
        }

        case button(Button)
        case editFlow(EditFlow)

        var rawValue: String {
            switch self {
            case let .button(button):
                "button.\(button.rawValue)"
            case let .editFlow(editFlow):
                "editFlow.\(editFlow.rawValue)"
            }
        }
    }

    public enum Rewind {
        public enum Button: String {
            case account
        }

        case button(Button)

        var rawValue: String {
            switch self {
            case let .button(button):
                "button.\(button.rawValue)"
            }
        }
    }

    case auth(Auth)
    case account(Account)
    case rewind(Rewind)

    public var accessibilityID: String {
        switch self {
        case let .auth(element):
            "auth.\(element.rawValue)"
        case let .account(element):
            "account.\(element.rawValue)"
        case let .rewind(element):
            "rewind.\(element.rawValue)"
        }
    }
}
