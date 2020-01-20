import UIDeviceComplete

class KeyView: UIView {
    private let key: KeyDefinition
    private let theme: ThemeType
    
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
                    alternateLabel.textColor = UIColor.interpolate(from: theme.altKeyTextColor, to: theme.textColor, with: percentageAlternative)
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
    
    private var isLogicallyIPad: Bool {
        return UIDevice.current.dc.deviceFamily == .iPad &&
            self.traitCollection.userInterfaceIdiom == .pad
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
        let labelHoldingView = UIView(frame: .zero)
        labelHoldingView.translatesAutoresizingMaskIntoConstraints = false
        labelHoldingView.backgroundColor = .clear
        labelHoldingView.clipsToBounds = false

        configureKeyLabel(label, page: page, text: string)

        if let alternateString = alt {
            self.alternateLabel = UILabel(frame: .zero)
            configureAltKeyLabel(self.alternateLabel!, page: page)
            alternateLabel!.text = alternateString
            
            labelHoldingView.addSubview(alternateLabel!)
        }

        labelHoldingView.addSubview(label)
        addSubview(labelHoldingView)
        
        label.centerXAnchor.constraint(equalTo: labelHoldingView.centerXAnchor).isActive = true
        label.widthAnchor.constraint(equalTo: labelHoldingView.widthAnchor).isActive = true
        
        let yConstant: CGFloat
        if case .normal = page, case KeyType.input(_) = self.key.type {
            yConstant = -2.0
        } else {
            yConstant = 0.0
        }
        
        if let alternateLabel = self.alternateLabel {
            swipeLayoutConstraint = alternateLabel.topAnchor
                .constraint(equalTo: labelHoldingView.topAnchor, constant: theme.altLabelTopAnchorConstant)
                .enable()
            
            label.bottomAnchor.constraint(equalTo: labelHoldingView.bottomAnchor, constant: theme.altLabelBottomAnchorConstant).enable()
            
            alternateLabel.centerXAnchor
                .constraint(equalTo: labelHoldingView.centerXAnchor)
                .enable()
            alternateLabel.widthAnchor
                .constraint(equalTo: labelHoldingView.widthAnchor, multiplier: 1.0, constant: -4.0)
                .enable()
        } else {
            label.centerYAnchor.constraint(equalTo: labelHoldingView.centerYAnchor, constant: yConstant).isActive = true
            swipeLayoutConstraint = nil
        }

        contentView = labelHoldingView
    }
    
    private func text(_ string: String, page: KeyboardPage) {
        let labelHoldingView = UIView(frame: .zero)
        labelHoldingView.translatesAutoresizingMaskIntoConstraints = false
        labelHoldingView.backgroundColor = .clear
        labelHoldingView.clipsToBounds = false

        configureKeyLabel(label, page: page, text: string)

        labelHoldingView.addSubview(label)
        addSubview(labelHoldingView)

        let yConstant: CGFloat
        if case .normal = page, case KeyType.input(_) = self.key.type {
            yConstant = -2.0
        } else {
            yConstant = 0.0
        }
        
        label.centerXAnchor
            .constraint(equalTo: labelHoldingView.centerXAnchor)
            .enable()
        label.centerYAnchor
            .constraint(equalTo: labelHoldingView.centerYAnchor, constant: yConstant)
            .enable()
        label.widthAnchor
            .constraint(equalTo: labelHoldingView.widthAnchor, multiplier: 1.0, constant: -4.0)
            .enable()
        
        swipeLayoutConstraint = nil

        contentView = labelHoldingView
    }

    private func image(named name: String, traits: UITraitCollection, tintColor: UIColor) {
        var image = UIImage(named: name, in: Bundle.top, compatibleWith: traits)
        if image == nil {
            // If we get here, we're probably being run as an iPhone app on the iPad.
            // In this scenario for whatever reason we must use an image asset file that contains only one universal image
            image = UIImage(named: name + "-fallback", in: Bundle.top, compatibleWith: traits)
        }
        
        imageView = UIImageView()
        if let imageView = self.imageView {
            self.imageView?.translatesAutoresizingMaskIntoConstraints = false

            imageView.image = image
            imageView.contentMode = .center
            imageView.tintColor = tintColor

            addSubview(imageView)

            contentView = imageView
        }
    }
    
    private func image(named name: String, traits: UITraitCollection) {
        image(named: name, traits: traits, tintColor: theme.textColor)
    }
    
    init(page: KeyboardPage, key: KeyDefinition, theme: ThemeType, traits: UITraitCollection) {
        self.key = key
        self.theme = theme
        
        super.init(frame: .zero)

        // HACK: UIColor.clear or alpha value below 0.001 here breaks indexPathForItemAtPoint:
        backgroundColor = UIColor(white: 0.001, alpha: 0.001)
        
        switch key.type {
        case let .input(string, alt):
            input(string: string, alt: alt, page: page)
        case let .spacebar(string):
            text(string, page: page)
        case let .returnkey(string):
            text(string, page: page)
        case .symbols:
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
        case .keyboardMode:
            image(named: "close-keyboard-ipad", traits: traits)
        case .backspace:
            image(named: "backspace", traits: traits)
        case .keyboard:
            image(named: "globe", traits: traits)
        case .shift:
            switch page {
            case .shifted, .capslock:
                image(named: "shift-filled", traits: traits, tintColor: theme.shiftTintColor)
            default:
                image(named: "shift", traits: traits)
            }
        case .shiftSymbols:
            if case .symbols1 = page {
                text("#+=", page: page)
            } else if case .symbols2 = page {
                text("123", page: page)
            } else {
                image(named: "shift", traits: traits)
            }
        case .spacer, .splitKeyboard, .sideKeyboardLeft, .sideKeyboardRight:
            imageView = UIImageView()
            if let imageView = self.imageView {
                self.imageView?.translatesAutoresizingMaskIntoConstraints = false

                addSubview(imageView)

                contentView = imageView
            }
        case .comma:
            if UIDevice.current.dc.isIpad && traits.userInterfaceIdiom == .pad {
                if (UIDevice.current.dc.screenSize.sizeInches ?? 0) < 12.0 {
                    input(string: ",", alt: "!", page: page)
                } else {
                    input(string: ",", alt: ";", page: page)
                }
            } else {
                input(string: ",", alt: nil, page: page)
            }
        case .fullStop:
            if UIDevice.current.dc.isIpad && traits.userInterfaceIdiom == .pad {
                if (UIDevice.current.dc.screenSize.sizeInches ?? 0) < 12.0 {
                    input(string: ".", alt: "?", page: page)
                } else {
                    input(string: ".", alt: ":", page: page)
                }
            } else {
                input(string: ".", alt: nil, page: page)
            }
        case .caps:
            image(named: "caps", traits: traits)
        case .tab:
            text("tab", page: page)
        }

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
    
    private func backgroundColor(for key: KeyDefinition, page:KeyboardPage) -> UIColor {
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
