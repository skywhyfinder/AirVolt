import Foundation

public struct PeripheralDevice: Identifiable, Codable, Equatable {
    public let id: String
    public var name: String
    public var type: DeviceType
    public var connection: ConnectionType
    public var battery: BatteryState
    public var vendor: String?
    public var model: String?
    public var lastSeen: Date

    public init(
        id: String,
        name: String,
        type: DeviceType,
        connection: ConnectionType,
        battery: BatteryState,
        vendor: String? = nil,
        model: String? = nil,
        lastSeen: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.connection = connection
        self.battery = battery
        self.vendor = vendor
        self.model = model
        self.lastSeen = lastSeen
    }

    public static func == (lhs: PeripheralDevice, rhs: PeripheralDevice) -> Bool {
        return lhs.id == rhs.id &&
               lhs.battery == rhs.battery &&
               lhs.name == rhs.name &&
               lhs.connection == rhs.connection
    }
}
