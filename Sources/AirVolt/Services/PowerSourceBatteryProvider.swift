import Foundation
import IOKit.ps

public final class PowerSourceBatteryProvider {
    public static let shared = PowerSourceBatteryProvider()

    private init() {}

    public func fetchDevices() -> [PeripheralDevice] {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] else {
            return []
        }

        var results: [PeripheralDevice] = []

        for source in sources {
            guard let desc = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] else {
                continue
            }

            let transportType = desc[kIOPSTransportTypeKey] as? String ?? ""
            // We only want external peripherals (Bluetooth or USB), not the internal MacBook battery
            if transportType == kIOPSInternalType {
                continue
            }

            let name = desc[kIOPSNameKey] as? String ?? "External Device"
            let current = desc[kIOPSCurrentCapacityKey] as? Int ?? 0
            let max = desc[kIOPSMaxCapacityKey] as? Int ?? 100
            let isCharging = (desc[kIOPSIsChargingKey] as? Bool) ?? false

            let percent = max > 0 ? (current * 100 / max) : current
            let id = "ps_\(name.replacingOccurrences(of: " ", with: "_"))"

            let type = detectType(name: name)

            let device = PeripheralDevice(
                id: id,
                name: name,
                type: type,
                connection: transportType == "Bluetooth" ? .bluetooth : .usb,
                battery: BatteryState(percent: percent, isCharging: isCharging),
                vendor: "Apple",
                model: name
            )
            results.append(device)
        }

        return results
    }

    private func detectType(name: String) -> DeviceType {
        let lower = name.lowercased()
        if lower.contains("mouse") {
            return .mouse
        } else if lower.contains("keyboard") {
            return .keyboard
        } else if lower.contains("trackpad") {
            return .trackpad
        } else if lower.contains("headset") || lower.contains("headphones") {
            return .headset
        }
        return .other
    }
}
