import UIKit

class KeyOverlayView: UIView {
    private class KeyOverlayShadowView: UIView {}

    private let originView: UIView
    private let key: KeyDefinition
    private let theme: ThemeType

    let originFrameView: UIView
    private var shadowView: KeyOverlayShadowView?

    private var path: CGPath!

    init(origin: UIView, key: KeyDefinition, theme: ThemeType) {
        originView = origin
        self.key = key
        self.theme = theme
        originFrameView = UIView(frame: origin.bounds)
        originFrameView.clipsToBounds = false
        
        super.init(frame: CGRect(x: 0, y: 0, width: origin.frame.width, height: origin.frame.height * 2))
        backgroundColor = .clear
        originFrameView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(originFrameView)
        
        // This one breaks the top of the keyboard when given any chance to do so
        originFrameView.topAnchor
            .constraint(equalTo: topAnchor, constant: theme.popupCornerRadius)
            .enable(priority: .defaultHigh)

        leftAnchor
            .constraint(lessThanOrEqualTo: originFrameView.leftAnchor, constant: -theme.popupCornerRadius)
            .enable(priority: .required)

        rightAnchor
            .constraint(greaterThanOrEqualTo: originFrameView.rightAnchor, constant: theme.popupCornerRadius)
            .enable(priority: .required)
        
        originFrameView.heightAnchor
            .constraint(lessThanOrEqualToConstant: origin.frame.height - theme.popupCornerRadius * 2)
            .enable(priority: .defaultHigh)
        
        originFrameView.widthAnchor
            .constraint(greaterThanOrEqualToConstant: origin.frame.width)
            .enable(priority: .required)

        originFrameView.backgroundColor = .clear
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
        shadowView.fill(superview: originFrameView)
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

        theme.popupColor.setFill()
        bezier.fill()
        theme.popupBorderColor.setStroke()
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
        let originFrameInLocalBounds = superview
            .convert(originFrameInSuperview, to: self)
            .insetBy(dx: theme.keyHorizontalMargin, dy: theme.keyVerticalMargin)

        var points: [PopupPathPoint]

        if originFrameInLocalBounds.maxY < bounds.maxY - theme.popupCornerRadius {
            // Only draw a rounded rect
            points = [
                CGPoint(x: self.frame.midX, y: 0.0).withRadius(radius: theme.popupCornerRadius),
                CGPoint.zero.withRadius(radius: theme.popupCornerRadius),
                CGPoint(x: 0, y: originFrameView.frame.height + theme.popupCornerRadius * 2).withRadius(radius: theme.popupCornerRadius),
                CGPoint(x: self.frame.width, y: originFrameView.frame.height + theme.popupCornerRadius * 2).withRadius(radius: theme.popupCornerRadius),
                CGPoint(x: self.frame.width, y: 0.0).withRadius(radius: theme.popupCornerRadius),
                CGPoint(x: self.bounds.midX, y: 0.0).withRadius(radius: theme.popupCornerRadius),
                CGPoint(x: self.bounds.midX, y: 0.0).withRadius(radius: theme.popupCornerRadius)
            ]
        } else if originFrameInLocalBounds.maxX + theme.popupCornerRadius * 2 >= bounds.maxX {
            // Regular bubble
            points = [
                CGPoint(x: self.frame.midX, y: 0.0).withRadius(radius: theme.popupCornerRadius),
                CGPoint.zero.withRadius(radius: theme.popupCornerRadius),
                CGPoint(x: 0, y: originFrameView.frame.height + theme.popupCornerRadius * 2).withRadius(radius: theme.popupCornerRadius),
                CGPoint(x: originFrameInLocalBounds.minX, y: originFrameView.frame.height + theme.popupCornerRadius * 3).withRadius(radius: theme.popupCornerRadius),
                CGPoint(x: originFrameInLocalBounds.minX, y: self.bounds.maxY).withRadius(radius: theme.keyCornerRadius),
                CGPoint(x: originFrameInLocalBounds.maxX, y: self.bounds.maxY).withRadius(radius: theme.keyCornerRadius),
                CGPoint(x: originFrameInLocalBounds.maxX, y: originFrameView.frame.height + theme.popupCornerRadius * 3).withRadius(radius: theme.popupCornerRadius),
                CGPoint(x: self.frame.width, y: originFrameView.frame.height + theme.popupCornerRadius * 2).withRadius(radius: theme.popupCornerRadius),
                CGPoint(x: self.frame.width, y: 0.0).withRadius(radius: theme.popupCornerRadius),
                CGPoint(x: self.bounds.midX, y: 0.0).withRadius(radius: theme.popupCornerRadius),
                CGPoint(x: self.bounds.midX, y: 0.0).withRadius(radius: theme.popupCornerRadius)
            ]
        } else {
            // Longpress bubble
            points = [
                CGPoint(x: self.frame.midX, y: 0.0).withRadius(radius: theme.popupCornerRadius),
                CGPoint.zero.withRadius(radius: theme.popupCornerRadius),
                CGPoint(x: 0, y: originFrameView.frame.height + theme.popupCornerRadius * 2).withRadius(radius: originFrameInLocalBounds.minX < theme.popupCornerRadius ? 0 : theme.popupCornerRadius),
                CGPoint(x: originFrameInLocalBounds.minX, y: originFrameView.frame.height + theme.popupCornerRadius * 2).withRadius(radius: theme.popupCornerRadius),
                CGPoint(x: originFrameInLocalBounds.minX, y: self.bounds.maxY).withRadius(radius: theme.keyCornerRadius),
                CGPoint(x: originFrameInLocalBounds.maxX, y: self.bounds.maxY).withRadius(radius: theme.keyCornerRadius),
                CGPoint(x: originFrameInLocalBounds.maxX, y: originFrameView.frame.height + theme.popupCornerRadius * 2).withRadius(radius: theme.popupCornerRadius),
                CGPoint(x: self.frame.width, y: originFrameView.frame.height + theme.popupCornerRadius * 2).withRadius(radius: originFrameInLocalBounds.maxX > self.frame.width - theme.popupCornerRadius ? 0 : theme.popupCornerRadius),
                CGPoint(x: self.frame.width, y: 0.0).withRadius(radius: theme.popupCornerRadius),
                CGPoint(x: self.bounds.midX, y: 0.0).withRadius(radius: theme.popupCornerRadius),
                CGPoint(x: self.bounds.midX, y: 0.0).withRadius(radius: theme.popupCornerRadius)
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
