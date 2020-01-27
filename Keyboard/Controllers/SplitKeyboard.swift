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

    func updateTheme(theme: ThemeType) {
        leftKeyboardView.updateTheme(theme: theme)
        rightKeyboardView.updateTheme(theme: theme)
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

    required init(definition: KeyboardDefinition, theme: ThemeType) {
        let leftDefinition = definition.copy(
            normal: leftHalf(definition.normal.splitAndBalanceSpacebar()),
            shifted: leftHalf(definition.shifted.splitAndBalanceSpacebar()),
            symbols1: leftHalf(definition.symbols1.splitAndBalanceSpacebar()),
            symbols2: leftHalf(definition.symbols2.splitAndBalanceSpacebar())
        )

        let rightDefinition = definition.copy(
            normal: rightHalf(definition.normal.splitAndBalanceSpacebar()),
            shifted: rightHalf(definition.shifted.splitAndBalanceSpacebar()),
            symbols1: rightHalf(definition.symbols1.splitAndBalanceSpacebar()),
            symbols2: rightHalf(definition.symbols2.splitAndBalanceSpacebar())
        )

        let leftKeyboardView = KeyboardView(definition: leftDefinition, theme: theme)
        leftKeyboardView.translatesAutoresizingMaskIntoConstraints = false
        self.leftKeyboardView = leftKeyboardView

        let rightKeyboardView = KeyboardView(definition: rightDefinition, theme: theme)
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
