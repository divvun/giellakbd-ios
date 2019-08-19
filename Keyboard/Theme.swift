//
//  Theme.swift
//  RewriteKeyboard
//
//  Created by Ville Petersson on 2019-07-03.
//  Copyright © 2019 The Techno Creatives AB. All rights reserved.
//

import Foundation
import UIKit

protocol Theme {
    var regularKeyColor: UIColor { get }
    var specialKeyColor: UIColor { get }
    var popupColor: UIColor { get }
    var backgroundColor: UIColor { get }
    var underColor: UIColor { get }
    var textColor: UIColor { get }
    var inactiveTextColor: UIColor { get }
    var borderColor: UIColor { get }
    var specialKeyBorderColor: UIColor { get }
    var keyShadowColor: UIColor { get }
    var shiftActiveColor: UIColor { get }
    var solidRegularKeyColor: UIColor { get }
    var solidSpecialKeyColor: UIColor { get }
    var solidPopupColor: UIColor { get }
    var activeColor: UIColor { get }
    var activeTextColor: UIColor { get }

    var keyCornerRadius: CGFloat { get }
    var popupCornerRadius: CGFloat { get }
    var keyVerticalMargin: CGFloat { get }
    var keyHorizontalMargin: CGFloat { get }

    var keyFont: UIFont { get }
    var alternateKeyFontSize: CGFloat { get }
    var popupKeyFont: UIFont { get }
    var bannerFont: UIFont { get }
    
    var bannerBackgroundColor: UIColor { get }
    var bannerSeparatorColor: UIColor { get }
    var bannerTextColor: UIColor { get }
    
    var bannerHorizontalMargin: CGFloat { get }
    var bannerVerticalMargin: CGFloat { get }
}

class LightThemeImpl: Theme {
    var regularKeyColor = UIColor.white
    var specialKeyColor = UIColor(r: 172, g: 177, b: 185)
    var popupColor = UIColor.white
    var backgroundColor = UIColor(r: 202, g: 205, b: 212)
    var underColor = UIColor(hue: 0.611, saturation: 0.04, brightness: 0.56, alpha: 1)
    var textColor = UIColor.black
    var inactiveTextColor: UIColor = UIColor.lightGray
    var borderColor = UIColor.clear//UIColor(hue: 0.595, saturation: 0.04, brightness: 0.65, alpha: 1.0)
    var specialKeyBorderColor: UIColor { return .clear }
    var keyShadowColor = UIColor(r: 103, g: 106, b: 110, a: 0.5)
    var shiftActiveColor = UIColor.white
    var solidRegularKeyColor: UIColor { return self.regularKeyColor }
    var solidSpecialKeyColor = UIColor(r: 183, g: 191, b: 202)
    var solidPopupColor: UIColor { return self.popupColor }
    var activeColor: UIColor = UIColor(r: 31, g: 126, b: 249)
    var activeTextColor: UIColor = UIColor.white
    
    var keyCornerRadius: CGFloat { return 8.0 }
    var popupCornerRadius: CGFloat = 12.0
    var keyHorizontalMargin: CGFloat { return 2.5 }
    var keyVerticalMargin: CGFloat { return 5.0 }

    var keyFont: UIFont { return UIFont.systemFont(ofSize: 22.0) }
    var alternateKeyFontSize: CGFloat { return 20.0 }
    var popupKeyFont = UIFont.systemFont(ofSize: 26.0)
    var bannerFont = UIFont.systemFont(ofSize: 16.0)

    var bannerBackgroundColor: UIColor { return self.backgroundColor }
    var bannerSeparatorColor: UIColor { return self.solidSpecialKeyColor }
    var bannerTextColor: UIColor  { return .black }
    
    var bannerHorizontalMargin: CGFloat = 16.0
    var bannerVerticalMargin: CGFloat = 8.0

    fileprivate init() {}
}

class LightThemeIpadImpl: LightThemeImpl {
    override var keyCornerRadius: CGFloat { return 12.0 }
    override var keyHorizontalMargin: CGFloat { return 9.0 }
    override var keyVerticalMargin: CGFloat { return 7.0 }
    
    override var keyFont: UIFont { return UIFont.systemFont(ofSize: 28.0) }
}

class DarkThemeImpl: Theme {
    var backgroundColor: UIColor = UIColor(r: 0, g: 0, b: 0, a: 0.8)
    
    var keyShadowColor: UIColor = UIColor(r: 103, g: 106, b: 110, a: 0.5)
    
    var regularKeyColor = UIColor.white.withAlphaComponent(CGFloat(0.3))
    var specialKeyColor = UIColor.gray.withAlphaComponent(CGFloat(0.3))
    var popupColor = UIColor.gray
    var underColor = UIColor(r: 39, g: 18, b: 39, a: 0.4)
    var textColor = UIColor.white
    var inactiveTextColor: UIColor = UIColor.lightGray
    var borderColor = UIColor.clear
    var specialKeyBorderColor: UIColor { return specialKeyColor }
    var shiftActiveColor = UIColor(r: 214, g: 220, b: 208)
    var solidRegularKeyColor = UIColor(r: 83, g: 83, b: 83)
    var solidSpecialKeyColor = UIColor(r: 45, g: 45, b: 45)
    var solidPopupColor: UIColor { return self.solidRegularKeyColor }
    var activeColor: UIColor = UIColor(r: 31, g: 126, b: 249)
    var activeTextColor: UIColor = UIColor.white

    var keyCornerRadius: CGFloat = 8.0
    var popupCornerRadius: CGFloat = 12.0
    var keyHorizontalMargin: CGFloat = 2.5
    var keyVerticalMargin: CGFloat = 5.0

    var keyFont = UIFont.systemFont(ofSize: 22.0)
    var alternateKeyFontSize: CGFloat { return 20.0 }
    var popupKeyFont = UIFont.systemFont(ofSize: 26.0)
    var bannerFont = UIFont.systemFont(ofSize: 16.0)

    var bannerBackgroundColor: UIColor { return self.regularKeyColor }
    var bannerSeparatorColor: UIColor { return self.solidSpecialKeyColor }
    var bannerTextColor: UIColor  { return .white }

    var bannerHorizontalMargin: CGFloat = 16.0
    var bannerVerticalMargin: CGFloat = 8.0

    fileprivate init() {}
}

let LightTheme = UIDevice.current.kind == UIDevice.Kind.iPad ? LightThemeIpadImpl() : LightThemeImpl()
let DarkTheme = DarkThemeImpl()
