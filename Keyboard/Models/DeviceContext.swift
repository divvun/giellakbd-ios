import DeviceKit
import UIKit

/// Centralized source of truth for device type, size, and orientation detection
/// Wraps DeviceKit's Device to provide additional computed properties
struct DeviceContext {
    let device: Device
    let isLandscape: Bool
    /// Size of the screen the keyboard is on, in the current interface orientation.
    /// `.zero` when unknown, which only happens in tests.
    let screenSize: CGSize

    init(device: Device, isLandscape: Bool, screenSize: CGSize = .zero) {
        self.device = device
        self.isLandscape = isLandscape
        self.screenSize = screenSize
    }

    // MARK: - Device Property Accessors

    var isPad: Bool { device.isPad }
    var isPhone: Bool { device.isPhone }

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

    // MARK: - Trait Collection Helpers

    /// Check if trait collection represents a true iPad app (not iPhone app on iPad)
    func shouldUseIPadLayout(traitCollection: UITraitCollection) -> Bool {
        isPad && traitCollection.userInterfaceIdiom == .pad
    }

    /// Check if this is an iPhone app running on iPad in compatibility mode
    func isIPhoneAppRunningOnIPad(traitCollection: UITraitCollection) -> Bool {
        isPad && traitCollection.userInterfaceIdiom == .phone
    }

    // MARK: - Factory

    /// The context for the screen `view` is currently shown on.
    ///
    /// Reads the view's window scene rather than `UIScreen.main`: on devices with more than one built-in
    /// display, such as iPhone Duo, `UIScreen.main` stays on one display while the keyboard can be on another.
    /// The scene's screen bounds follow the current interface orientation.
    /// Falls back to `UIScreen.main` until the view is in a window.
    static func current(in view: UIView?) -> DeviceContext {
        let screenSize = view?.window?.windowScene?.screen.bounds.size ?? UIScreen.main.bounds.size
        return DeviceContext(
            device: Device.current,
            isLandscape: screenSize.width > screenSize.height,
            screenSize: screenSize
        )
    }

    /// Context without a view. Prefer `current(in:)` whenever orientation or screen size matter.
    static var current: DeviceContext {
        current(in: nil)
    }
}
