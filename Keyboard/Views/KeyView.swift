
final class KeyView: UIView {
    private let key: KeyDefinition
    private let theme: Theme

    public var contentView: UIView!

    var isSwipeKey: Bool {
        if case let .input(_, alt) = key.type, alt != nil {
            return true
        }
        switch key.type {
        case .comma, .fullStop:
            return true
        default:
            return false
        }
    }

    private var label: UILabel! = UILabel()
    private var alternateLabel: UILabel?

    private var fontSize: CGFloat = 0.0
    private var altFontSize: CGFloat = 0.0
    private let screenInches = UIDevice.current.dc.screenSize.sizeInches ?? Screen.maxSupportedInches

    var swipeLayoutConstraint: NSLayoutConstraint?

    var imageView: UIImageView?

    var active: Bool = false {
        didSet {
            if let contentView = self.contentView {
                let activeColor = key.type.isSpecialKeyStyle
                    ? theme.regularKeyColor
                    : theme.specialKeyColor
                let regularColor = key.type.isSpecialKeyStyle
                    ? theme.specialKeyColor
                    : theme.regularKeyColor

                contentView.backgroundColor = active
                    ? activeColor
                    : regularColor
            }

            if !active {
                percentageAlternative = 0.0
            }
        }
    }

    var percentageAlternative: CGFloat = 0.0 {
        didSet {
            let minValue = theme.altLabelTopAnchorConstant
            let maxValue = frame.height / 6.5

            swipeLayoutConstraint?.constant = minValue + (maxValue * percentageAlternative)

            if isSwipeKey {
                let fontSizeDelta = fontSize - theme.modifierKeyFontSize

                if let alternateLabel = alternateLabel {
                    alternateLabel.textColor = UIColor.interpolate(from: theme.altKeyTextColor,
                                                                   to: theme.textColor, with: percentageAlternative)
                    alternateLabel.font = alternateLabel.font.withSize(altFontSize + fontSizeDelta * percentageAlternative)
                }

                label.textColor = UIColor.interpolate(from: theme.textColor, to: UIColor.clear, with: percentageAlternative)
                label.font = label.font.withSize(fontSize - fontSizeDelta * percentageAlternative)
            }
        }
    }

    private func configureKeyLabel(_ label: UILabel, page: KeyboardPage, text: String) {
        label.textColor = theme.textColor
        label.numberOfLines = 0
        label.minimumScaleFactor = 0.1
        label.textAlignment = .center
        label.backgroundColor = .clear
        label.clipsToBounds = false
        label.translatesAutoresizingMaskIntoConstraints = false
        label.lineBreakMode = .byWordWrapping
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentHuggingPriority(.defaultLow, for: .vertical)
        label.adjustsFontSizeToFitWidth = false
        label.text = text

        if case .input = key.type {
            switch page {
            case .shifted, .capslock, .symbols1, .symbols2:
                label.font = theme.capitalKeyFont
            default:
                label.font = theme.lowerKeyFont
            }
        } else {
            // ABC key and friends will not shrink properly
            if text.count > 6 {
                label.numberOfLines = 2
            } else {
                label.numberOfLines = 1
            }
            label.lineBreakMode = .byTruncatingTail
            label.font = theme.capitalKeyFont.withSize(theme.modifierKeyFontSize)
            label.adjustsFontSizeToFitWidth = true
            label.sizeToFit()
        }

        fontSize = label.font.pointSize
    }

    private func configureAltKeyLabel(_ alternateLabel: UILabel, page: KeyboardPage) {
        alternateLabel.textColor = theme.inactiveTextColor
        alternateLabel.adjustsFontSizeToFitWidth = false
        alternateLabel.numberOfLines = 0
        alternateLabel.textAlignment = .center
        alternateLabel.backgroundColor = .clear
        alternateLabel.clipsToBounds = false
        alternateLabel.translatesAutoresizingMaskIntoConstraints = false
        alternateLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        alternateLabel.setContentHuggingPriority(.defaultLow, for: .vertical)

        if self.isLogicallyIPad && (UIDevice.current.dc.screenSize.sizeInches ?? 0.0) > 12 {
            switch page {
            case .shifted, .capslock, .symbols1, .symbols2:
                alternateLabel.font = theme.capitalKeyFont
            default:
                alternateLabel.font = theme.lowerKeyFont
            }
        } else {
            alternateLabel.font = theme.altKeyFont
        }

        altFontSize = alternateLabel.font.pointSize
    }

