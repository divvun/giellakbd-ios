//
//  ColorTheme.swift
//  TastyImitationKeyboard
//
//  Created by Brendan Molloy on 26/4/17.
//  Copyright © 2017 Apple. All rights reserved.
//

import UIKit

extension UIColor {
    convenience init(r: Int, g: Int, b: Int, a: Double = 1) {
        self.init(red: CGFloat(r)/CGFloat(255), green: CGFloat(g)/CGFloat(255), blue: CGFloat(b)/CGFloat(255), alpha: CGFloat(a))
    }
}

protocol ColorTheme {
    var regularKey: UIColor { get }
    var specialKey: UIColor { get }
    var popup: UIColor { get }
    var under: UIColor { get }
    var text: UIColor { get }
    var border: UIColor { get }
    var shiftActive: UIColor { get }
    var solidRegularKey: UIColor { get }
    var solidSpecialKey: UIColor { get }
    var solidPopup: UIColor { get }
}

class LightThemeImpl: ColorTheme {
    let regularKey = UIColor.white
    let specialKey = UIColor(r: 183, g: 191, b: 202)
    let popup = UIColor.white
    let under = UIColor(hue: 0.611, saturation: 0.04, brightness: 0.56, alpha: 1)
    let text = UIColor.black
    let border = UIColor(hue: 0.595, saturation: 0.04, brightness: 0.65, alpha: 1.0)
    let shiftActive = UIColor.white
    var solidRegularKey: UIColor { return self.regularKey }
    var solidSpecialKey = UIColor(r: 183, g: 191, b: 202)
    var solidPopup: UIColor { return self.popup }
    
    fileprivate init() {}
}

class DarkThemeImpl: ColorTheme {
    let regularKey = UIColor.white.withAlphaComponent(CGFloat(0.3))
    let specialKey = UIColor.gray.withAlphaComponent(CGFloat(0.3))
    let popup = UIColor.gray
    let under = UIColor(r: 39, g: 18, b: 39, a: 0.4)
    let text = UIColor.white
    let border = UIColor.clear
    let shiftActive = UIColor(r: 214, g: 220, b: 208)
    var solidRegularKey = UIColor(r: 83, g: 83, b: 83)
    var solidSpecialKey = UIColor(r: 45, g: 45, b: 45)
    var solidPopup: UIColor { return self.solidRegularKey }
    
    fileprivate init() {}
}

let LightTheme = LightThemeImpl()
let DarkTheme = DarkThemeImpl()
