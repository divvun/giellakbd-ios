import Foundation
import UIKit
import UIDeviceComplete

class SystemKeys {
    static func systemKeyRowsForCurrentDevice(spaceName: String, returnName: String) -> [KeyDefinition] {
        var keys = [KeyDefinition]()
        
        // Left side of space bar
        if !UIDevice.current.dc.deviceModel.hasNotch {
            if UIDevice.current.dc.isIpad && (UIDevice.current.dc.screenSize.sizeInches ?? Screen.maxSupportedInches) > 10.0 {
                keys.append(KeyDefinition(type: .keyboard, size: CGSize(width: 1.25, height: 1.0)))
                keys.append(KeyDefinition(type: .symbols, size: CGSize(width: 1.25, height: 1.0)))
            } else {
                keys.append(KeyDefinition(type: .symbols, size: CGSize(width: 1.25, height: 1.0)))
                keys.append(KeyDefinition(type: .keyboard, size: CGSize(width: 1.25, height: 1.0)))
            }
        } else if UIDevice.current.dc.deviceFamily != .iPad {
            keys.append(KeyDefinition(type: .symbols, size: CGSize(width: 2.5, height: 1.0)))
        } else {
            keys.append(KeyDefinition(type: .symbols))
        }
        keys.append(KeyDefinition(type: .spacebar(name: spaceName), size: CGSize(width: 5.0, height: 1.0)))
        
        // Right of spacebar
        if UIDevice.current.dc.deviceFamily == .iPad {
            keys.append(KeyDefinition(type: .symbols, size: CGSize(width: 1.25, height: 1.0)))
            keys.append(KeyDefinition(type: .keyboardMode, size: CGSize(width: 1.25, height: 1.0)))
        } else {
            keys.append(KeyDefinition(type: .returnkey(name: returnName), size: CGSize(width: 2.5, height: 1.0)))
        }

        return keys
    }
}
