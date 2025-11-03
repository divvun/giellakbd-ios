import UIKit
import DeviceKit

public indirect enum TransformTree: Codable {
    case tree([String: TransformTree])
    case leaf(String)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        do {
            self = .tree(try container.decode([String: TransformTree].self))
        } catch {
            self = .leaf(try container.decode(String.self))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case let .tree(value):
            try container.encode(value)
        case let .leaf(value):
            try container.encode(value)
        }
    }
}

struct RawKeyDefinition: Decodable {
    let id: String
    let width: Double
    let height: Double

    private enum Keys: CodingKey {
        case id
        case width
        case height
    }

    public init(from decoder: Decoder) throws {
        let container: KeyedDecodingContainer<Keys>

        do {
            container = try decoder.container(keyedBy: Keys.self)
        } catch {
            let container = try decoder.singleValueContainer()
            self.id = try container.decode(String.self)
            self.width = 1.0
            self.height = 1.0
            return
        }

        self.id = try container.decode(String.self, forKey: .id)
        self.width = (try container.decodeIfPresent(Double.self, forKey: .width)) ?? 1.0
        self.height = (try container.decodeIfPresent(Double.self, forKey: .height)) ?? 1.0
    }
}

enum DeviceVariant: String, Decodable {
    case ipad9in = "ipad-9in"
    case ipad12in = "ipad-12in"
    case iphone = "iphone"

    static func from(traits: UITraitCollection) -> DeviceVariant {
        if shouldUseIPadLayout(traitCollection: traits) {
            if UIScreen.sizeInches < 12.0 {
                return .ipad9in
            } else {
                return .ipad12in
            }
        } else {
            return .iphone
        }
    }

    func displayName() -> String {
        switch self {
        case .ipad9in: return "iPad 9\""
        case .ipad12in: return "iPad 12\""
        case .iphone: return "iPhone"
        }
    }
}

public struct RawKeyboardMode: Decodable {
    let normal: [[RawKeyDefinition]]
    let shifted: [[RawKeyDefinition]]
    let alt: [[RawKeyDefinition]]?
    let altShift: [[RawKeyDefinition]]?
    let symbols1: [[RawKeyDefinition]]?
    let symbols2: [[RawKeyDefinition]]?

    private enum Keys: String, CodingKey {
        case normal
        case shifted
        case alt
        case altShift = "alt+shift"
        case symbols1 = "symbols-1"
        case symbols2 = "symbols-2"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        normal = try container.decode([[RawKeyDefinition]].self, forKey: .normal)
        shifted = try container.decode([[RawKeyDefinition]].self, forKey: .shifted)
        alt = try container.decodeIfPresent([[RawKeyDefinition]].self, forKey: .alt)
        altShift = try container.decodeIfPresent([[RawKeyDefinition]].self, forKey: .altShift)
        symbols1 = try container.decodeIfPresent([[RawKeyDefinition]].self, forKey: .symbols1)
        symbols2 = try container.decodeIfPresent([[RawKeyDefinition]].self, forKey: .symbols2)
    }
}

struct RawKeyboardDefinition: Decodable {
    let name: String
    let locale: String
    let spaceName: String
    let returnName: String

    let deadKeys: [String: [String: [String]]]?
    let longPress: [String: [String]]?
    let transforms: [String: TransformTree]?

    let ipad9in: RawKeyboardMode?
    let ipad12in: RawKeyboardMode?
    let iphone: RawKeyboardMode

    private enum Keys: String, CodingKey {
        case name
        case locale
        case space
        case `return`
        case deadKeys
        case longPress
        case transforms

        case ipad9in = "ipad-9in"
        case ipad12in = "ipad-12in"
        case iphone = "iphone"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)

        name = try container.decode(String.self, forKey: .name)
        locale = try container.decode(String.self, forKey: .locale)
        spaceName = try container.decode(String.self, forKey: .space)
        returnName = try container.decode(String.self, forKey: .return)

        do {
            if let value = try container.decodeIfPresent([String: [String: [String]]].self, forKey: .deadKeys) {
                deadKeys = value
            } else {
                deadKeys = [:]
            }
        } catch {
            print(error)
            deadKeys = [:]
        }

        do {
            if let value = try container.decodeIfPresent([String: [String]].self, forKey: .longPress) {
                longPress = value
            } else {
                longPress = [:]
            }
        } catch {
            print(error)
            longPress = [:]
        }

        do {
            if let value = try container.decodeIfPresent([String: TransformTree].self, forKey: .transforms) {
                transforms = value
            } else {
                transforms = [:]
            }
        } catch {
            print(error)
            transforms = [:]
        }

        iphone = try container.decode(RawKeyboardMode.self, forKey: .iphone)
        ipad9in = try? container.decode(RawKeyboardMode.self, forKey: .ipad9in)
        ipad12in = try? container.decode(RawKeyboardMode.self, forKey: .ipad12in)
    }
}

enum KeyboardFeature {
    // This is used for deciding whether or not tapping a banner item will
    // result in insertion of a space. Subject to change.
    case compounding
}

public struct KeyboardDefinition: Codable {
    let name: String
    let locale: String
    let spaceName: String
    let returnName: String

    let deadKeys: [String: [String]]
    let longPress: [String: [String]]
    let transforms: [String: TransformTree]

