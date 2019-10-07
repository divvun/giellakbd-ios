//
//  SplitKeyboard.swift
//  Keyboard
//
//  Created by Ville Petersson on 2019-09-19.
//  Copyright © 2019. All rights reserved.
//

import UIKit

private func leftHalf(_ pageOfKeys: [[KeyDefinition]]) -> [[KeyDefinition]] {
    return pageOfKeys.map { row in
        row.enumerated().filter { i, _ in
            i < (row.count / 2)
        }.map { $0.1 }
    }
}

private func rightHalf(_ pageOfKeys: [[KeyDefinition]]) -> [[KeyDefinition]] {
    return pageOfKeys.map { row in
        row.enumerated().filter { i, _ in
            i >= (row.count / 2)
        }.map { $0.1 }
    }
}

class SplitKeyboardView: KeyboardViewProvider {
    var swipeDownKeysEnabled: Bool {
        get {
            return leftKeyboardView.swipeDownKeysEnabled
        }
        set {
            leftKeyboardView.swipeDownKeysEnabled = newValue
            rightKeyboardView.swipeDownKeysEnabled = newValue
        }
    }

    var delegate: (KeyboardViewDelegate & KeyboardViewKeyboardKeyDelegate)? {
        get {
            return leftKeyboardView.delegate
        }
        set {
            leftKeyboardView.delegate = newValue
            rightKeyboardView.delegate = newValue
        }
    }

    var page: KeyboardPage {
        get {
            return leftKeyboardView.page
        }
        set {
            leftKeyboardView.page = newValue
            rightKeyboardView.page = newValue
        }
    }

    func updateTheme(theme: Theme) {
        leftKeyboardView.updateTheme(theme: theme)
    }

    func update() {
        leftKeyboardView.update()
        rightKeyboardView.update()
    }

    var topAnchor: NSLayoutYAxisAnchor {
        return leftKeyboardView.topAnchor
    }

    var heightAnchor: NSLayoutDimension {
        return leftKeyboardView.heightAnchor
    }

    var leftKeyboardView: KeyboardView
    var rightKeyboardView: KeyboardView

    required init(definition: KeyboardDefinition) {
        var leftDefinition = definition
        leftDefinition.normal = leftHalf(definition.normal.splitAndBalanceSpacebar())
        leftDefinition.shifted = leftHalf(definition.shifted.splitAndBalanceSpacebar())
        leftDefinition.symbols1 = leftHalf(definition.symbols1.splitAndBalanceSpacebar())
        leftDefinition.symbols2 = leftHalf(definition.symbols2.splitAndBalanceSpacebar())

        var rightDefinition = definition
        rightDefinition.normal = rightHalf(definition.normal.splitAndBalanceSpacebar())
        rightDefinition.shifted = rightHalf(definition.shifted.splitAndBalanceSpacebar())
        rightDefinition.symbols1 = rightHalf(definition.symbols1.splitAndBalanceSpacebar())
        rightDefinition.symbols2 = rightHalf(definition.symbols2.splitAndBalanceSpacebar())

        let leftKeyboardView = KeyboardView(definition: leftDefinition)
        leftKeyboardView.translatesAutoresizingMaskIntoConstraints = false
        self.leftKeyboardView = leftKeyboardView

        let rightKeyboardView = KeyboardView(definition: rightDefinition)
        rightKeyboardView.translatesAutoresizingMaskIntoConstraints = false
        self.rightKeyboardView = rightKeyboardView
    }

    func remove() {
        leftKeyboardView.delegate = nil
        leftKeyboardView.removeFromSuperview()

        rightKeyboardView.delegate = nil
        rightKeyboardView.removeFromSuperview()
    }
}
