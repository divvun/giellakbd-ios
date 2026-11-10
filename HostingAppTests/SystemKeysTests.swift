@testable import BaseKeyboard
import Testing
import UIKit

/// The bottom row must include a globe key exactly when the system asks for one via
/// `UIInputViewController.needsInputModeSwitchKey`, whatever hardware the device has.
@MainActor
struct SystemKeysTests {
    private let phoneTraits = UITraitCollection(userInterfaceIdiom: .phone)
    private let padTraits = UITraitCollection(traitsFrom: [
        UITraitCollection(userInterfaceIdiom: .pad),
        UITraitCollection(horizontalSizeClass: .regular)
    ])

    private func bottomRow(device: DeviceContext,
                           traits: UITraitCollection,
                           needsInputModeSwitchKey: Bool) -> [KeyDefinition] {
        SystemKeys.systemKeyRowsForCurrentDevice(
            spaceName: "space",
            returnName: "return",
            traits: traits,
            needsInputModeSwitchKey: needsInputModeSwitchKey,
            device: device
        )
    }

    private func types(_ row: [KeyDefinition]) -> [KeyType] {
        row.map(\.type)
    }

    @Test("iPhone Duo shows a globe key when the system asks for one")
    func iPhoneDuoShowsGlobe() {
        let row = bottomRow(device: DeviceContext(device: .iPhoneDuo, isLandscape: false), traits: phoneTraits, needsInputModeSwitchKey: true)
        #expect(types(row) == [.symbols, .keyboard, .spacebar(name: "space"), .returnkey(name: "return")])
    }

    @Test("Face ID iPhone relies on the system globe below the keyboard")
    func faceIDiPhoneHidesGlobe() {
        let row = bottomRow(device: DeviceContext(device: .iPhone17, isLandscape: false), traits: phoneTraits, needsInputModeSwitchKey: false)
        #expect(!types(row).contains(.keyboard))
        #expect(row.first?.type == .symbols)
        #expect(row.first?.size.width == 2.5)
    }

    @Test("No globe key when only one keyboard is enabled")
    func singleKeyboardHidesGlobe() {
        let row = bottomRow(device: DeviceContext(device: .iPhoneSE3, isLandscape: false), traits: phoneTraits, needsInputModeSwitchKey: false)
        #expect(!types(row).contains(.keyboard))
    }

    @Test("Home button iPhone shows a globe key")
    func homeButtoniPhoneShowsGlobe() {
        let row = bottomRow(device: DeviceContext(device: .iPhoneSE3, isLandscape: false), traits: phoneTraits, needsInputModeSwitchKey: true)
        #expect(types(row).prefix(2) == [.symbols, .keyboard])
    }

    @Test("Large iPad puts the globe key before the symbols key")
    func largeiPadOrdersGlobeFirst() {
        let row = bottomRow(device: DeviceContext(device: .iPadPro13M5, isLandscape: false), traits: padTraits, needsInputModeSwitchKey: true)
        #expect(types(row).prefix(2) == [.keyboard, .symbols])
    }
}
