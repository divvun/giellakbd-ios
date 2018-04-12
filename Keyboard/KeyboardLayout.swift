//
//  KeyboardLayout.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 7/25/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

import UIKit

// TODO: need to rename, consolidate, and define terms
class LayoutConstants {
    static let landscapeRatio = CGFloat(2)
    static let sideEdgesPortraitArray: [CGFloat] = [3, 4]

    // side edges increase on 6 in portrait
    static let sideEdgesPortraitWidthThreshholds: [CGFloat] = [400]
    static let sideEdgesLandscape = CGFloat(3)

    // top edges decrease on various devices in portrait
    static let topEdgePortraitArray: [CGFloat] = [12, 10, 8]
    static let topEdgePortraitWidthThreshholds: [CGFloat] = [350, 400]
    static let topEdgeLandscape = CGFloat(6)

    // keyboard area shrinks in size in landscape on 6 and 6+
    static let keyboardShrunkSizeArray: [CGFloat] = [522, 524]
    static let keyboardShrunkSizeWidthThreshholds: [CGFloat] = [700]
    static let keyboardShrunkSizeBaseWidthThreshhold = CGFloat(600)

    // row gaps are weird on 6 in portrait
    static let rowGapPortraitArray: [CGFloat] = [15, 11, 10]
    static let rowGapPortraitThreshholds: [CGFloat] = [350, 400]
    static let rowGapPortraitLastRow = CGFloat(9)
    static let rowGapPortraitLastRowIndex = 1
    static let rowGapLandscape = CGFloat(7)

    // key gaps have weird and inconsistent rules
    static let keyGapPortraitNormal = CGFloat(6)
    static let keyGapPortraitSmall = CGFloat(5)
    static let keyGapPortraitNormalThreshhold = CGFloat(350)
    static let keyGapPortraitUncompressThreshhold = CGFloat(350)
    static let keyGapLandscapeNormal = CGFloat(6)
    static let keyGapLandscapeSmall = CGFloat(5)
    // TODO: 5.5 row gap on 5L
    // TODO: wider row gap on 6L
    static let keyCompressedThreshhold = 11

    // rows with two special keys on the side and characters in the middle (usually 3rd row)
    // TODO: these are not pixel-perfect, but should be correct within a few pixels
    // TODO: are there any "hidden constants" that would allow us to get rid of the multiplier? see: popup dimensions
    static let flexibleEndRowTotalWidthToKeyWidthMPortrait = CGFloat(1)
    static let flexibleEndRowTotalWidthToKeyWidthCPortrait = CGFloat(-14)
    static let flexibleEndRowTotalWidthToKeyWidthMLandscape = CGFloat(0.9231)
    static let flexibleEndRowTotalWidthToKeyWidthCLandscape = CGFloat(-9.4615)
    static let flexibleEndRowMinimumStandardCharacterWidth = CGFloat(7)

    static let lastRowKeyGapPortrait = CGFloat(6)
    static let lastRowKeyGapLandscapeArray: [CGFloat] = [8, 7, 5]
    static let lastRowKeyGapLandscapeWidthThreshholds: [CGFloat] = [500, 700]

    // TODO: approxmiate, but close enough
    static let lastRowPortraitFirstTwoButtonAreaWidthToKeyboardAreaWidth = CGFloat(0.24)
    static let lastRowLandscapeFirstTwoButtonAreaWidthToKeyboardAreaWidth = CGFloat(0.19)
    static let lastRowPortraitLastButtonAreaWidthToKeyboardAreaWidth = CGFloat(0.24)
    static let lastRowLandscapeLastButtonAreaWidthToKeyboardAreaWidth = CGFloat(0.19)
    static let micButtonPortraitWidthRatioToOtherSpecialButtons = CGFloat(0.765)

    // TODO: not exactly precise
    static let popupGap = CGFloat(8)
    static let popupWidthIncrement = CGFloat(26)
    static let popupTotalHeightArray: [CGFloat] = [102, 108]
    static let popupTotalHeightDeviceWidthThreshholds: [CGFloat] = [350]

    static func sideEdgesPortrait(_ width: CGFloat) -> CGFloat {
        return self.findThreshhold(self.sideEdgesPortraitArray, threshholds: self.sideEdgesPortraitWidthThreshholds, measurement: width)
    }
    static func topEdgePortrait(_ width: CGFloat) -> CGFloat {
        return self.findThreshhold(self.topEdgePortraitArray, threshholds: self.topEdgePortraitWidthThreshholds, measurement: width)
    }
    static func rowGapPortrait(_ width: CGFloat) -> CGFloat {
        return self.findThreshhold(self.rowGapPortraitArray, threshholds: self.rowGapPortraitThreshholds, measurement: width)
    }

    static func rowGapPortraitLastRow(_ width: CGFloat) -> CGFloat {
        let index = self.findThreshholdIndex(self.rowGapPortraitThreshholds, measurement: width)
        if index == self.rowGapPortraitLastRowIndex {
            return self.rowGapPortraitLastRow
        }
        else {
            return self.rowGapPortraitArray[index]
        }
    }