    private func input(string: String, alt: String?, page: KeyboardPage) {
        let labelContainer = UIView(frame: .zero)
        labelContainer.translatesAutoresizingMaskIntoConstraints = false
        labelContainer.backgroundColor = .clear
        labelContainer.clipsToBounds = false

        configureKeyLabel(label, page: page, text: string)

        if let alternateString = alt {
            self.alternateLabel = UILabel(frame: .zero)
            configureAltKeyLabel(self.alternateLabel!, page: page)
            alternateLabel!.text = alternateString

            labelContainer.addSubview(alternateLabel!)
        }

        labelContainer.addSubview(label)
        addSubview(labelContainer)

        label.centerXAnchor.constraint(equalTo: labelContainer.centerXAnchor).enable()
        label.widthAnchor.constraint(equalTo: labelContainer.widthAnchor).enable()

        let yConstant: CGFloat
        if case .normal = page, case KeyType.input(_, _) = self.key.type {
            yConstant = -2.0
        } else {
            yConstant = 0.0
        }

        if let alternateLabel = self.alternateLabel {
            swipeLayoutConstraint = alternateLabel.topAnchor
                .constraint(equalTo: labelContainer.topAnchor, constant: theme.altLabelTopAnchorConstant)
                .enable()

            label.bottomAnchor.constraint(equalTo: labelContainer.bottomAnchor,
                                          constant: theme.altLabelBottomAnchorConstant).enable()

            alternateLabel.centerXAnchor.constraint(equalTo: labelContainer.centerXAnchor).enable()
            alternateLabel.widthAnchor.constraint(equalTo: labelContainer.widthAnchor, multiplier: 1.0, constant: -4.0).enable()
        } else {
            label.centerYAnchor.constraint(equalTo: labelContainer.centerYAnchor, constant: yConstant).enable()
            swipeLayoutConstraint = nil
        }

        contentView = labelContainer
    }

    private func text(_ string: String, page: KeyboardPage) {
        let labelContainer = UIView(frame: .zero)
        labelContainer.translatesAutoresizingMaskIntoConstraints = false
        labelContainer.backgroundColor = .clear
        labelContainer.clipsToBounds = false

        configureKeyLabel(label, page: page, text: string)

        labelContainer.addSubview(label)
        addSubview(labelContainer)

        let yConstant: CGFloat
        if case .normal = page, case KeyType.input(_, _) = self.key.type {
            yConstant = -2.0
        } else {
            yConstant = 0.0
        }

        label.centerXAnchor.constraint(equalTo: labelContainer.centerXAnchor).enable()
        label.centerYAnchor.constraint(equalTo: labelContainer.centerYAnchor, constant: yConstant).enable()
        label.widthAnchor.constraint(equalTo: labelContainer.widthAnchor, multiplier: 1.0, constant: -4.0).enable()

        swipeLayoutConstraint = nil

        contentView = labelContainer
    }

    // Load image as SF Symbol and fallback to assets
    private func loadImage(named name: String, traits: UITraitCollection) -> UIImage? {
        // Map asset names to SF Symbol names with appropriate sizing
        let sfSymbolInfo: (name: String, pointSize: CGFloat)? = {
            switch name {
            case "backspace": return ("delete.backward", 20.0)
            case "globe": return ("globe", 20.0)
            case "return": return ("return", 20.0)
            case "shift": return ("shift", 20.0)
            case "shift-filled": return ("shift.fill", 20.0)
            case "close-keyboard-ipad": return ("keyboard.chevron.compact.down", 17.0)
            default: return nil
            }
        }()

        // Try SF Symbols first (iOS 13+)
        if #available(iOS 13.0, *),
           let symbolInfo = sfSymbolInfo,
           traits.userInterfaceIdiom == .phone { // TODO: remove this when supporting iPad
            let config = UIImage.SymbolConfiguration(pointSize: symbolInfo.pointSize, weight: .regular, scale: .medium)
            if let symbolImage = UIImage(systemName: symbolInfo.name, withConfiguration: config) {
                return symbolImage
            }
        }

        // Fallback to asset catalog
        var image = UIImage(named: name, in: Bundle.top, compatibleWith: traits)
        if image == nil {
            // If we get here, we're probably being run as an iPhone app on the iPad.
            // In this scenario for whatever reason we must use an image asset file that contains only one universal image
            image = UIImage(named: name + "-fallback", in: Bundle.top, compatibleWith: traits)
        }

        return image
    }

    private func image(named name: String, traits: UITraitCollection, tintColor: UIColor) {
        let image = loadImage(named: name, traits: traits)

        // Create a container view to control sizing
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        imageView = UIImageView()
        if let imageView = self.imageView {
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.image = image
            imageView.contentMode = .center
            imageView.tintColor = tintColor

            // Prevent image from affecting layout size
            imageView.setContentHuggingPriority(.defaultLow, for: .vertical)
            imageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
            imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
            imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

            container.addSubview(imageView)

            // Center imageView in container without affecting container size
            imageView.centerXAnchor.constraint(equalTo: container.centerXAnchor).isActive = true
            imageView.centerYAnchor.constraint(equalTo: container.centerYAnchor).isActive = true

            addSubview(container)

            contentView = container
        }
    }

    private func image(named name: String, traits: UITraitCollection) {
        image(named: name, traits: traits, tintColor: theme.textColor)
    }

