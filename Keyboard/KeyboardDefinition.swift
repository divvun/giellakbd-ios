import UIKit
import UIDeviceComplete

public indirect enum TransformTree: Decodable {
    case tree([String: TransformTree])
    case leaf(String)
    
    public init(from decoder: Decoder) throws {
        let d = try decoder.singleValueContainer()
        
        do {
            self = .tree(try d.decode([String: TransformTree].self))
        } catch {
            self = .leaf(try d.decode(String.self))
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
        let d: KeyedDecodingContainer<Keys>
        
        do {
            d = try decoder.container(keyedBy: Keys.self)
        } catch {
            let d = try decoder.singleValueContainer()
            self.id = try d.decode(String.self)
            self.width = 1.0
            self.height = 1.0
            return
        }
        
        self.id = try d.decode(String.self, forKey: .id)
        self.width = (try d.decodeIfPresent(Double.self, forKey: .width)) ?? 1.0
        self.height = (try d.decodeIfPresent(Double.self, forKey: .height)) ?? 1.0
    }
}

enum DeviceVariant: String, Decodable {
    case ipad_9in = "ipad-9in"
    case ipad_12in = "ipad-12in"
    case iphone = "iphone"
    
    static var current: DeviceVariant {
        let family = UIDevice.current.dc.deviceFamily
        
        if family == .iPad {
            if (UIDevice.current.dc.screenSize.sizeInches ?? Screen.maxSupportedInches) < 12.0 {
                return .ipad_9in
            } else {
                return .ipad_12in
            }
        } else {
            return .iphone
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
        case altShift
        case symbols1 = "symbols-1"
        case symbols2 = "symbols-2"
    }
    
    public init(from decoder: Decoder) throws {
        let d = try decoder.container(keyedBy: Keys.self)
        normal = try d.decode([[RawKeyDefinition]].self, forKey: .normal)
        shifted = try d.decode([[RawKeyDefinition]].self, forKey: .shifted)
        alt = try d.decodeIfPresent([[RawKeyDefinition]].self, forKey: .alt)
        altShift = try d.decodeIfPresent([[RawKeyDefinition]].self, forKey: .altShift)
        symbols1 = try d.decodeIfPresent([[RawKeyDefinition]].self, forKey: .symbols1)
        symbols2 = try d.decodeIfPresent([[RawKeyDefinition]].self, forKey: .symbols2)
    }
}

public struct KeyboardDefinition: Decodable {
    let name: String
    let locale: String
    let spaceName: String
    let returnName: String
    
    let deadKeys: [String: [String]]
    let longPress: [String: [String]]
    let transforms: [String: TransformTree]
    
    private(set) var normal: [[KeyDefinition]] = []
    private(set) var shifted: [[KeyDefinition]] = []
    private(set) var symbols1: [[KeyDefinition]] = []
    private(set) var symbols2: [[KeyDefinition]] = []
    
    private enum Keys: String, CodingKey {
        case name
        case locale
        case space
        case `return`
        case deadKeys
        case longPress
        case transforms
        
        case ipad_9in = "ipad-9in"
        case ipad_12in = "ipad-12in"
        case iphone = "iphone"
        
        static var deviceKey: Keys {
            switch DeviceVariant.current {
            case .ipad_12in:
                return .ipad_12in
            case .ipad_9in:
                return .ipad_9in
            case .iphone:
                return .iphone
            }
        }
    }
    
    public init(from decoder: Decoder) throws {
        let d = try decoder.container(keyedBy: Keys.self)
        
        name = try d.decode(String.self, forKey: .name)
        locale = try d.decode(String.self, forKey: .locale)
        spaceName = try d.decode(String.self, forKey: .space)
        returnName = try d.decode(String.self, forKey: .return)
        
        let deadKeysMap: [DeviceVariant: [String: [String]]]
        do {
            if let value = try d.decodeIfPresent([DeviceVariant: [String: [String]]].self, forKey: .deadKeys) {
                deadKeysMap = value
            } else {
                deadKeysMap = [:]
            }
        } catch {
            print(error)
            deadKeysMap = [:]
        }
        
        if let deadKeys = deadKeysMap[DeviceVariant.current] {
            self.deadKeys = deadKeys
        } else {
            self.deadKeys = [:]
        }
        
        do {
            if let value = try d.decodeIfPresent([String: [String]].self, forKey: .longPress) {
                longPress = value
            } else {
                longPress = [:]
            }
        } catch {
            print(error)
            longPress = [:]
        }
        
        do {
            if let value = try d.decodeIfPresent([String: TransformTree].self, forKey: .transforms) {
                transforms = value
            } else {
                transforms = [:]
            }
        } catch {
            print(error)
            transforms = [:]
        }
        
        let mode = try d.decode(RawKeyboardMode.self, forKey: .deviceKey)
        switch DeviceVariant.current {
        case .iphone:
            self.normal = mode.normal.map { $0.map { KeyDefinition(input: $0, spaceName: spaceName, returnName: returnName) } }
            self.shifted = mode.shifted.map { $0.map { KeyDefinition(input: $0, spaceName: spaceName, returnName: returnName) } }
            
            if let symbols1 = mode.symbols1 {
                self.symbols1 = symbols1.map { $0.map { KeyDefinition(input: $0, spaceName: spaceName, returnName: returnName) }}
            }
            if let symbols2 = mode.symbols2 {
                self.symbols2 = symbols2.map { $0.map { KeyDefinition(input: $0, spaceName: spaceName, returnName: returnName) }}
            }
        case .ipad_12in, .ipad_9in:
            let alt = mode.alt ?? []
            let altShift = mode.altShift ?? []
            let symbols1 = mode.symbols1 ?? []
            let symbols2 = mode.symbols2 ?? []
            
            self.normal = zip(mode.normal, alt).map {
                zip($0, $1).map {
                    KeyDefinition(input: $0, alternate: $1.id, spaceName: spaceName, returnName: returnName)
                }
            }
            
            self.shifted = zip(mode.shifted, altShift).map {
                zip($0, $1).map {
                    KeyDefinition(input: $0, alternate: $1.id, spaceName: spaceName, returnName: returnName)
                }
            }
            
            self.symbols1 = zip(symbols1, symbols2).map {
                zip($0, $1).map {
                    return KeyDefinition(input: $0, alternate: $1.id, spaceName: spaceName, returnName: returnName)
                }
            }
            
            self.symbols2 = symbols2.map {
                return $0.map {
                    return KeyDefinition(input: $0, spaceName: spaceName, returnName: returnName)
                }
            }
        }
        
        normal.platformize(page: .normal, spaceName: spaceName, returnName: returnName)
        shifted.platformize(page: .shifted, spaceName: spaceName, returnName: returnName)
        symbols1.platformize(page: .symbols1, spaceName: spaceName, returnName: returnName)
        symbols2.platformize(page: .symbols2, spaceName: spaceName, returnName: returnName)
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
        
        self.normal = normal
        self.shifted = shifted
        self.symbols1 = symbols1
        self.symbols2 = symbols2
    }
    
    static let definitions: [KeyboardDefinition] = {
        let path = Bundle.top.url(forResource: "KeyboardDefinitions", withExtension: "json")!
        let data = try! String(contentsOf: path).data(using: .utf8)!
        return try! JSONDecoder().decode([KeyboardDefinition].self, from: data)
    }()
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
