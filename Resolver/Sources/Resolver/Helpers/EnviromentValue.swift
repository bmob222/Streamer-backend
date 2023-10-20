import Foundation

@propertyWrapper
public struct EnviromentValue<Value> {

    public init(key: String, defaultValue: Value, container: UserDefaults = .standard) {
        self.key = key
        self.defaultValue = defaultValue
        self.container = container
    }

    public let key: String
    public var defaultValue: Value
    public var container: UserDefaults = .standard

    public var wrappedValue: Value {
        let value = container.string(forKey: key)
        if Value.self == URL.self, let value {
            return URL(string: value) as! Value
        } else  if let value {
            return value as! Value
        } else {
            return defaultValue
        }
    }
}