    struct Layout: Codable {
        var normal: [[KeyDefinition]] = []
        var shifted: [[KeyDefinition]] = []
        var symbols1: [[KeyDefinition]] = []
        var symbols2: [[KeyDefinition]] = []
    }

    private(set) var currentDeviceLayout: Layout?

    public var supportsCurrentDevice: Bool {
        return currentDeviceLayout != nil
    }

    // TODO: features should be derived from as-yet-undefined JSON input
    var features: Set<KeyboardFeature> {
        return Set()
    }

    init(fromRaw raw: RawKeyboardDefinition, traits: UITraitCollection) throws {
        let deviceVariant = DeviceVariant.from(traits: traits)

        self.name = raw.name
        self.locale = raw.locale
        self.spaceName = raw.spaceName
        self.returnName = raw.returnName

        self.deadKeys = raw.deadKeys?[deviceVariant.rawValue] ?? [:]
        self.longPress = raw.longPress ?? [:]
        self.transforms = raw.transforms ?? [:]

        let mode: RawKeyboardMode?

        switch deviceVariant {
        case .iphone:
            mode = raw.iphone
        case .ipad9in:
            mode = raw.ipad9in
        case .ipad12in:
            mode = raw.ipad12in
        }

        guard let mode = mode else {
            // There's no keyboard definition for the device with the given traits
            // Don't set the layout property and return
            return
        }

        switch deviceVariant {
        case .iphone:
            self.currentDeviceLayout = Layout(
                normal: keyDefinitionsFromRaw(mode.normal),
                shifted: keyDefinitionsFromRaw(mode.shifted),
                symbols1: keyDefinitionsFromRaw(mode.symbols1 ?? []),
                symbols2: keyDefinitionsFromRaw(mode.symbols2 ?? [])
            )

        case .ipad12in, .ipad9in:
            let alt = mode.alt ?? []
            let altShift = mode.altShift ?? []
            let symbols1 = mode.symbols1 ?? []
            let symbols2 = mode.symbols2 ?? []

            let normal = keyDefinitionsFromRaw(mode.normal, alternates: alt)
            let shifted = keyDefinitionsFromRaw(mode.shifted, alternates: altShift)
            var symbols1Converted: [[KeyDefinition]] = []
            var symbols2Converted: [[KeyDefinition]] = []

            if symbols2.isEmpty {
                symbols1Converted = keyDefinitionsFromRaw(symbols1)
            } else {
                symbols1Converted = keyDefinitionsFromRaw(symbols1, alternates: symbols2)
                symbols2Converted = keyDefinitionsFromRaw(symbols2)
            }

            self.currentDeviceLayout = Layout(normal: normal, shifted: shifted, symbols1: symbols1Converted, symbols2: symbols2Converted)
        }

        currentDeviceLayout!.normal.platformize(page: .normal, spaceName: spaceName, returnName: returnName, traits: traits)
        currentDeviceLayout!.shifted.platformize(page: .shifted, spaceName: spaceName, returnName: returnName, traits: traits)
        currentDeviceLayout!.symbols1.platformize(page: .symbols1, spaceName: spaceName, returnName: returnName, traits: traits)
        currentDeviceLayout!.symbols2.platformize(page: .symbols2, spaceName: spaceName, returnName: returnName, traits: traits)
    }

    private func keyDefinitionsFromRaw(_ rawKeyDefinitions: [[RawKeyDefinition]]) -> [[KeyDefinition]] {
        return rawKeyDefinitions.map { $0.map { KeyDefinition(input: $0, spaceName: spaceName, returnName: returnName) } }
    }

    private func keyDefinitionsFromRaw(_ rawKeyDefinitions: [[RawKeyDefinition]],
                                       alternates: [[RawKeyDefinition]]) -> [[KeyDefinition]] {
        return zip(rawKeyDefinitions, alternates).map {
            zip($0, $1).map {
                KeyDefinition(input: $0, alternate: $1.id, spaceName: spaceName, returnName: returnName)
            }
        }
    }

    public func copy(
        normal: [[KeyDefinition]],
        shifted: [[KeyDefinition]],
        symbols1: [[KeyDefinition]],
        symbols2: [[KeyDefinition]]
    ) -> KeyboardDefinition {
        return KeyboardDefinition(
            other: self, normal: normal, shifted: shifted, symbols1: symbols1, symbols2: symbols2)
    }

    private init(
        other: KeyboardDefinition,
        normal: [[KeyDefinition]],
        shifted: [[KeyDefinition]],
        symbols1: [[KeyDefinition]],
        symbols2: [[KeyDefinition]]
    ) {
        self.name = other.name
        self.locale = other.locale
        self.spaceName = other.spaceName
        self.returnName = other.returnName

        self.deadKeys = other.deadKeys
        self.transforms = other.transforms
        self.longPress = other.longPress

        self.currentDeviceLayout = Layout(
            normal: normal,
            shifted: shifted,
            symbols1: symbols1,
            symbols2: symbols2
        )
    }
}

public enum KeyboardPage {
    case normal
    case shifted
    case capslock
    case symbols1
    case symbols2

    func alternatePage() -> KeyboardPage {
        switch self {
        case .normal, .shifted, .capslock:
            return .symbols1
        default:
            return .symbols2
        }
    }
}