    init(page: KeyboardPage, key: KeyDefinition, theme: Theme, traits: UITraitCollection) {
        self.key = key
        self.theme = theme

        super.init(frame: .zero)

        // HACK: UIColor.clear or alpha value below 0.001 here breaks indexPathForItemAtPoint:
        backgroundColor = UIColor(white: 0.001, alpha: 0.001)

        setupContentView(key, page, traits, theme)

        layer.shadowColor = theme.keyShadowColor.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowOpacity = 1.0
        layer.shadowRadius = 0.0

        contentView.fill(superview: self, margins: UIEdgeInsets(
            top: theme.keyVerticalMargin,
            left: theme.keyHorizontalMargin,
            bottom: theme.keyVerticalMargin,
            right: theme.keyHorizontalMargin))

        contentView.clipsToBounds = false
        contentView.backgroundColor = backgroundColor(for: key, page: page)
    }

    private func setupContentView(_ key: KeyDefinition, _ page: KeyboardPage, _ traits: UITraitCollection, _ theme: Theme) {
        switch key.type {
        case let .input(string, alt):
            input(string: string, alt: alt, page: page)
        case let .spacebar(string):
            text(string, page: page)
        case let .returnkey(string):
            setupReturnKey(page, traits, string)
        case .symbols:
            setupSymbols(page, traits)
        case .keyboardMode:
            image(named: "close-keyboard-ipad", traits: traits)
        case .backspace:
            image(named: "backspace", traits: traits)
        case .keyboard:
            image(named: "globe", traits: traits)
        case .shift:
            setupShift(page, traits, theme)
        case .shiftSymbols:
            setupShiftSymbols(page, traits)
        case .spacer, .normalKeyboard, .splitKeyboard, .sideKeyboardLeft, .sideKeyboardRight:
            // TODO: why is an empty image view being added here?
            imageView = UIImageView()
            if let imageView = self.imageView {
                self.imageView?.translatesAutoresizingMaskIntoConstraints = false

                addSubview(imageView)

                contentView = imageView
            }
        case .comma:
            setupComma(traits, page)
        case .fullStop:
            setupFullStop(traits, page)
        case .caps:
            image(named: "caps", traits: traits)
        case .tab:
            image(named: "tab", traits: traits)
        }
    }

    private func setupReturnKey(_ page: KeyboardPage, _ traits: UITraitCollection, _ string: String) {
        if iOSVersion.isIOS26OrNewer {
            image(named: "return", traits: traits)
        } else {
            if traits.userInterfaceIdiom == .pad, screenInches >= 11 {
                text(string, page: page)
            } else {
                image(named: "return", traits: traits)
            }
        }
            
    }
    private func setupSymbols(_ page: KeyboardPage, _ traits: UITraitCollection) {
        if case .symbols1 = page {
            text("ABC", page: page)
        } else if case .symbols2 = page {
            text("ABC", page: page)
        } else {
            if traits.userInterfaceIdiom == .pad && UIDevice.current.dc.deviceFamily == .iPad {
                text(".?123", page: page)
            } else {
                text("123", page: page)
            }
        }
    }

    private func setupShiftSymbols(_ page: KeyboardPage, _ traits: UITraitCollection) {
        if case .symbols1 = page {
            text("#+=", page: page)
        } else if case .symbols2 = page {
            text("123", page: page)
        } else {
            image(named: "shift", traits: traits)
        }
    }

    private func setupShift(_ page: KeyboardPage, _ traits: UITraitCollection, _ theme: Theme) {
        switch page {
        case .shifted, .capslock:
            image(named: "shift-filled", traits: traits, tintColor: theme.shiftTintColor)
        default:
            image(named: "shift", traits: traits)
        }
    }

    private func setupComma(_ traits: UITraitCollection, _ page: KeyboardPage) {
        if UIDevice.current.dc.isIpad && traits.userInterfaceIdiom == .pad {
            if (UIDevice.current.dc.screenSize.sizeInches ?? 0) < 12.0 {
                input(string: ",", alt: "!", page: page)
            } else {
                input(string: ",", alt: ";", page: page)
            }
        } else {
            input(string: ",", alt: nil, page: page)
        }
    }

    private func setupFullStop(_ traits: UITraitCollection, _ page: KeyboardPage) {
        if UIDevice.current.dc.isIpad && traits.userInterfaceIdiom == .pad {
            if (UIDevice.current.dc.screenSize.sizeInches ?? 0) < 12.0 {
                input(string: ".", alt: "?", page: page)
            } else {
                input(string: ".", alt: ":", page: page)
            }
        } else {
            input(string: ".", alt: nil, page: page)
        }
    }

    private func backgroundColor(for key: KeyDefinition, page: KeyboardPage) -> UIColor {
        if key.type == .shift,
            (page == .shifted || page == .capslock) {
            return theme.shiftActiveColor
        }

        return key.type.isSpecialKeyStyle
            ? theme.specialKeyColor
            : theme.regularKeyColor
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        updateSubviews()
    }

    func updateSubviews() {
        let percentageAlternative = self.percentageAlternative
        self.percentageAlternative = percentageAlternative

        if let subview = contentView {
            subview.layer.borderWidth = 1.0
            subview.layer.borderColor = (key.type.isSpecialKeyStyle ? theme.specialKeyBorderColor : theme.borderColor).cgColor
            subview.layer.cornerRadius = theme.keyCornerRadius
            subview.clipsToBounds = true
        }
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