    static func keyGapPortrait(_ width: CGFloat, rowCharacterCount: Int) -> CGFloat {
        let compressed = (rowCharacterCount >= self.keyCompressedThreshhold)
        let isPad = UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad
        var res: CGFloat

        if compressed {
            if width >= self.keyGapPortraitUncompressThreshhold {
                res = self.keyGapPortraitNormal
            }
            else {
                res = self.keyGapPortraitSmall
            }
        }
        else {
            res = self.keyGapPortraitNormal
        }

        // TODO make constant
        return isPad ? res * 2.2 : res
    }

    static func keyGapLandscape(_ width: CGFloat, rowCharacterCount: Int) -> CGFloat {
        let compressed = (rowCharacterCount >= self.keyCompressedThreshhold)
        let shrunk = self.keyboardIsShrunk(width)
        let isPad = UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad
        var res: CGFloat

        if compressed || shrunk {
            res = self.keyGapLandscapeSmall
        }
        else {
            res = self.keyGapLandscapeNormal
        }

        // TODO make constant
        return isPad ? res * 2.2 : res
    }

    static func lastRowKeyGapLandscape(_ width: CGFloat) -> CGFloat {
        return self.findThreshhold(self.lastRowKeyGapLandscapeArray, threshholds: self.lastRowKeyGapLandscapeWidthThreshholds, measurement: width)
    }

    static func keyboardIsShrunk(_ width: CGFloat) -> Bool {
        let isPad = UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad
        return (isPad ? false : width >= self.keyboardShrunkSizeBaseWidthThreshhold)
    }
    static func keyboardShrunkSize(_ width: CGFloat) -> CGFloat {
        let isPad = UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad
        if isPad {
            return width
        }

        if width >= self.keyboardShrunkSizeBaseWidthThreshhold {
            return self.findThreshhold(self.keyboardShrunkSizeArray, threshholds: self.keyboardShrunkSizeWidthThreshholds, measurement: width)
        }
        else {
            return width
        }
    }

    static func popupTotalHeight(_ deviceWidth: CGFloat) -> CGFloat {
        return self.findThreshhold(self.popupTotalHeightArray, threshholds: self.popupTotalHeightDeviceWidthThreshholds, measurement: deviceWidth)
    }

    static func findThreshhold(_ elements: [CGFloat], threshholds: [CGFloat], measurement: CGFloat) -> CGFloat {
        assert(elements.count == threshholds.count + 1, "elements and threshholds do not match")
        return elements[self.findThreshholdIndex(threshholds, measurement: measurement)]
    }
    static func findThreshholdIndex(_ threshholds: [CGFloat], measurement: CGFloat) -> Int {
        for (i, threshhold) in threshholds.reversed().enumerated() {
            if measurement >= threshhold {
                let actualIndex = threshholds.count - i
                return actualIndex
            }
        }
        return 0
    }
}

extension CGRect: Hashable {
    public var hashValue: Int {
        get {
            return (origin.x.hashValue ^ origin.y.hashValue ^ size.width.hashValue ^ size.height.hashValue)
        }
    }
}

extension CGSize: Hashable {
    public var hashValue: Int {
        get {
            return (width.hashValue ^ height.hashValue)
        }
    }
}

// handles the layout for the keyboard, including key spacing and arrangement
class KeyboardLayout: NSObject, KeyboardKeyProtocol {

    static let shouldPoolKeys: Bool = true

    var layoutConstants: LayoutConstants.Type

    unowned var model: Keyboard
    unowned var superview: UIView
    var modelToView: [Key:KeyboardKey] = [:]
    var viewToModel: [KeyboardKey:Key] = [:]

    var keyPool: [KeyboardKey] = []
    var nonPooledMap: [String:KeyboardKey] = [:]
    var sizeToKeyMap: [CGSize:[KeyboardKey]] = [:]
    var shapePool: [String:Shape] = [:]

    var darkMode: Bool
    var solidColorMode: Bool
    
    required init(model: Keyboard, superview: UIView, layoutConstants: LayoutConstants.Type, darkMode: Bool, solidColorMode: Bool) {
        self.layoutConstants = layoutConstants

        self.model = model
        self.superview = superview

        self.darkMode = darkMode
        self.solidColorMode = solidColorMode
    }
    
    func viewForKey(_ model: Key) -> KeyboardKey? {
        return self.modelToView[model]
    }

    func keyForView(_ key: KeyboardKey) -> Key? {
        return self.viewToModel[key]
    }

    //////////////////////////////////////////////
    // CALL THESE FOR LAYOUT/APPEARANCE CHANGES //
    //////////////////////////////////////////////

    func layoutKeys(_ pageNum: Int, uppercase: Bool, characterUppercase: Bool, shiftState: ShiftState) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        // pre-allocate all keys if no cache
        if !KeyboardLayout.shouldPoolKeys {
            if self.keyPool.isEmpty {
                for p in 0..<self.model.pages.count {
                    self.positionKeys(p)
                }
                
                self.updateKeyAppearance()
                
                self.updateKeyCaps(
                    true,
                    uppercase: uppercase,
                    characterUppercase: characterUppercase,
                    shiftState: shiftState
                )
            }
        }

