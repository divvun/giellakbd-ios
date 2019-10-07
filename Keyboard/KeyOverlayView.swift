//
//  KeyOverlayView.swift
//  RewriteKeyboard
//
//  Created by Ville Petersson on 2019-07-08.
//  Copyright © 2019 The Techno Creatives AB. All rights reserved.
//

import UIKit

class KeyOverlayView: UIView {
    class KeyOverlayShadowView: UIView {}

    let originView: UIView
    let key: KeyDefinition

    let contentView: UIView
    private var shadowView: KeyOverlayShadowView?

    var path: CGPath!

    init(origin: UIView, key: KeyDefinition) {
        self.originView = origin
        self.key = key
        self.contentView = UIView(frame: origin.bounds)
        super.init(frame: CGRect(x: 0, y: 0, width: origin.frame.width, height: origin.frame.height * 2))
        self.backgroundColor = .clear
        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.contentView)
        self.contentView.topAnchor.constraint(equalTo: self.topAnchor, constant: KeyboardView.theme.popupCornerRadius).isActive = true
        self.contentView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: KeyboardView.theme.popupCornerRadius).isActive = true
        self.contentView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -KeyboardView.theme.popupCornerRadius).isActive = true
        let bottomConstraint = self.contentView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -(origin.frame.height - KeyboardView.theme.keyHorizontalMargin * 2) - KeyboardView.theme.popupCornerRadius)
        bottomConstraint.priority = .defaultLow
        bottomConstraint.isActive = true
        let bottomConstraint2 = self.bottomAnchor.constraint(greaterThanOrEqualTo: self.contentView.bottomAnchor, constant: -KeyboardView.theme.popupCornerRadius)
        bottomConstraint2.priority = .required
        bottomConstraint2.isActive = true

        let heightConstraint = self.contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: origin.frame.height - KeyboardView.theme.popupCornerRadius * 2)
        heightConstraint.priority = .defaultLow
        heightConstraint.isActive = true
        self.contentView.backgroundColor = .clear
        self.isUserInteractionEnabled = false

    }

    func addShadow() {
        guard self.shadowView == nil else { return }
        guard let superview = self.superview else { return }

        let shadowView = KeyOverlayShadowView()
        self.shadowView = shadowView
        shadowView.translatesAutoresizingMaskIntoConstraints = false
        shadowView.backgroundColor = UIColor.black.withAlphaComponent(0.001)
        superview.insertSubview(shadowView, belowSubview: self)
        shadowView.fillSuperview(self.contentView)
        shadowView.layer.shadowColor = UIColor.init(white: 0.0, alpha: 1.0).cgColor
        shadowView.layer.shadowOffset = .zero
        shadowView.layer.shadowOpacity = 1.0
        shadowView.layer.shadowRadius = 12.0
        shadowView.clipsToBounds = false
    }

    override func didMoveToSuperview() {
        self.shadowView?.removeFromSuperview()
        self.shadowView = nil

        addShadow()
        super.didMoveToSuperview()
    }

    override func removeFromSuperview() {
        self.shadowView?.removeFromSuperview()
        super.removeFromSuperview()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        guard let _ = self.superview else { return }

        path = self.createPath()

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

        self.setNeedsDisplay()
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

        if originFrameInLocalBounds.maxY < self.bounds.maxY - KeyboardView.theme.popupCornerRadius {
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
        } else if originFrameInLocalBounds.maxX + KeyboardView.theme.popupCornerRadius * 2 >= self.bounds.maxX {
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
        path.move(to: CGPoint(x: self.frame.midX, y: 0.0))

        for (index, point) in points.enumerated() {
            if (index < points.count - 1) {
                path.addArc(tangent1End: point.point, tangent2End: points[index+1].point, radius: point.radius)
            }
        }

        path.closeSubpath()

        return path
    }
}

fileprivate extension CGPoint {
    func withRadius(radius: CGFloat) -> KeyOverlayView.PopupPathPoint {
        return KeyOverlayView.PopupPathPoint(radius: radius, point: self)
    }
}
