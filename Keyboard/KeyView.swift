
class KeyView: UIView {
    private var key: KeyDefinition
    private var alternateKey: KeyDefinition?

    var isSwipeKey: Bool {
        if let alternateKey = self.alternateKey, let _ = self.alternateLabel, case .input = alternateKey.type {
            return true
        } else {
            return false
        }
    }

    var label: UILabel?
    var alternateLabel: UILabel?

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
                label?.textColor = UIColor.interpolate(from: KeyboardView.theme.textColor, to: UIColor.clear, with: percentageAlternative)

                let fontSizeDelta = KeyboardView.theme.keyFont.pointSize - KeyboardView.theme.alternateKeyFontSize
                alternateLabel?.font = KeyboardView.theme.keyFont.withSize(KeyboardView.theme.alternateKeyFontSize + fontSizeDelta * percentageAlternative)
                label?.font = KeyboardView.theme.keyFont.withSize(KeyboardView.theme.keyFont.pointSize - fontSizeDelta * percentageAlternative)
            }
        }
    }

    var contentView: UIView!
    
    private func text(_ string: String) {
        label = UILabel()
        if let _ = self.alternateKey {
            alternateLabel = UILabel(frame: .zero)
        }

        if let label = self.label {
            let labelHoldingView = UIView(frame: .zero)
            labelHoldingView.translatesAutoresizingMaskIntoConstraints = false
            labelHoldingView.backgroundColor = .clear

            label.textColor = KeyboardView.theme.textColor
            if case .input = key.type {
                label.font = KeyboardView.theme.keyFont
            } else {
                label.font = KeyboardView.theme.keyFont.withSize(KeyboardView.theme.alternateKeyFontSize)
            }
            label.text = string
            label.adjustsFontSizeToFitWidth = true
            label.numberOfLines = 0
            label.minimumScaleFactor = 0.4
            label.textAlignment = .center
            label.backgroundColor = .clear
            label.clipsToBounds = false
            label.translatesAutoresizingMaskIntoConstraints = false
            label.setContentHuggingPriority(.defaultLow, for: .horizontal)
            label.setContentHuggingPriority(.defaultLow, for: .vertical)

            if let alternateKey = self.alternateKey, let alternateLabel = self.alternateLabel, case let .input(alternateString) = alternateKey.type {
                alternateLabel.textColor = KeyboardView.theme.inactiveTextColor
                alternateLabel.font = KeyboardView.theme.keyFont
                alternateLabel.text = alternateString
                alternateLabel.adjustsFontSizeToFitWidth = true
                alternateLabel.textAlignment = .center
                alternateLabel.backgroundColor = .clear
                alternateLabel.clipsToBounds = false
                alternateLabel.translatesAutoresizingMaskIntoConstraints = false
                alternateLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
                alternateLabel.setContentHuggingPriority(.defaultLow, for: .vertical)

                labelHoldingView.addSubview(alternateLabel)
            }

            labelHoldingView.addSubview(label)
            addSubview(labelHoldingView)
            label.centerXAnchor.constraint(equalTo: labelHoldingView.centerXAnchor).isActive = true
            label.widthAnchor.constraint(equalTo: label.heightAnchor).isActive = true

            if let alternateKey = self.alternateKey, let alternateLabel = self.alternateLabel, case .input = alternateKey.type {
                swipeLayoutConstraint = label.topAnchor.constraint(equalTo: labelHoldingView.topAnchor, constant: 24)
                swipeLayoutConstraint?.isActive = true

                label.bottomAnchor.constraint(equalTo: labelHoldingView.bottomAnchor, constant: 0).isActive = true
                alternateLabel.centerXAnchor.constraint(equalTo: labelHoldingView.centerXAnchor).isActive = true
                alternateLabel.widthAnchor.constraint(equalTo: alternateLabel.heightAnchor).isActive = true
                alternateLabel.topAnchor.constraint(equalTo: labelHoldingView.topAnchor, constant: 8).isActive = true
                alternateLabel.bottomAnchor.constraint(equalTo: label.topAnchor).isActive = true
            } else if let alternateKey = self.alternateKey, case .spacer = alternateKey.type {
                swipeLayoutConstraint = label.topAnchor.constraint(equalTo: labelHoldingView.topAnchor, constant: 24)
                swipeLayoutConstraint?.isActive = true

                label.bottomAnchor.constraint(equalTo: labelHoldingView.bottomAnchor, constant: 0).isActive = true
            } else {
                label.centerYAnchor.constraint(equalTo: labelHoldingView.centerYAnchor, constant: 0).isActive = true
                label.widthAnchor.constraint(lessThanOrEqualTo: labelHoldingView.widthAnchor, multiplier: 1.0).isActive = true
                swipeLayoutConstraint = nil
            }

            contentView = labelHoldingView
        }
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
    
    init(key: KeyDefinition, alternateKey: KeyDefinition? = nil) {
        self.key = key
        self.alternateKey = alternateKey
        super.init(frame: .zero)

        // HACK: UIColor.clear here breaks indexPathForItemAtPoint:
        backgroundColor = UIColor.black.withAlphaComponent(0.0001)

        // If the alternate key is not an input key, ignore it
        if let alternateKey = self.alternateKey, case .input = alternateKey.type, case .input = key.type {
            // Continue
        } else if let alternateKey = self.alternateKey, case .spacer = alternateKey.type, case .input = key.type {
            // Continue
        } else {
            self.alternateKey = nil
        }
        
        let isiPad = UIDevice.current.kind == .iPad

        switch key.type {
        case let KeyType.input(string), let KeyType.spacebar(string), let KeyType.returnkey(string):
            text(string)
        case KeyType.symbols:
            if UIDevice.current.kind == .iPad {
                text(".?123")
            } else {
                text("123")
            }
        case .keyboardMode:
            image(UIImage(named: "close-keyboard-ipad")!)
        case .backspace:
            image(UIImage(named: "backspace")!)
        case .keyboard:
            image(UIImage(named: "globe")!)
        case .shift:
            image(UIImage(named: "shift")!)
        default:
            imageView = UIImageView()
            if let imageView = self.imageView {
                self.imageView?.translatesAutoresizingMaskIntoConstraints = false

                addSubview(imageView)

                contentView = imageView
            }
        }

        layer.shadowColor = KeyboardView.theme.keyShadowColor.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowOpacity = 1.0
        layer.shadowRadius = 0.0

        contentView.fillSuperview(self, margins: UIEdgeInsets(
            top: KeyboardView.theme.keyVerticalMargin,
            left: KeyboardView.theme.keyHorizontalMargin,
            bottom: KeyboardView.theme.keyVerticalMargin,
            right: KeyboardView.theme.keyHorizontalMargin))

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
