import UIKit

final class SpellBannerFlowLayout: UICollectionViewFlowLayout {
    private let separatorKind = "bannerSeparator"

    override init() {
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
            let separatorAttributes = UICollectionViewLayoutAttributes.init(forDecorationViewOfKind: separatorKind,
                                                                            with: indexPath)
            let cellFrame = cellAttribute.frame

            separatorAttributes.frame = CGRect(x: cellFrame.maxX,
                                               y: cellFrame.origin.y,
                                               width: minimumLineSpacing,
                                               height: cellFrame.height)
            separatorAttributes.zIndex = 1000

            decoratorAttributes.append(separatorAttributes)
        }

        let newAttributes = cellAttributes + decoratorAttributes
        return newAttributes
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
