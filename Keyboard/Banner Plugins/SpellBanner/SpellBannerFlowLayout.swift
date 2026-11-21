import UIKit

final class SpellBannerFlowLayout: UICollectionViewFlowLayout {
    private let separatorKind = "bannerSeparator"
    private let theme: Theme

    /// - Parameter theme: The banner's theme, which the separators are drawn with. The collection view creates the
    ///   separators itself, so they get it from their layout attributes.
    init(theme: Theme) {
        self.theme = theme
        super.init()
        register(SpellBannerSeparatorView.self, forDecorationViewOfKind: separatorKind)
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let cellAttributes = super.layoutAttributesForElements(in: rect) else {
            return nil
        }

        var decoratorAttributes = [UICollectionViewLayoutAttributes]()

        for cellAttribute in cellAttributes {
            let indexPath = cellAttribute.indexPath
            let separatorAttributes = SpellBannerSeparatorAttributes(forDecorationViewOfKind: separatorKind,
                                                                     with: indexPath)
            let cellFrame = cellAttribute.frame

            separatorAttributes.frame = CGRect(x: cellFrame.maxX,
                                               y: cellFrame.origin.y,
                                               width: minimumLineSpacing,
                                               height: cellFrame.height)
            separatorAttributes.zIndex = 1000
            separatorAttributes.lineColor = theme.bannerSeparatorColor
            separatorAttributes.backgroundColor = theme.bannerBackgroundColor
            separatorAttributes.bottomInset = theme.bannerSeparatorBottomInset

            decoratorAttributes.append(separatorAttributes)
        }

        let newAttributes = cellAttributes + decoratorAttributes
        return newAttributes
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Layout attributes of a banner separator, carrying the theme's values for it.
final class SpellBannerSeparatorAttributes: UICollectionViewLayoutAttributes {
    var lineColor: UIColor = .clear
    var backgroundColor: UIColor = .clear
    /// Space between the line and the banner's bottom edge, or `nil` to centre it.
    var bottomInset: CGFloat?

    override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone)
        if let copy = copy as? SpellBannerSeparatorAttributes {
            copy.lineColor = lineColor
            copy.backgroundColor = backgroundColor
            copy.bottomInset = bottomInset
        }
        return copy
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? SpellBannerSeparatorAttributes else {
            return false
        }
        return lineColor == other.lineColor
            && backgroundColor == other.backgroundColor
            && bottomInset == other.bottomInset
            && super.isEqual(object)
    }
}
