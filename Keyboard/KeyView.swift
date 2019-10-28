
class KeyView: UIView {
    private var key: KeyDefinition

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

    var swipeLayoutConstraint: NSLayoutConstraint?

    var imageView: UIImageView?

    var active: Bool = false {
        didSet {
            if let contentView = self.contentView {
                let activeColor = key.type.isSpecialKeyStyle
                    ? KeyboardView.theme.regularKeyColor
                    : KeyboardView.theme.specialKeyColor
                let regularColor = key.type.isSpecialKeyStyle
                    ? KeyboardView.theme.specialKeyColor
                    : KeyboardView.theme.regularKeyColor

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
            let minValue = frame.height / 3.0
            let maxValue = (frame.height / 3.0) * 2.0

            swipeLayoutConstraint?.constant = minValue + (maxValue - minValue) * percentageAlternative

            if isSwipeKey {
                alternateLabel?.textColor = UIColor.interpolate(from: KeyboardView.theme.inactiveTextColor, to: KeyboardView.theme.textColor, with: percentageAlternative)
                label.textColor = UIColor.interpolate(from: KeyboardView.theme.textColor, to: UIColor.clear, with: percentageAlternative)

                let fontSizeDelta = KeyboardView.theme.keyFont.pointSize - KeyboardView.theme.modifierKeyFontSize
                alternateLabel?.font = KeyboardView.theme.altKeyFont.withSize(KeyboardView.theme.altKeyFontSize + fontSizeDelta * percentageAlternative)
                label.font = KeyboardView.theme.keyFont.withSize(KeyboardView.theme.keyFont.pointSize - fontSizeDelta * percentageAlternative)
            }
        }
    }

    private var contentView: UIView!
    
    private func configureKeyLabel(_ label: UILabel, page: KeyboardPage) {
        label.textColor = KeyboardView.theme.textColor
        if case .input = key.type {
            switch page {
            case .shifted, .capslock, .symbols1, .symbols2:
                label.font = KeyboardView.theme.capitalKeyFont
            default:
                label.font = KeyboardView.theme.lowerKeyFont
            }
            label.adjustsFontSizeToFitWidth = false
        } else {
            label.font = KeyboardView.theme.keyFont.withSize(KeyboardView.theme.modifierKeyFontSize)
            label.adjustsFontSizeToFitWidth = true
        }
        label.numberOfLines = 0
        label.minimumScaleFactor = 0.4
        label.textAlignment = .center
        label.backgroundColor = .clear
        label.clipsToBounds = false
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentHuggingPriority(.defaultLow, for: .vertical)
    }
    
    private func configureAltKeyLabel(_ alternateLabel: UILabel, page: KeyboardPage) {
        alternateLabel.textColor = KeyboardView.theme.inactiveTextColor
        
        alternateLabel.adjustsFontSizeToFitWidth = false
        alternateLabel.numberOfLines = 0
        alternateLabel.textAlignment = .center
        alternateLabel.backgroundColor = .clear
        alternateLabel.clipsToBounds = false
        alternateLabel.translatesAutoresizingMaskIntoConstraints = false
        alternateLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        alternateLabel.setContentHuggingPriority(.defaultLow, for: .vertical)
        alternateLabel.font = KeyboardView.theme.altKeyFont
    }
    
    private func input(string: String, alt: String?, page: KeyboardPage) {
        let labelHoldingView = UIView(frame: .zero)
        labelHoldingView.translatesAutoresizingMaskIntoConstraints = false
        labelHoldingView.backgroundColor = .clear
        labelHoldingView.clipsToBounds = false

        configureKeyLabel(label, page: page)
        label.text = string

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
            swipeLayoutConstraint = label.topAnchor.constraint(equalTo: labelHoldingView.topAnchor, constant: 24)
            swipeLayoutConstraint?.isActive = true

            label.bottomAnchor.constraint(equalTo: labelHoldingView.bottomAnchor, constant: yConstant).isActive = true
            
            alternateLabel.centerXAnchor.constraint(equalTo: labelHoldingView.centerXAnchor).isActive = true
            alternateLabel.widthAnchor.constraint(lessThanOrEqualTo: labelHoldingView.widthAnchor).isActive = true
            alternateLabel.topAnchor.constraint(equalTo: labelHoldingView.topAnchor, constant: 8).isActive = true
            alternateLabel.bottomAnchor.constraint(equalTo: label.topAnchor).isActive = true
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

        configureKeyLabel(label, page: page)
        label.text = string

        labelHoldingView.addSubview(label)
        addSubview(labelHoldingView)

        let yConstant: CGFloat
        if case .normal = page, case KeyType.input(_) = self.key.type {
            yConstant = -2.0
        } else {
            yConstant = 0.0
        }
        label.centerXAnchor.constraint(equalTo: labelHoldingView.centerXAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: labelHoldingView.centerYAnchor, constant: yConstant).isActive = true
        label.widthAnchor.constraint(equalTo: labelHoldingView.widthAnchor).isActive = true
        swipeLayoutConstraint = nil

        contentView = labelHoldingView
    }

    private func image(_ image: UIImage) {
        imageView = UIImageView()
        if let imageView = self.imageView {
            self.imageView?.translatesAutoresizingMaskIntoConstraints = false

            imageView.image = image
            imageView.contentMode = .center
            imageView.tintColor = KeyboardView.theme.textColor

            addSubview(imageView)

            contentView = imageView
        }
    }
    
    init(page: KeyboardPage, key: KeyDefinition) {
        self.key = key
        
        super.init(frame: .zero)

        // HACK: UIColor.clear here breaks indexPathForItemAtPoint:
        backgroundColor = UIColor.black.withAlphaComponent(0.0001)
        
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
                if UIDevice.current.dc.deviceFamily == .iPad {
                    text(".?123", page: page)
                } else {
                    text("123", page: page)
                }
            }
        case .keyboardMode:
            image(UIImage(named: "close-keyboard-ipad")!)
        case .backspace:
            image(UIImage(named: "backspace")!)
        case .keyboard:
            image(UIImage(named: "globe")!)
        case .shift:
            image(UIImage(named: "shift")!)
        case .shiftSymbols:
            if case .symbols1 = page {
                text("#+=", page: page)
            } else if case .symbols2 = page {
                text("123", page: page)
            } else {
                image(UIImage(named: "shift")!)
            }
        case .spacer, .splitKeyboard, .sideKeyboardLeft, .sideKeyboardRight:
            imageView = UIImageView()
            if let imageView = self.imageView {
                self.imageView?.translatesAutoresizingMaskIntoConstraints = false

                addSubview(imageView)

                contentView = imageView
            }
        case .comma:
            input(string: ",", alt: ";", page: page)
        case .fullStop:
            input(string: ".", alt: ":", page: page)
        case .caps:
            image(UIImage(named: "caps")!)
        case .tab:
            text("tab", page: page)
        }

        layer.shadowColor = KeyboardView.theme.keyShadowColor.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowOpacity = 1.0
        layer.shadowRadius = 0.0
        
        contentView.fill(superview: self, margins: UIEdgeInsets(
            top: KeyboardView.theme.keyVerticalMargin + 2.0,
            left: KeyboardView.theme.keyHorizontalMargin,
            bottom: KeyboardView.theme.keyVerticalMargin - 2.0,
            right: KeyboardView.theme.keyHorizontalMargin))
        
        contentView.clipsToBounds = false

        contentView.backgroundColor = key.type.isSpecialKeyStyle
            ? KeyboardView.theme.specialKeyColor
            : KeyboardView.theme.regularKeyColor
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
            subview.layer.borderColor = (key.type.isSpecialKeyStyle ? KeyboardView.theme.specialKeyBorderColor : KeyboardView.theme.borderColor).cgColor
            subview.layer.cornerRadius = KeyboardView.theme.keyCornerRadius
            subview.clipsToBounds = true
        }
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
