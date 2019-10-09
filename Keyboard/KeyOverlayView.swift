import UIKit

class KeyOverlayView: UIView {
    class KeyOverlayShadowView: UIView {}

    let originView: UIView
    let key: KeyDefinition

    let contentView: UIView
    private var shadowView: KeyOverlayShadowView?

    var path: CGPath!

    init(origin: UIView, key: KeyDefinition) {
        originView = origin
        self.key = key
        contentView = UIView(frame: origin.bounds)
        super.init(frame: CGRect(x: 0, y: 0, width: origin.frame.width, height: origin.frame.height * 2))
        backgroundColor = .clear
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        contentView.topAnchor.constraint(equalTo: topAnchor, constant: KeyboardView.theme.popupCornerRadius).isActive = true
        contentView.leftAnchor.constraint(equalTo: leftAnchor, constant: KeyboardView.theme.popupCornerRadius).isActive = true
        contentView.rightAnchor.constraint(equalTo: rightAnchor, constant: -KeyboardView.theme.popupCornerRadius).isActive = true
        let bottomConstraint = contentView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -(origin.frame.height - KeyboardView.theme.keyHorizontalMargin * 2) - KeyboardView.theme.popupCornerRadius)
        bottomConstraint.priority = .defaultLow
        bottomConstraint.isActive = true
        let bottomConstraint2 = bottomAnchor.constraint(greaterThanOrEqualTo: contentView.bottomAnchor, constant: -KeyboardView.theme.popupCornerRadius)
        bottomConstraint2.priority = .required
        bottomConstraint2.isActive = true

