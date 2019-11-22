import Foundation
import UIKit
import UIDeviceComplete

class SystemKeys {
    static func systemKeyRowsForCurrentDevice(spaceName: String, returnName: String, traits: UITraitCollection) -> [KeyDefinition] {
        var keys = [KeyDefinition]()
        
        let isIPad = UIDevice.current.dc.deviceFamily == .iPad &&
            traits.userInterfaceIdiom == .pad
        
        // Left side of space bar
        if !UIDevice.current.dc.deviceModel.hasNotch {
            if isIPad && (UIDevice.current.dc.screenSize.sizeInches ?? Screen.maxSupportedInches) > 10.0 {
                keys.append(KeyDefinition(type: .keyboard, size: CGSize(width: 1.25, height: 1.0)))
                keys.append(KeyDefinition(type: .symbols, size: CGSize(width: 1.25, height: 1.0)))
            } else {
                keys.append(KeyDefinition(type: .symbols, size: CGSize(width: 1.25, height: 1.0)))
                keys.append(KeyDefinition(type: .keyboard, size: CGSize(width: 1.25, height: 1.0)))
            }
        } else if !isIPad {
            keys.append(KeyDefinition(type: .symbols, size: CGSize(width: 2.5, height: 1.0)))
        } else {
            keys.append(KeyDefinition(type: .symbols))
        }
        keys.append(KeyDefinition(type: .spacebar(name: spaceName), size: CGSize(width: 5.0, height: 1.0)))
        
        // Right of spacebar
        if isIPad{
            keys.append(KeyDefinition(type: .symbols, size: CGSize(width: 1.25, height: 1.0)))
            keys.append(KeyDefinition(type: .keyboardMode, size: CGSize(width: 1.25, height: 1.0)))
        } else {
            keys.append(KeyDefinition(type: .returnkey(name: returnName), size: CGSize(width: 2.5, height: 1.0)))
        }

        return keys
    }
}

extension Array where Element == [KeyDefinition] {
    mutating func platformize(page: KeyboardPage, spaceName: String, returnName: String, traits: UITraitCollection) {
        append(SystemKeys.systemKeyRowsForCurrentDevice(spaceName: spaceName, returnName: returnName, traits: traits))
    }

    func splitAndBalanceSpacebar() -> [[KeyDefinition]] {
        var copy = self
        for (i, row) in copy.enumerated() {
            var splitPoint = row.count / 2
            var length: CGFloat = 0.0
            for (keyIndex, key) in row.enumerated() {
                length += key.size.width
                if case .spacebar = key.type {
                    let splitSpace = KeyDefinition(type: key.type, size: CGSize(width: key.size.width / 2.0, height: key.size.height))
                    copy[i].remove(at: keyIndex)

                    copy[i].insert(splitSpace, at: keyIndex)
                    copy[i].insert(splitSpace, at: keyIndex)
                    splitPoint = keyIndex + 1
                }
            }

            while splitPoint != (copy[i].count / 2) {
                if splitPoint > copy[i].count / 2 {
                    copy[i].append(KeyDefinition(type: .spacer, size: CGSize(width: 0.0, height: 1.0)))
                } else {
                    copy[i].insert(KeyDefinition(type: .spacer, size: CGSize(width: 0.0, height: 1.0)), at: 0)
                }
            }
        }
        return copy
    }
}
