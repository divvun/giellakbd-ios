// GENERATION STUB.
import UIKit

func generatedKeyboard() -> Keyboard {
    let defaultKeyboard = Keyboard()
    
    let isPad = UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad

    var longPresses = generatedGetLongPresses();
    
    defaultKeyboard.addKey(Key(.Shift), row: 2, page: 0)
    
    for key in ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"] {
        let keyModel = Key(.Character)
        keyModel.setLetter(key)
        if let lp = longPresses[key] {
            keyModel.setUppercaseLongPress(lp)
        }
        if let lp = longPresses[key.lowercaseString] {
            keyModel.setLowercaseLongPress(lp)
        }

        defaultKeyboard.addKey(keyModel, row: 0, page: 0)
    }
    
    for key in ["A", "S", "D", "F", "G", "H", "J", "K", "L"] {
        let keyModel = Key(.Character)
        keyModel.setLetter(key)
        if let lp = longPresses[key] {
            keyModel.setUppercaseLongPress(lp)
        }
        if let lp = longPresses[key.lowercaseString] {
            keyModel.setLowercaseLongPress(lp)
        }

        defaultKeyboard.addKey(keyModel, row: 1, page: 0)
    }
    
    for key in ["Z", "X", "C", "V", "B", "N", "M"] {
        let keyModel = Key(.Character)
        keyModel.setLetter(key)
        if let lp = longPresses[key] {
            keyModel.setUppercaseLongPress(lp)
        }
        if let lp = longPresses[key.lowercaseString] {
            keyModel.setLowercaseLongPress(lp)
        }

        defaultKeyboard.addKey(keyModel, row: 2, page: 0)
    }
    
    if isPad {
        defaultKeyboard.addKey(Key(.Backspace), row: 0, page: 0)
        let returnKey = Key(.Return)
        returnKey.uppercaseKeyCap = "return"
        returnKey.uppercaseOutput = "\n"
        returnKey.lowercaseOutput = "\n"
        defaultKeyboard.addKey(returnKey, row: 1, page: 0)
        
        let commaKey = Key(.SpecialCharacter)
        commaKey.uppercaseKeyCap = "!\n,"
        commaKey.uppercaseOutput = "!"
        commaKey.lowercaseOutput = ","
        defaultKeyboard.addKey(commaKey, row: 2, page: 0)
        
        let periodKey = Key(.SpecialCharacter)
        periodKey.uppercaseKeyCap = "?\n."
        periodKey.uppercaseOutput = "?"
        periodKey.lowercaseOutput = "."
        defaultKeyboard.addKey(periodKey, row: 2, page: 0)
        
        defaultKeyboard.addKey(Key(.Shift), row: 2, page: 0)
    } else {
        /*
        let commaKey = Key(.SpecialCharacter)
        commaKey.uppercaseKeyCap = "!\n,"
        commaKey.uppercaseOutput = "!"
        commaKey.lowercaseOutput = ","
        defaultKeyboard.addKey(commaKey, row: 2, page: 0)
        
        let periodKey = Key(.SpecialCharacter)
        periodKey.uppercaseKeyCap = "?\n."
        periodKey.uppercaseOutput = "?"
        periodKey.lowercaseOutput = "."
        defaultKeyboard.addKey(periodKey, row: 2, page: 0)
        */
        defaultKeyboard.addKey(Key(.Backspace), row: 2, page: 0)
    }

    return defaultKeyboard
}

func generatedGetLongPresses() -> [String: [String]] {
    var lps = [String: [String]]()
    lps["k"] = ["ǩ"]
    lps["t"] = ["ŧ", "þ"]
    lps["d"] = ["đ", "ð"]
    lps["D"] = ["Đ", "Ð"]
    lps["Z"] = ["Ž", "Ʒ", "Ǯ"]
    lps["u"] = ["ü", "ú", "ù", "û", "ũ", "ū", "ŭ"]
    lps["n"] = ["ŋ"]
    lps["c"] = ["č", "ç"]
    lps["e"] = ["ë", "é", "è", "ê", "ẽ", "ė", "ē", "ĕ", "ę"]
    lps["Æ"] = ["Ä"]
    lps["Ø"] = ["Ö"]
    lps["æ"] = ["ä"]
    lps["A"] = ["Æ", "Ä", "Å", "Á", "À", "Â", "Ã", "Ȧ", "Ā"]
    lps["s"] = ["š"]
    lps["ø"] = ["ö"]
    lps["S"] = ["Š"]
    lps["K"] = ["Ǩ"]
    lps["G"] = ["Ĝ", "Ḡ", "Ǧ", "Ǥ"]
    lps["O"] = ["Œ", "Ö", "Ó", "Ò", "Ô", "Õ", "Ō", "Ŏ"]
    lps["C"] = ["Č", "Ç"]
    lps["a"] = ["æ", "ä", "å", "á", "à", "â", "ã", "ȧ", "ā"]
    lps["E"] = ["Ë", "É", "È", "Ê", "Ẽ", "Ė", "Ē", "Ĕ", "Ę"]
    lps["N"] = ["Ŋ"]
    lps["g"] = ["ĝ", "ḡ", "ǧ", "ǥ"]
    lps["U"] = ["Ü", "Ú", "Ù", "Û", "Ũ", "Ū", "Ŭ"]
    lps["i"] = ["ï", "í", "ì", "î", "ĩ", "ī", "ĭ"]
    lps["z"] = ["ž", "ʒ", "ǯ"]
    lps["o"] = ["œ", "ö", "ó", "ò", "ô", "õ", "ō", "ŏ"]
    lps["I"] = ["Ï", "Í", "Ì", "Î", "Ĩ", "Ī", "Ĭ"]
    lps["Y"] = ["Ý", "Ỳ", "Ŷ", "Ẏ", "Ȳ"]
    lps["y"] = ["ý", "ỳ", "ŷ", "ẏ", "ȳ"]
    lps["T"] = ["Ŧ", "Þ"]
    return lps
}

func generatedConfig() -> [String: String] {
    var o: [String:String] = [:]
    o["space"] = "space"
    o["return"] = "return"
    return o
}