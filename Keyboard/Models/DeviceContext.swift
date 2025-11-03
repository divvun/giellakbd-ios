import DeviceKit
import UIKit

/// Centralized source of truth for device type, size, and orientation detection
/// Wraps DeviceKit's Device to provide additional computed properties
struct DeviceContext {
    let device: Device
    let isLandscape: Bool

    // MARK: - Device Property Accessors

    /// Access to underlying DeviceKit device for advanced features
    var isPad: Bool { device.isPad }
    var isPhone: Bool { device.isPhone }
    var hasSensorHousing: Bool { device.hasSensorHousing }

    /// Screen diagonal size in inches, with fallback for unknown devices
    var screenInches: CGFloat {
        // Default to maxSupportedInches for legacy reasons
        // TODO: this could be improved to guess screen size based on device bounds
        let maxSupportedInches = 13.0
        return device.diagonal > 0
            ? device.diagonal
            : maxSupportedInches
    }

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

    static var current: DeviceContext {
        DeviceContext(
            device: Device.current,
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
