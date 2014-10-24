//
//  GiellaKeyboard.swift
//  TastyImitationKeyboard
//
//  Created by Brendan Molloy on 24/10/2014.
//  Copyright (c) 2014
//

import UIKit

class GiellaKeyboard: KeyboardViewController {
    override func keyPressed(key: Key) {
        if let textDocumentProxy = self.textDocumentProxy as? UIKeyInput {
            textDocumentProxy.insertText(key.outputForCase(self.shiftState.uppercase()))
        }
    }
    
    init() {
        // XXX: generatedKeyboard() must be generated! :)
        super.init(nibName: nil, bundle: nil, keyboard: defaultControls(generatedKeyboard()))
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

func defaultControls(defaultKeyboard: Keyboard) -> Keyboard {
    var keyModel2 = Key(.Backspace)
    defaultKeyboard.addKey(keyModel2, row: 2, page: 0)
    
    var keyModeChangeNumbers = Key(.ModeChange)
    keyModeChangeNumbers.uppercaseKeyCap = "123"
    keyModeChangeNumbers.toMode = 1
    defaultKeyboard.addKey(keyModeChangeNumbers, row: 3, page: 0)
    
    var keyModel4 = Key(.KeyboardChange)
    defaultKeyboard.addKey(keyModel4, row: 3, page: 0)
    
    var keyModel5 = Key(.Space)
    keyModel5.uppercaseKeyCap = "space"
    keyModel5.uppercaseOutput = " "
    keyModel5.lowercaseOutput = " "
    defaultKeyboard.addKey(keyModel5, row: 3, page: 0)
    
    var keyModel6 = Key(.Return)
    keyModel6.uppercaseKeyCap = "return"
    keyModel6.uppercaseOutput = "\n"
    keyModel6.lowercaseOutput = "\n"
    defaultKeyboard.addKey(keyModel6, row: 3, page: 0)
    
    for key in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"] {
        var keyModel = Key(.SpecialCharacter)
        keyModel.setLetter(key)
        defaultKeyboard.addKey(keyModel, row: 0, page: 1)
    }
    
    for key in ["-", "/", ":", ";", "(", ")", "$", "&", "@", "\""] {
        var keyModel = Key(.SpecialCharacter)
        keyModel.setLetter(key)
        defaultKeyboard.addKey(keyModel, row: 1, page: 1)
    }
    
    var keyModeChangeSpecialCharacters = Key(.ModeChange)
    keyModeChangeSpecialCharacters.uppercaseKeyCap = "#+="
    keyModeChangeSpecialCharacters.toMode = 2
    defaultKeyboard.addKey(keyModeChangeSpecialCharacters, row: 2, page: 1)
    
    for key in [".", ",", "?", "!", "'"] {
        var keyModel = Key(.SpecialCharacter)
        keyModel.setLetter(key)
        defaultKeyboard.addKey(keyModel, row: 2, page: 1)
    }
    
    defaultKeyboard.addKey(Key(keyModel2), row: 2, page: 1)
    
    var keyModeChangeLetters = Key(.ModeChange)
    keyModeChangeLetters.uppercaseKeyCap = "ABC"
    keyModeChangeLetters.toMode = 0
    defaultKeyboard.addKey(keyModeChangeLetters, row: 3, page: 1)
    
    defaultKeyboard.addKey(Key(keyModel4), row: 3, page: 1)
    
    defaultKeyboard.addKey(Key(keyModel5), row: 3, page: 1)
    
    defaultKeyboard.addKey(Key(keyModel6), row: 3, page: 1)
    
    for key in ["[", "]", "{", "}", "#", "%", "^", "*", "+", "="] {
        var keyModel = Key(.SpecialCharacter)
        keyModel.setLetter(key)
        defaultKeyboard.addKey(keyModel, row: 0, page: 2)
    }
    
    for key in ["_", "\\", "|", "~", "<", ">", "€", "£", "Y", "•"] {
        var keyModel = Key(.SpecialCharacter)
        keyModel.setLetter(key)
        defaultKeyboard.addKey(keyModel, row: 1, page: 2)
    }
    
    defaultKeyboard.addKey(Key(keyModeChangeNumbers), row: 2, page: 2)
    
    for key in [".", ",", "?", "!", "'"] {
        var keyModel = Key(.SpecialCharacter)
        keyModel.setLetter(key)
        defaultKeyboard.addKey(keyModel, row: 2, page: 2)
    }
    
    defaultKeyboard.addKey(Key(keyModel2), row: 2, page: 2)
    
    defaultKeyboard.addKey(Key(keyModeChangeLetters), row: 3, page: 2)
    
    defaultKeyboard.addKey(Key(keyModel4), row: 3, page: 2)
    
    defaultKeyboard.addKey(Key(keyModel5), row: 3, page: 2)
    
    defaultKeyboard.addKey(Key(keyModel6), row: 3, page: 2)
    
    return defaultKeyboard
}

