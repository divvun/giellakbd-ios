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
    var popupKeyFont: UIFont { get }
    var bannerFont: UIFont { get }
    
    var bannerBackgroundColor: UIColor { get }
    var bannerSeparatorColor: UIColor { get }
    var bannerTextColor: UIColor { get }
    
    var bannerHorizontalMargin: CGFloat { get }
    var bannerVerticalMargin: CGFloat { get }
}

class LightThemeImpl: Theme {
    let regularKeyColor = UIColor.white
    let specialKeyColor = UIColor(r: 172, g: 177, b: 185)
    let popupColor = UIColor.white
    let backgroundColor = UIColor(r: 202, g: 205, b: 212)
    let underColor = UIColor(hue: 0.611, saturation: 0.04, brightness: 0.56, alpha: 1)
    let textColor = UIColor.black
    let borderColor = UIColor.clear//UIColor(hue: 0.595, saturation: 0.04, brightness: 0.65, alpha: 1.0)
    var specialKeyBorderColor: UIColor { return .clear }
    let keyShadowColor = UIColor(r: 103, g: 106, b: 110, a: 0.5)
    let shiftActiveColor = UIColor.white
    var solidRegularKeyColor: UIColor { return self.regularKeyColor }
    var solidSpecialKeyColor = UIColor(r: 183, g: 191, b: 202)
    var solidPopupColor: UIColor { return self.popupColor }
    let activeColor: UIColor = UIColor(r: 31, g: 126, b: 249)
    let activeTextColor: UIColor = UIColor.white
    
    let keyCornerRadius: CGFloat = 8.0
    let popupCornerRadius: CGFloat = 12.0
    let keyHorizontalMargin: CGFloat = 2.5
    let keyVerticalMargin: CGFloat = 5.0

    let keyFont = UIFont.systemFont(ofSize: 22.0)
    let popupKeyFont = UIFont.systemFont(ofSize: 26.0)
    let bannerFont = UIFont.systemFont(ofSize: 16.0)

    var bannerBackgroundColor: UIColor { return self.backgroundColor }
    var bannerSeparatorColor: UIColor { return self.solidSpecialKeyColor }
    var bannerTextColor: UIColor  { return .black }
    
    let bannerHorizontalMargin: CGFloat = 16.0
    let bannerVerticalMargin: CGFloat = 8.0

    fileprivate init() {}
}

class DarkThemeImpl: Theme {
    var backgroundColor: UIColor = UIColor(r: 0, g: 0, b: 0, a: 0.8)
    
    var keyShadowColor: UIColor = UIColor(r: 103, g: 106, b: 110, a: 0.5)
    
    let regularKeyColor = UIColor.white.withAlphaComponent(CGFloat(0.3))
    let specialKeyColor = UIColor.gray.withAlphaComponent(CGFloat(0.3))
    let popupColor = UIColor.gray
    let underColor = UIColor(r: 39, g: 18, b: 39, a: 0.4)
    let textColor = UIColor.white
    let borderColor = UIColor.clear
    var specialKeyBorderColor: UIColor { return specialKeyColor }
    let shiftActiveColor = UIColor(r: 214, g: 220, b: 208)
    var solidRegularKeyColor = UIColor(r: 83, g: 83, b: 83)
    var solidSpecialKeyColor = UIColor(r: 45, g: 45, b: 45)
    var solidPopupColor: UIColor { return self.solidRegularKeyColor }
    let activeColor: UIColor = UIColor(r: 31, g: 126, b: 249)
    let activeTextColor: UIColor = UIColor.white

    let keyCornerRadius: CGFloat = 8.0
    let popupCornerRadius: CGFloat = 12.0
    let keyHorizontalMargin: CGFloat = 2.5
    let keyVerticalMargin: CGFloat = 5.0

    let keyFont = UIFont.systemFont(ofSize: 22.0)
    let popupKeyFont = UIFont.systemFont(ofSize: 26.0)
    let bannerFont = UIFont.systemFont(ofSize: 16.0)

    var bannerBackgroundColor: UIColor { return self.backgroundColor }
    var bannerSeparatorColor: UIColor { return self.solidSpecialKeyColor }
    var bannerTextColor: UIColor  { return .white }

    let bannerHorizontalMargin: CGFloat = 16.0
    let bannerVerticalMargin: CGFloat = 8.0

    fileprivate init() {}
}

let LightTheme = LightThemeImpl()
let DarkTheme = DarkThemeImpl()
