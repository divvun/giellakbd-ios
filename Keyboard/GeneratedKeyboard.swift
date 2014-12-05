// GENERATION STUB.
func generatedKeyboard() -> Keyboard {
    var defaultKeyboard = Keyboard()
    
    var longPresses = ["O": ["Ø", "Ö", "Ò"]];
    
    for key in ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"] {
        var keyModel = Key(.Character)
        keyModel.setLetter(key)
        if let lp = longPresses[key]? {
            keyModel.setUppercaseLongPress(lp)
            keyModel.setLowercaseLongPress(lp)
        }
        defaultKeyboard.addKey(keyModel, row: 0, page: 0)
    }
    
    for key in ["A", "S", "D", "F", "G", "H", "J", "K", "L"] {
        var keyModel = Key(.Character)
        keyModel.setLetter(key)
        defaultKeyboard.addKey(keyModel, row: 1, page: 0)
    }
    
    var keyModel = Key(.Shift)
    defaultKeyboard.addKey(keyModel, row: 2, page: 0)
    
    for key in ["Z", "X", "C", "V", "B", "N", "M"] {
        var keyModel = Key(.Character)
        keyModel.setLetter(key)
        defaultKeyboard.addKey(keyModel, row: 2, page: 0)
    }
    
    return defaultKeyboard
}

func generatedConfig() -> [String: String] {
    return ["space": "space", "return": "return"]
}