        let heightConstraint = contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: origin.frame.height - KeyboardView.theme.popupCornerRadius * 2)
        heightConstraint.priority = .defaultLow
        heightConstraint.isActive = true
        contentView.backgroundColor = .clear
        isUserInteractionEnabled = false
    }

    func addShadow() {
        guard self.shadowView == nil else { return }
        guard let superview = self.superview else { return }

        let shadowView = KeyOverlayShadowView()
        self.shadowView = shadowView
        shadowView.translatesAutoresizingMaskIntoConstraints = false
        shadowView.backgroundColor = UIColor.black.withAlphaComponent(0.001)
        superview.insertSubview(shadowView, belowSubview: self)
        shadowView.fillSuperview(contentView)
        shadowView.layer.shadowColor = UIColor(white: 0.0, alpha: 1.0).cgColor
        shadowView.layer.shadowOffset = .zero
        shadowView.layer.shadowOpacity = 1.0
        shadowView.layer.shadowRadius = 12.0
        shadowView.clipsToBounds = false
    }

    override func didMoveToSuperview() {
        shadowView?.removeFromSuperview()
        shadowView = nil

        addShadow()
        super.didMoveToSuperview()
    }

    override func removeFromSuperview() {
        shadowView?.removeFromSuperview()
        super.removeFromSuperview()
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_: CGRect) {
        guard let _ = self.superview else { return }

        path = createPath()

        let bezier = UIBezierPath(cgPath: path)

        KeyboardView.theme.popupColor.setFill()
        bezier.fill()
        KeyboardView.theme.borderColor.setStroke()
        bezier.stroke()

        let mask = CAShapeLayer()
        mask.path = path
        layer.mask = mask
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        setNeedsDisplay()
    }

    fileprivate struct PopupPathPoint {
        let radius: CGFloat
        let point: CGPoint
    }

    func createPath() -> CGPath {
        let superview = self.superview!
        let originFrameInSuperview = originView.convert(originView.frame, to: superview)
        let originFrameInLocalBounds = superview.convert(originFrameInSuperview, to: self).insetBy(dx: KeyboardView.theme.keyHorizontalMargin, dy: KeyboardView.theme.keyVerticalMargin)

        var points: [PopupPathPoint]

        if originFrameInLocalBounds.maxY < bounds.maxY - KeyboardView.theme.popupCornerRadius {
            // Only draw a rounded rect
            points = [
                CGPoint(x: self.frame.midX, y: 0.0).withRadius(radius: KeyboardView.theme.popupCornerRadius),
                CGPoint.zero.withRadius(radius: KeyboardView.theme.popupCornerRadius),
                CGPoint(x: 0, y: contentView.frame.height + KeyboardView.theme.popupCornerRadius * 2).withRadius(radius: KeyboardView.theme.popupCornerRadius),
                CGPoint(x: self.frame.width, y: contentView.frame.height + KeyboardView.theme.popupCornerRadius * 2).withRadius(radius: KeyboardView.theme.popupCornerRadius),
                CGPoint(x: self.frame.width, y: 0.0).withRadius(radius: KeyboardView.theme.popupCornerRadius),
                CGPoint(x: self.bounds.midX, y: 0.0).withRadius(radius: KeyboardView.theme.popupCornerRadius),
                CGPoint(x: self.bounds.midX, y: 0.0).withRadius(radius: KeyboardView.theme.popupCornerRadius)
            ]
        } else if originFrameInLocalBounds.maxX + KeyboardView.theme.popupCornerRadius * 2 >= bounds.maxX {
            // Regular bubble
            points = [
                CGPoint(x: self.frame.midX, y: 0.0).withRadius(radius: KeyboardView.theme.popupCornerRadius),
                CGPoint.zero.withRadius(radius: KeyboardView.theme.popupCornerRadius),
                CGPoint(x: 0, y: contentView.frame.height + KeyboardView.theme.popupCornerRadius * 2).withRadius(radius: KeyboardView.theme.popupCornerRadius),
                CGPoint(x: originFrameInLocalBounds.minX, y: contentView.frame.height + KeyboardView.theme.popupCornerRadius * 3).withRadius(radius: KeyboardView.theme.popupCornerRadius),
                CGPoint(x: originFrameInLocalBounds.minX, y: self.bounds.maxY).withRadius(radius: KeyboardView.theme.keyCornerRadius),
                CGPoint(x: originFrameInLocalBounds.maxX, y: self.bounds.maxY).withRadius(radius: KeyboardView.theme.keyCornerRadius),
                CGPoint(x: originFrameInLocalBounds.maxX, y: contentView.frame.height + KeyboardView.theme.popupCornerRadius * 3).withRadius(radius: KeyboardView.theme.popupCornerRadius),
                CGPoint(x: self.frame.width, y: contentView.frame.height + KeyboardView.theme.popupCornerRadius * 2).withRadius(radius: KeyboardView.theme.popupCornerRadius),
                CGPoint(x: self.frame.width, y: 0.0).withRadius(radius: KeyboardView.theme.popupCornerRadius),
                CGPoint(x: self.bounds.midX, y: 0.0).withRadius(radius: KeyboardView.theme.popupCornerRadius),
                CGPoint(x: self.bounds.midX, y: 0.0).withRadius(radius: KeyboardView.theme.popupCornerRadius)
            ]
        } else {
            // Longpress bubble
            points = [
                CGPoint(x: self.frame.midX, y: 0.0).withRadius(radius: KeyboardView.theme.popupCornerRadius),
                CGPoint.zero.withRadius(radius: KeyboardView.theme.popupCornerRadius),
                CGPoint(x: 0, y: contentView.frame.height + KeyboardView.theme.popupCornerRadius * 2).withRadius(radius: originFrameInLocalBounds.minX < KeyboardView.theme.popupCornerRadius ? 0 : KeyboardView.theme.popupCornerRadius),
                CGPoint(x: originFrameInLocalBounds.minX, y: contentView.frame.height + KeyboardView.theme.popupCornerRadius * 2).withRadius(radius: KeyboardView.theme.popupCornerRadius),
                CGPoint(x: originFrameInLocalBounds.minX, y: self.bounds.maxY).withRadius(radius: KeyboardView.theme.keyCornerRadius),
                CGPoint(x: originFrameInLocalBounds.maxX, y: self.bounds.maxY).withRadius(radius: KeyboardView.theme.keyCornerRadius),
                CGPoint(x: originFrameInLocalBounds.maxX, y: contentView.frame.height + KeyboardView.theme.popupCornerRadius * 2).withRadius(radius: KeyboardView.theme.popupCornerRadius),
                CGPoint(x: self.frame.width, y: contentView.frame.height + KeyboardView.theme.popupCornerRadius * 2).withRadius(radius: originFrameInLocalBounds.maxX > self.frame.width - KeyboardView.theme.popupCornerRadius ? 0 : KeyboardView.theme.popupCornerRadius),
                CGPoint(x: self.frame.width, y: 0.0).withRadius(radius: KeyboardView.theme.popupCornerRadius),
                CGPoint(x: self.bounds.midX, y: 0.0).withRadius(radius: KeyboardView.theme.popupCornerRadius),
                CGPoint(x: self.bounds.midX, y: 0.0).withRadius(radius: KeyboardView.theme.popupCornerRadius)
            ]
        }

        let path = CGMutablePath()
        path.move(to: CGPoint(x: frame.midX, y: 0.0))

        for (index, point) in points.enumerated() {
            if index < points.count - 1 {
                path.addArc(tangent1End: point.point, tangent2End: points[index + 1].point, radius: point.radius)
            }
        }

        path.closeSubpath()

        return path
    }
}

private extension CGPoint {
    func withRadius(radius: CGFloat) -> KeyOverlayView.PopupPathPoint {
        return KeyOverlayView.PopupPathPoint(radius: radius, point: self)
    }
}
