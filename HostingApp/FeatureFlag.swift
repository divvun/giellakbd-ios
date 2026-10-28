//
//  FeatureFlag.swift
//  HostingApp
//
//  Created by Brendan Molloy on 2020-10-29.
//  Copyright © 2020 Apple. All rights reserved.
//

import Foundation

public class FeatureFlag {
    static var userDictionary = true

    /// Shows the "Debug Testing" screen in debug and TestFlight builds, never in App Store builds.
    static var debugTesting: Bool {
        #if DEBUG
        return true
        #else
        // TestFlight installs carry a sandbox receipt; App Store installs do not.
        return Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
        #endif
    }

    private init() { fatalError() }
}