        self.positionKeys(pageNum)

        // reset state
        for (p, page) in self.model.pages.enumerated() {
            for row in page.rows {
                for key in row {
                    if let keyView = self.modelToView[key] {
                        keyView.hidePopup()
                        keyView.isHighlighted = false
                        keyView.isHidden = (p != pageNum)
                    }
                }
            }
        }

        if KeyboardLayout.shouldPoolKeys {
            self.updateKeyAppearance()
            self.updateKeyCaps(
                true,
                uppercase: uppercase,
                characterUppercase: characterUppercase,
                shiftState: shiftState
            )
        }

        CATransaction.commit()
    }

    func positionKeys(_ pageNum: Int) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        let setupKey = { (view: KeyboardKey, model: Key, frame: CGRect) -> Void in
            view.frame = frame
            self.modelToView[model] = view
            self.viewToModel[view] = model
        }

        if var keyMap = self.generateKeyFrames(self.model, bounds: self.superview.bounds, page: pageNum) {
            if KeyboardLayout.shouldPoolKeys {
                self.modelToView.removeAll(keepingCapacity: true)
                self.viewToModel.removeAll(keepingCapacity: true)

                self.resetKeyPool()

                var foundCachedKeys = [Key]()

                // pass 1: reuse any keys that match the required size
                for (key, frame) in keyMap {
                    if let keyView = self.pooledKey(key: key, model: self.model, frame: frame) {
                        foundCachedKeys.append(key)
                        setupKey(keyView, key, frame)
                    }
                }

                foundCachedKeys.forEach {
                    keyMap.removeValue(forKey: $0)
                }

                // pass 2: fill in the blanks
                for (key, frame) in keyMap {
                    let keyView = self.generateKey()
                    setupKey(keyView, key, frame)
                }
            }
            else {
                for (key, frame) in keyMap {
                    if let keyView = self.pooledKey(key: key, model: self.model, frame: frame) {
                        setupKey(keyView, key, frame)
                    }
                }
            }
        }

        CATransaction.commit()
    }

    func updateKeyAppearance() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        for (key, view) in self.modelToView {
            self.setAppearanceForKey(view, model: key, theme: darkMode ? DarkTheme : LightTheme, solidColorMode: self.solidColorMode)
        }

        CATransaction.commit()
    }

    // on fullReset, we update the keys with shapes, images, etc. as if from scratch; otherwise, just update the text
    // WARNING: if key cache is disabled, DO NOT CALL WITH fullReset MORE THAN ONCE
    func updateKeyCaps(_ fullReset: Bool, uppercase: Bool, characterUppercase: Bool, shiftState: ShiftState) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        if fullReset {
            for (_, key) in self.modelToView {
                key.shape = nil

                if let imageKey = key as? ImageKey { // TODO:
                    imageKey.image = nil
                }
            }
        }

        for (model, key) in self.modelToView {
            self.updateKeyCap(key, model: model, fullReset: fullReset, uppercase: uppercase, characterUppercase: characterUppercase, shiftState: shiftState)
        }

        CATransaction.commit()
    }

    func updateKeyCap(_ key: KeyboardKey, model: Key, fullReset: Bool, uppercase: Bool, characterUppercase: Bool, shiftState: ShiftState) {
        if fullReset {
            // font size
            switch model.type {
            case
            Key.KeyType.modeChange,
            Key.KeyType.space,
            Key.KeyType.return:
                key.label.adjustsFontSizeToFitWidth = true
                key.label.font = key.label.font.withSize(16)
            default:
                key.label.font = UIFont.systemFont(ofSize: 24)
            }

            // label inset
            switch model.type {
            case
            Key.KeyType.modeChange:
                key.labelInset = 3
            default:
                key.labelInset = 0
            }

            // shapes
            switch model.type {
            case Key.KeyType.shift:
                if key.shape == nil {
                    let shiftShape = self.getShape(ShiftShape.self)
                    key.shape = shiftShape
                }
            case Key.KeyType.backspace:
                if key.shape == nil {
                    let backspaceShape = self.getShape(BackspaceShape.self)
                    key.shape = backspaceShape
                }
            case Key.KeyType.keyboardChange:
                if key.shape == nil {
                    let globeShape = self.getShape(GlobeShape.self)
                    key.shape = globeShape
                }
            default:
                break
            }

            // images
            if model.type == Key.KeyType.settings {
                if let imageKey = key as? ImageKey {
                    if imageKey.image == nil {
                        let gearImage = UIImage(named: "gear")
                        let settingsImageView = UIImageView(image: gearImage)
                        imageKey.image = settingsImageView
                    }
                }
            }
        }

        if model.type == Key.KeyType.shift {
            if key.shape == nil {
                let shiftShape = self.getShape(ShiftShape.self)
                key.shape = shiftShape
            }

            switch shiftState {
            case .disabled:
                key.isHighlighted = false
            case .enabled:
                key.isHighlighted = true
            case .locked:
                key.isHighlighted = true
            }

            (key.shape as? ShiftShape)?.withLock = (shiftState == .locked)
        }

        self.updateKeyCapText(key, model: model, uppercase: uppercase, characterUppercase: characterUppercase)
    }

    func updateKeyCapText(_ key: KeyboardKey, model: Key, uppercase: Bool, characterUppercase: Bool) {
        if model.type == .character {
            key.text = model.keyCapForCase(characterUppercase)
        }
        else {
            key.text = model.keyCapForCase(uppercase)
        }
    }

    ///////////////
    // END CALLS //
    ///////////////

    func setAppearanceForKey(_ key: KeyboardKey, model: Key, theme: ColorTheme, solidColorMode: Bool) {
        let isPad = UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad
        if model.type == Key.KeyType.other {
            self.setAppearanceForOtherKey(key, model: model, darkMode: darkMode, solidColorMode: solidColorMode)
        }

        switch model.type {
        case .character, .specialCharacter, .period:
            key.color = theme.regularKey
            key.downColor = isPad ? theme.specialKey : nil
            key.textColor = theme.text
            key.downTextColor = nil
        case .space:
            key.color = theme.regularKey
            key.downColor = theme.specialKey
            key.textColor = theme.text
            key.downTextColor = nil
        case .shift:
            key.color = theme.specialKey
            key.downColor = theme.shiftActive
            key.textColor = theme.text
            key.downTextColor = theme.text
        case .backspace:
            key.color = theme.specialKey
            key.downColor = theme.regularKey
            key.textColor = theme.text
            key.downTextColor = nil // TODO: wtf (darkMode ? nil : self.globalColors.lightModeTextColor)
        case .modeChange:
            key.color = theme.specialKey
            key.downColor = nil
            key.textColor = theme.text
            key.downTextColor = nil
        case .return, .keyboardChange, .keyboardHide, .settings:
            key.color = theme.specialKey
            key.downColor = theme.regularKey
            key.textColor = theme.text
            key.labelInset = 3
            key.downTextColor = nil
        default:
            break
        }

        key.popupColor = theme.popup // TODO wtf self.globalColors.popup(darkMode, solidColorMode: solidColorMode)
        key.underColor = theme.under
        key.borderColor = theme.border
    }

    func setAppearanceForOtherKey(_ key: KeyboardKey, model: Key, darkMode: Bool, solidColorMode: Bool) { /* override this to handle special keys */ }

    // TODO: avoid array copies
    // TODO: sizes stored not rounded?

    ///////////////////////////
    // KEY POOLING FUNCTIONS //
    ///////////////////////////

    // if pool is disabled, always returns a unique key view for the corresponding key model
    func pooledKey(key aKey: Key, model: Keyboard, frame: CGRect) -> KeyboardKey? {
        if !KeyboardLayout.shouldPoolKeys {
            var p: Int!
            var r: Int!
            var k: Int!

            // TODO: O(N^2) in terms of total # of keys since pooledKey is called for each key, but probably doesn't matter
            var foundKey: Bool = false
            for (pp, page) in model.pages.enumerated() {
                for (rr, row) in page.rows.enumerated() {
                    for (kk, key) in row.enumerated() {
                        if key == aKey {
                            p = pp
                            r = rr
                            k = kk
                            foundKey = true
                        }
                        if foundKey {
                            break
                        }
                    }
                    if foundKey {
                        break
                    }
                }
                if foundKey {
                    break
                }
            }

            let id = "p\(p)r\(r)k\(k)"
            if let key = self.nonPooledMap[id] {
                return key
            }
            else {
                let key = generateKey()
                self.nonPooledMap[id] = key
                return key
            }
        }
        else {
            if var keyArray = self.sizeToKeyMap[frame.size] {
                if let key = keyArray.last {
                    if keyArray.count == 1 {
                        self.sizeToKeyMap.removeValue(forKey: frame.size)
                    }
                    else {
                        keyArray.removeLast()
                        self.sizeToKeyMap[frame.size] = keyArray
                    }
                    return key
                }
                else {
                    return nil
                }

            }
            else {
                return nil
            }
        }
    }

    // if pool is disabled, always generates a new key
    func generateKey() -> KeyboardKey {
        let createAndSetupNewKey = { () -> KeyboardKey in
            let keyView = ImageKey(vibrancy: nil)
            
            keyView.isEnabled = true
            keyView.delegate = self

            self.superview.addSubview(keyView)

            self.keyPool.append(keyView)

            return keyView
        }

        if KeyboardLayout.shouldPoolKeys {
            if !self.sizeToKeyMap.isEmpty {
                var (size, keyArray) = self.sizeToKeyMap[self.sizeToKeyMap.startIndex]

                if let key = keyArray.last {
                    if keyArray.count == 1 {
                        self.sizeToKeyMap.removeValue(forKey: size)
                    }
                    else {
                        keyArray.removeLast()
                        self.sizeToKeyMap[size] = keyArray
                    }

                    return key
                }
                else {
                    return createAndSetupNewKey()
                }
            }
            else {
                return createAndSetupNewKey()
            }
        }
        else {
            return createAndSetupNewKey()
        }
    }

    // if pool is disabled, doesn't do anything
    func resetKeyPool() {
        if KeyboardLayout.shouldPoolKeys {
            self.sizeToKeyMap.removeAll(keepingCapacity: true)

            for key in self.keyPool {
                if var keyArray = self.sizeToKeyMap[key.frame.size] {
                    keyArray.append(key)
                    self.sizeToKeyMap[key.frame.size] = keyArray
                }
                else {
                    var keyArray = [KeyboardKey]()
                    keyArray.append(key)
                    self.sizeToKeyMap[key.frame.size] = keyArray
                }
                key.isHidden = true
            }
        }
    }

    // TODO: no support for more than one of the same shape
    // if pool disabled, always returns new shape
    func getShape(_ shapeClass: Shape.Type) -> Shape {
        _ = NSStringFromClass(shapeClass)

        /*
        if self.dynamicType.shouldPoolKeys {
            if let shape = self.shapePool[className] {
                return shape
            }
            else {
                var shape = shapeClass.init(frame: CGRectZero)
                self.shapePool[className] = shape
                return shape
            }
        }

        else {*/
            return shapeClass.init(frame: CGRect.zero)
        //}
    }

    //////////////////////
    // LAYOUT FUNCTIONS //
    //////////////////////

    func rounded(_ measurement: CGFloat) -> CGFloat {
        return round(measurement * UIScreen.main.scale) / UIScreen.main.scale
    }

    func generateKeyFrames(_ model: Keyboard, bounds: CGRect, page pageToLayout: Int) -> [Key:CGRect]? {
        if bounds.height == 0 || bounds.width == 0 {
            return nil
        }

        var keyMap = [Key:CGRect]()

        let isLandscape: Bool = {
            let boundsRatio = bounds.width / bounds.height
            return (boundsRatio >= self.layoutConstants.landscapeRatio)
        }()

        var sideEdges = (isLandscape ? self.layoutConstants.sideEdgesLandscape : self.layoutConstants.sideEdgesPortrait(bounds.width))
        let bottomEdge = sideEdges

        let normalKeyboardSize = bounds.width - CGFloat(2) * sideEdges
        let shrunkKeyboardSize = self.layoutConstants.keyboardShrunkSize(normalKeyboardSize)

        sideEdges += ((normalKeyboardSize - shrunkKeyboardSize) / CGFloat(2))

        let topEdge = CGFloat((isLandscape ? self.layoutConstants.topEdgeLandscape : self.layoutConstants.topEdgePortrait(bounds.width)))

        let rowGap = CGFloat((isLandscape ? self.layoutConstants.rowGapLandscape : self.layoutConstants.rowGapPortrait(bounds.width)))
        let lastRowGap = CGFloat((isLandscape ? rowGap : self.layoutConstants.rowGapPortraitLastRow(bounds.width)))

        _ = (isLandscape ? self.layoutConstants.flexibleEndRowTotalWidthToKeyWidthMLandscape : self.layoutConstants.flexibleEndRowTotalWidthToKeyWidthMPortrait)
        _ = (isLandscape ? self.layoutConstants.flexibleEndRowTotalWidthToKeyWidthCLandscape : self.layoutConstants.flexibleEndRowTotalWidthToKeyWidthCPortrait)

        let lastRowLeftSideRatio = (isLandscape ? self.layoutConstants.lastRowLandscapeFirstTwoButtonAreaWidthToKeyboardAreaWidth : self.layoutConstants.lastRowPortraitFirstTwoButtonAreaWidthToKeyboardAreaWidth)
        let lastRowRightSideRatio = (isLandscape ? self.layoutConstants.lastRowLandscapeLastButtonAreaWidthToKeyboardAreaWidth : self.layoutConstants.lastRowPortraitLastButtonAreaWidthToKeyboardAreaWidth)
        let lastRowKeyGap = (isLandscape ? self.layoutConstants.lastRowKeyGapLandscape(bounds.width) : self.layoutConstants.lastRowKeyGapPortrait)

        for (p, page) in model.pages.enumerated() {
            if p != pageToLayout {
                continue
            }

            let numRows = page.rows.count

            let mostKeysInRow: Int = {
                var currentMax: Int = 0
                for (_, row) in page.rows.enumerated() {
                    currentMax = max(currentMax, row.count)
                }
                return currentMax
            }()

            let rowGapTotal = CGFloat(numRows - 1 - 1) * rowGap + lastRowGap

            let keyGap: CGFloat = (isLandscape ? self.layoutConstants.keyGapLandscape(bounds.width, rowCharacterCount: mostKeysInRow) : self.layoutConstants.keyGapPortrait(bounds.width, rowCharacterCount: mostKeysInRow))

            let isPad = UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad

            let keyHeight: CGFloat = {
                let totalGaps = bottomEdge + topEdge + rowGapTotal
                let returnHeight = (bounds.height - totalGaps) / CGFloat(numRows)
                // TODO can only change this if viewport height is recalced
                return self.rounded(/*isPad ? returnHeight * 0.95 : */returnHeight)

                }()

            let letterKeyWidth: CGFloat = {
                let totalGaps = (sideEdges * CGFloat(2)) + (keyGap * CGFloat(mostKeysInRow - 1))
                let returnWidth = (bounds.width - totalGaps) / CGFloat(mostKeysInRow)
                // TODO make the pad multiplier a constant
                return self.rounded(isPad ? returnWidth * 0.95 : returnWidth)
                }()

            let processRow = { (row: [Key], frames: [CGRect], map: inout [Key:CGRect]) -> Void in
                assert(row.count == frames.count, "row and frames don't match")
                for (k, key) in row.enumerated() {
                    map[key] = frames[k]
                }
            }

            for (r, row) in page.rows.enumerated() {
                let rowGapCurrentTotal = (r == page.rows.count - 1 ? rowGapTotal : CGFloat(r) * rowGap)
                let frame = CGRect(x: rounded(sideEdges), y: rounded(topEdge + (CGFloat(r) * keyHeight) + rowGapCurrentTotal), width: rounded(bounds.width - CGFloat(2) * sideEdges), height: rounded(keyHeight))

                var frames: [CGRect]!


                // bottom row with things like space, return, etc.
                if self.specialKeysRowHeuristic(row) {
                    frames = self.layoutSpecialKeysRow(row, keyWidth: letterKeyWidth, gapWidth: lastRowKeyGap, leftSideRatio: lastRowLeftSideRatio, rightSideRatio: lastRowRightSideRatio, micButtonRatio: self.layoutConstants.micButtonPortraitWidthRatioToOtherSpecialButtons, isLandscape: isLandscape, frame: frame)
                }

                // character row with side buttons: shift, backspace, etc.
                else if self.doubleSidedRowHeuristic(row) {
                    frames = self.layoutCharacterWithSidesRow(row, frame: frame, isLandscape: isLandscape, keyWidth: letterKeyWidth, keyGap: keyGap)
                }

                // basic character row: only typable characters
                else {
                    frames = self.layoutCharacterRow(row, keyWidth: letterKeyWidth, gapWidth: keyGap, frame: frame)
                }

                processRow(row, frames, &keyMap)
            }
        }

        return keyMap
    }
    /*
    func characterRowHeuristic(row: [Key]) -> Bool {
        let last = row.count - 1
        return (row.count >= 1 && row[0].isCharacter && row[last].isCharacter)
    }
    */

    func specialKeysRowHeuristic(_ row: [Key]) -> Bool {
        return row[0].type == .modeChange && row[1].type == .keyboardChange
    }

    func doubleSidedRowHeuristic(_ row: [Key]) -> Bool {
        let last = row.count - 1
        return !row[0].isCharacter || !row[last].isCharacter
    }

    func layoutCharacterRow(_ row: [Key], keyWidth: CGFloat, gapWidth: CGFloat, frame: CGRect) -> [CGRect] {
        var frames = [CGRect]()

        let keySpace = CGFloat(row.count) * keyWidth + CGFloat(row.count - 1) * gapWidth
        var actualGapWidth = gapWidth
        var sideSpace = (frame.width - keySpace) / CGFloat(2)

        // TODO: port this to the other layout functions
        // avoiding rounding errors
        if sideSpace < 0 {
            sideSpace = 0
            actualGapWidth = (frame.width - (CGFloat(row.count) * keyWidth)) / CGFloat(row.count - 1)
        }

        var currentOrigin = frame.origin.x + sideSpace

        for (_, _) in row.enumerated() {
            let roundedOrigin = rounded(currentOrigin)

            // avoiding rounding errors
            if roundedOrigin + keyWidth > frame.origin.x + frame.width {
                frames.append(CGRect(x: rounded(frame.origin.x + frame.width - keyWidth), y: frame.origin.y, width: keyWidth, height: frame.height))
            }
            else {
                frames.append(CGRect(x: rounded(currentOrigin), y: frame.origin.y, width: keyWidth, height: frame.height))
            }

            currentOrigin += (keyWidth + actualGapWidth)
        }

        return frames
    }

    // TODO: pass in actual widths instead
    func layoutCharacterWithSidesRow(_ row: [Key], frame: CGRect, isLandscape: Bool, keyWidth: CGFloat, keyGap: CGFloat) -> [CGRect] {
        var frames = [CGRect]()

        let isPad = UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad

        let standardFullKeyCount = Int(self.layoutConstants.keyCompressedThreshhold) - 1
        let standardGap = (isLandscape ? self.layoutConstants.keyGapLandscape : self.layoutConstants.keyGapPortrait)(frame.width, standardFullKeyCount)
        let sideEdges = (isLandscape ? self.layoutConstants.sideEdgesLandscape : self.layoutConstants.sideEdgesPortrait(frame.width))
        var standardKeyWidth = (frame.width - sideEdges - (standardGap * CGFloat(standardFullKeyCount - 1)) - sideEdges)
        standardKeyWidth /= CGFloat(standardFullKeyCount)
        let standardKeyCount = self.layoutConstants.flexibleEndRowMinimumStandardCharacterWidth

        let standardWidth = CGFloat(standardKeyWidth * standardKeyCount + standardGap * (standardKeyCount - 1))
        let currentWidth = CGFloat(row.count - 2) * keyWidth + CGFloat(row.count - 3) * keyGap

        let isStandardWidth = (currentWidth < standardWidth)
        let actualWidth = (isStandardWidth ? standardWidth : currentWidth)
        let actualGap = (isStandardWidth ? standardGap : keyGap)
        let actualKeyWidth = (actualWidth - CGFloat(row.count - 3) * actualGap) / CGFloat(row.count - 2)

        let sideSpace = (frame.width - actualWidth) / CGFloat(2)

        let m = (isLandscape ? self.layoutConstants.flexibleEndRowTotalWidthToKeyWidthMLandscape : self.layoutConstants.flexibleEndRowTotalWidthToKeyWidthMPortrait)
        let c = (isLandscape ? self.layoutConstants.flexibleEndRowTotalWidthToKeyWidthCLandscape : self.layoutConstants.flexibleEndRowTotalWidthToKeyWidthCPortrait)

        let firstKey = row[0]
        let lastKey = row[row.count-1]
        let singleSpecialKey = !(firstKey.isSpecial && lastKey.isSpecial)
        // TODO constant
        let specialKeyMin = standardKeyWidth * CGFloat(1.025)

        var specialCharacterWidth: CGFloat
        var specialCharacterGap: CGFloat
        var remainingSpace: CGFloat

        if isPad {
            if singleSpecialKey {
                specialCharacterWidth = max(specialKeyMin, sideSpace / CGFloat(2))
            } else {
                specialCharacterWidth = min(standardKeyWidth, sideSpace - keyGap)
            }

            // Fixes margin issue on the right.
            specialCharacterWidth += (m * 2)
            specialCharacterGap = sideSpace - specialCharacterWidth

            remainingSpace = sideSpace / 4

        } else {
            specialCharacterWidth = rounded(max(sideSpace * m + c, keyWidth))
            specialCharacterGap = sideSpace - specialCharacterWidth
            remainingSpace = specialCharacterGap
        }

        var currentOrigin = frame.origin.x + m

        for (k, key) in row.enumerated() {
            if k == 0 {
                if !key.isSpecial {
                    if lastKey.type != .backspace {
                        currentOrigin += remainingSpace
                    }
                    frames.append(CGRect(x: rounded(currentOrigin), y: frame.origin.y, width: actualKeyWidth, height: frame.height))
                    currentOrigin += (actualKeyWidth + keyGap)
                } else {
                    frames.append(CGRect(x: rounded(currentOrigin), y: frame.origin.y, width: specialCharacterWidth, height: frame.height))
                    currentOrigin += (specialCharacterWidth + specialCharacterGap)
                }
            }
            else if k == row.count - 1 {
                if !key.isSpecial {
                    frames.append(CGRect(x: rounded(currentOrigin), y: frame.origin.y, width: actualKeyWidth, height: frame.height))
                    currentOrigin += (actualKeyWidth)
                } else {
                    if singleSpecialKey {
                        currentOrigin += keyGap
                    } else {
                        currentOrigin += specialCharacterGap
                    }
                    
                    // Unaligned pixel workaround hack
                    if !isLandscape {
                        currentOrigin -= 2
                    }
                    
                    let width = isPad ? frame.width - currentOrigin : actualKeyWidth
                    
                    frames.append(CGRect(x: rounded(currentOrigin), y: frame.origin.y, width: width, height: frame.height))
                    currentOrigin += specialCharacterWidth
                }
            }
            else {
                frames.append(CGRect(x: rounded(currentOrigin), y: frame.origin.y, width: actualKeyWidth, height: frame.height))
                if k == row.count - 2 {
                    currentOrigin += (actualKeyWidth)
                }
                else {
                    currentOrigin += (actualKeyWidth + keyGap)
                }
            }
        }

        return frames
    }

    func layoutSpecialKeysRow(_ row: [Key], keyWidth: CGFloat, gapWidth: CGFloat, leftSideRatio: CGFloat, rightSideRatio: CGFloat, micButtonRatio: CGFloat, isLandscape: Bool, frame: CGRect) -> [CGRect] {
        var frames = [CGRect]()

        var keysBeforeSpace = 0
        var keysAfterSpace = 0
        var reachedSpace = false
        for (_, key) in row.enumerated() {
            if key.type == Key.KeyType.space {
                reachedSpace = true
            }
            else {
                if !reachedSpace {
                    keysBeforeSpace += 1
                }
                else {
                    keysAfterSpace += 1
                }
            }
        }

        assert(keysBeforeSpace <= 3, "invalid number of keys before space (only max 3 currently supported)")
        assert(keysAfterSpace >= 1 && keysAfterSpace <= 2, "invalid number of keys after space (only 1-2 currently supported)")

        let hasButtonInMicButtonPosition = (keysBeforeSpace == 3)
        
        let isPad = UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad
        
        let gap = isPad ? gapWidth * 1.8 : gapWidth
        
        var leftSideAreaWidth = frame.width * leftSideRatio
        var rightSideAreaWidth = frame.width * rightSideRatio
        var leftButtonWidth = (leftSideAreaWidth - (gap * CGFloat(2 - 1))) / CGFloat(2)
        
        leftButtonWidth = rounded(leftButtonWidth)
        
        let modeButtonWidth = isPad ? leftButtonWidth / 1.2 : leftButtonWidth
        
        if isPad { leftButtonWidth /= 1.8 }
        
        var rightButtonWidth = (rightSideAreaWidth - (gap * CGFloat(keysAfterSpace - 1))) / CGFloat(keysAfterSpace)
        rightButtonWidth = rounded(rightButtonWidth)

        var micButtonWidth = (isLandscape ? leftButtonWidth : leftButtonWidth * micButtonRatio)
        if isPad { micButtonWidth = leftButtonWidth }

        // special case for mic button
        if hasButtonInMicButtonPosition {
            leftSideAreaWidth = leftSideAreaWidth + gap + micButtonWidth
        }
        
        if (isPad) {
            leftSideAreaWidth -= (leftButtonWidth * 1.8 - leftButtonWidth)
            leftSideAreaWidth -= (modeButtonWidth * 1.2 - modeButtonWidth)
            rightSideAreaWidth -= (modeButtonWidth * 1.2 - modeButtonWidth)
        }

        var spaceWidth = frame.width - leftSideAreaWidth - rightSideAreaWidth - gap * CGFloat(2)
        spaceWidth = rounded(spaceWidth)

        var currentOrigin = frame.origin.x
        var beforeSpace: Bool = true
        for (k, key) in row.enumerated() {
            if key.type == Key.KeyType.space {
                frames.append(CGRect(x: rounded(currentOrigin), y: frame.origin.y, width: spaceWidth, height: frame.height))
                currentOrigin += (spaceWidth + gap)
                beforeSpace = false
            }
            else if key.type == Key.KeyType.modeChange {
                frames.append(CGRect(x: rounded(currentOrigin), y: frame.origin.y, width: modeButtonWidth, height: frame.height))
                currentOrigin += (modeButtonWidth + gap)
            }
            else if beforeSpace {
                if hasButtonInMicButtonPosition && k == 2 { //mic button position
                    frames.append(CGRect(x: rounded(currentOrigin), y: frame.origin.y, width: micButtonWidth, height: frame.height))
                    currentOrigin += (micButtonWidth + gap)
                }
                else {
                    frames.append(CGRect(x: rounded(currentOrigin), y: frame.origin.y, width: leftButtonWidth, height: frame.height))
                    currentOrigin += (leftButtonWidth + gap)
                }
            }
            else {
                let width = (isPad && k == row.count - 1) ? frame.width - currentOrigin : rounded(rightButtonWidth)
                frames.append(CGRect(x: rounded(currentOrigin), y: frame.origin.y, width: width, height: frame.height))
                currentOrigin += (width + gap)
            }
        }

        return frames
    }

    ////////////////
    // END LAYOUT //
    ////////////////

    func frameForPopup(_ key: KeyboardKey, direction: Direction, longpressKeys:[String]) -> CGRect {
        let actualScreenWidth = (UIScreen.main.nativeBounds.size.width / UIScreen.main.nativeScale)
        let totalHeight = self.layoutConstants.popupTotalHeight(actualScreenWidth)

        let popupWidth = (longpressKeys.count > 0 ? CGFloat(longpressKeys.count * 36) : key.bounds.width) + self.layoutConstants.popupWidthIncrement
        let popupHeight = totalHeight - self.layoutConstants.popupGap - key.bounds.height
        _ = 0

        return CGRect(x: (key.bounds.width - popupWidth) / CGFloat(2), y: -popupHeight - self.layoutConstants.popupGap, width: popupWidth, height: popupHeight)
    }

    func willShowPopup(_ key: KeyboardKey, direction: Direction) {
        // TODO: actual numbers, not standins
        if let popup = key.popup {
            // TODO: total hack
            let actualSuperview = (self.superview.superview != nil ? self.superview.superview! : self.superview)

            var localFrame = actualSuperview.convert(popup.frame, from: popup.superview)

            if localFrame.origin.y < 3 {
                localFrame.origin.y = 3

                key.background.attached = Direction.down
                key.connector?.startDir = Direction.down
                key.background.hideDirectionIsOpposite = true
            }
            else {
                // TODO: this needs to be reset somewhere
                key.background.hideDirectionIsOpposite = false
            }

            if localFrame.origin.x < 3 {
                localFrame.origin.x = key.frame.origin.x
            }

            if localFrame.origin.x + localFrame.width > superview.bounds.width - 3 {
                localFrame.origin.x = localFrame.origin.x - (localFrame.origin.x + localFrame.width - superview.bounds.width) - 3
            }

            popup.frame = actualSuperview.convert(localFrame, to: popup.superview)
        }
    }

    func willHidePopup(_ key: KeyboardKey) {
    }
}
