import DeviceKit
import UIKit

struct DeviceContext {
    let idiom: UIUserInterfaceIdiom
    let screenInches: CGFloat
    let isLandscape: Bool

    // MARK: - Basic Device Type

    var isPhone: Bool { idiom == .phone }
    var isPad: Bool { idiom == .pad }

    // MARK: - iPad Size Categories

    var isMiniIPad: Bool {
        isPad && screenInches < 9
    }

    var isMediumIPad: Bool {
        isPad && !isMiniIPad && !isLargeIPad
    }

    var isLargeIPad: Bool {
        isPad && screenInches >= 12
    }

    // MARK: - Orientation-Specific iPad Categories

    var isLargeLandscape: Bool {
        isLargeIPad && isLandscape
    }

    var isSmallOrMediumLandscape: Bool {
        (isMiniIPad || isMediumIPad) && isLandscape
    }

    // MARK: - Factory

    static func current() -> DeviceContext {
        DeviceContext(
            idiom: UIDevice.current.userInterfaceIdiom,
            screenInches: UIScreen.sizeInches,
            isLandscape: UIScreen.main.isDeviceLandscape
        )
    }
}

// MARK: - Trait Collection Helpers

/// Check if trait collection represents a true iPad app (not iPhone app on iPad)
func shouldUseIPadLayout(traitCollection: UITraitCollection) -> Bool {
    Device.current.isPad && traitCollection.userInterfaceIdiom == .pad
}

/// Check if this is an iPhone app running on iPad in compatibility mode
func isIPhoneAppRunningOnIPad(traitCollection: UITraitCollection) -> Bool {
    Device.current.isPad && traitCollection.userInterfaceIdiom == .phone
}
