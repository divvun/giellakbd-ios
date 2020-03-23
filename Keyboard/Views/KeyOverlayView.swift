import UIKit

final class KeyOverlayView: UIView {
    private class KeyOverlayShadowView: UIView {}

    private let keyView: UIView
    private let key: KeyDefinition
    private let theme: ThemeType

    let keyBoundsView: UIView
    private var shadowView: KeyOverlayShadowView?

    private lazy var keyFrameInLocalBounds: CGRect = {
        let superview = self.superview!
        let keyFrameInSuperview = keyView.convert(keyView.frame, to: superview)
        let keyFrameInLocalBounds = superview
            .convert(keyFrameInSuperview, to: self)
            .insetBy(dx: theme.keyHorizontalMargin, dy: theme.keyVerticalMargin)
        return keyFrameInLocalBounds
    }()

    init(_ keyView: UIView, key: KeyDefinition, theme: ThemeType) {
        self.keyView = keyView
        self.keyView.translatesAutoresizingMaskIntoConstraints = false
        self.key = key
        self.theme = theme
        keyBoundsView = UIView(frame: keyView.bounds)
        keyBoundsView.clipsToBounds = false
        keyBoundsView.translatesAutoresizingMaskIntoConstraints = false

        super.init(frame: CGRect(x: 0, y: 0, width: keyView.frame.width, height: keyView.frame.height * 2))
        self.translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear
        addSubview(keyBoundsView)

        // This one breaks the top of the keyboard when given any chance to do so
        keyBoundsView.topAnchor
            .constraint(equalTo: topAnchor, constant: theme.popupCornerRadius)
            .enable(priority: .defaultHigh)

        keyBoundsView.bottomAnchor
            .constraint(greaterThanOrEqualTo: bottomAnchor, constant: -keyView.frame.height - theme.popupCornerRadius)
            .enable(priority: .defaultHigh)

        leftAnchor
            .constraint(lessThanOrEqualTo: keyBoundsView.leftAnchor, constant: -theme.popupCornerRadius)
            .enable(priority: .required)

        rightAnchor
            .constraint(greaterThanOrEqualTo: keyBoundsView.rightAnchor, constant: theme.popupCornerRadius)
            .enable(priority: .required)

        keyBoundsView.heightAnchor
            .constraint(equalToConstant: keyView.frame.height - theme.popupCornerRadius * 2)
            .enable(priority: .defaultHigh)

        keyBoundsView.widthAnchor
            .constraint(greaterThanOrEqualToConstant: keyView.frame.width)
            .enable(priority: .required)

        keyBoundsView.backgroundColor = .clear
        isUserInteractionEnabled = false
    }

    func addShadow() {
        guard self.shadowView == nil else { return }
        guard let superview = self.superview else { return }

        let shadowView = KeyOverlayShadowView()
        self.shadowView = shadowView
        shadowView.translatesAutoresizingMaskIntoConstraints = false
        shadowView.backgroundColor = UIColor.black
        superview.insertSubview(shadowView, belowSubview: self)

        // originFrameView is centered in the popup with `popupCornerRadius` amount of padding on each side.
        // Stretch our shadow view to fill the entire popup
        shadowView.fill(superview: keyBoundsView)
        shadowView.layer.shadowColor = UIColor(white: 0.0, alpha: 1.0).cgColor
        shadowView.layer.shadowOffset = CGSize(width: 0, height: theme.popupCornerRadius / 2.0)
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
        guard self.superview != nil else { return }

        let path = createPath()
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
        let points = getOverlayPoints()
        let path = CGMutablePath()

        path.move(to: CGPoint(x: frame.midX, y: 0.0))
        for (index, point) in points.enumerated() where index < points.count - 1 {
            path.addArc(tangent1End: point.point, tangent2End: points[index + 1].point, radius: point.radius)
        }
        path.closeSubpath()

        return path
    }

