import Foundation

public enum ConnectionType: String, Codable {
    case bluetooth = "Bluetooth"
    case wireless24G = "2.4G Wireless"
    case usb = "USB"
    case internalPower = "Internal"

    public var sfSymbol: String {
        switch self {
        case .bluetooth:
            return "wave.3.right"
        case .wireless24G:
            return "antenna.radiowaves.left.and.right"
        case .usb:
            return "cable.connector"
        case .internalPower:
            return "poweroutlet.type.b"
        }
    }
}