    private func getOverlayPoints() -> [PopupPathPoint] {
        // The height of the wide bubble at the top of the popup that contains the magnified character (or long press options)
        let bubbleHeight = keyBoundsView.frame.height + theme.popupCornerRadius * 2

        let topCenter = CGPoint(x: self.bounds.midX, y: 0.0).withRadius(theme.popupCornerRadius)
        let topLeft = CGPoint.zero.withRadius(theme.popupCornerRadius)

        // These are the bottom left and right points of the bubble that contain the letter in the popup.
        // This box is usually wider than the key.
        let letterBottomLeft = CGPoint(x: 0, y: bubbleHeight).withRadius(theme.popupCornerRadius)
        let letterBottomRight = CGPoint(x: self.frame.width, y: bubbleHeight).withRadius(theme.popupCornerRadius)

        let topRight = CGPoint(x: self.frame.width, y: 0.0).withRadius(theme.popupCornerRadius)

        let shouldShowRoundedRect = keyFrameInLocalBounds.maxY < bounds.maxY - theme.popupCornerRadius
        let shouldShowRegularBubble = keyFrameInLocalBounds.maxX + theme.popupCornerRadius * 2 >= bounds.maxX

        if shouldShowRoundedRect {
            return [
                topCenter,
                topLeft,
                letterBottomLeft,
                letterBottomRight,
                topRight,
                topCenter
            ]
        } else if shouldShowRegularBubble {
            let y = keyBoundsView.frame.height + theme.popupCornerRadius * 3
            let keyTopLeft = CGPoint(x: keyFrameInLocalBounds.minX, y: y).withRadius(theme.popupCornerRadius)
            let keyTopRight = CGPoint(x: keyFrameInLocalBounds.maxX, y: y).withRadius(theme.popupCornerRadius)
            let bottomLeft = CGPoint(x: keyFrameInLocalBounds.minX, y: self.bounds.maxY).withRadius(theme.keyCornerRadius)
            let bottomRight = CGPoint(x: keyFrameInLocalBounds.maxX, y: self.bounds.maxY).withRadius(theme.keyCornerRadius)

            return [
                topCenter,
                topLeft,
                letterBottomLeft,
                keyTopLeft,
                bottomLeft,
                bottomRight,
                keyTopRight,
                letterBottomRight,
                topRight,
                topCenter
            ]
        } else {
            // Longpress bubble and keys near edge of keyboard
            var bubbleConnectionCornerRadius: CGFloat = theme.popupCornerRadius
            var keyRadius: CGFloat = theme.keyCornerRadius

            let spaceBetweenBubbleBottomAndKeyBottom = self.frame.height - bubbleHeight

            if spaceBetweenBubbleBottomAndKeyBottom < 0 {
                // Unexpected; do nothing.
            } else if spaceBetweenBubbleBottomAndKeyBottom <= keyRadius {
                // Only enough room for the key radius (which we prefer). Give it as much room as we have.
                bubbleConnectionCornerRadius = 0
                keyRadius = spaceBetweenBubbleBottomAndKeyBottom
            } else if spaceBetweenBubbleBottomAndKeyBottom < keyRadius + bubbleConnectionCornerRadius {
                // Enough room for the key radius and part of the bubble radius. Use the full key radius
                // and give the bubble radius whatever space we have left over
                bubbleConnectionCornerRadius = spaceBetweenBubbleBottomAndKeyBottom - keyRadius
            }

            let leftRadius = keyFrameInLocalBounds.minX < theme.popupCornerRadius
                ? 0
                : theme.popupCornerRadius
            let rightRadius = keyFrameInLocalBounds.maxX > self.frame.width - theme.popupCornerRadius
                ? 0
                : theme.popupCornerRadius
            return [
                topCenter,
                topLeft,
                CGPoint(x: 0, y: bubbleHeight).withRadius(leftRadius),
                CGPoint(x: keyFrameInLocalBounds.minX, y: bubbleHeight).withRadius(bubbleConnectionCornerRadius),
                CGPoint(x: keyFrameInLocalBounds.minX, y: self.bounds.maxY).withRadius(keyRadius),
                CGPoint(x: keyFrameInLocalBounds.maxX, y: self.bounds.maxY).withRadius(keyRadius),
                CGPoint(x: keyFrameInLocalBounds.maxX, y: bubbleHeight).withRadius(bubbleConnectionCornerRadius),
                CGPoint(x: self.frame.width, y: bubbleHeight).withRadius(rightRadius),
                topRight,
                topCenter
            ]
        }
    }
}

private extension CGPoint {
    func withRadius(_ radius: CGFloat) -> KeyOverlayView.PopupPathPoint {
        return KeyOverlayView.PopupPathPoint(radius: radius, point: self)
    }
}
