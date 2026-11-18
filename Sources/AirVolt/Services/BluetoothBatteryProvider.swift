import Foundation

public final class BluetoothBatteryProvider {
    public static let shared = BluetoothBatteryProvider()

    private var isScanning = false

    private init() {}

    public func fetchDevices(completion: @escaping ([PeripheralDevice]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let devices = self.querySystemProfiler()
            DispatchQueue.main.async {
                completion(devices)
            }
        }
    }

    private func querySystemProfiler() -> [PeripheralDevice] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
        process.arguments = ["SPBluetoothDataType", "-json"]

        let pipe = Pipe()
        process.standardOutput = pipe

        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let list = json["SPBluetoothDataType"] as? [[String: Any]] else {
                return []
            }

            var results: [PeripheralDevice] = []

            for entry in list {
                if let connected = entry["device_connected"] as? [[String: Any]] {
                    for item in connected {
                        for (name, details) in item {
                            if let dict = details as? [String: Any] {
                                if let device = parseDevice(name: name, dict: dict) {
                                    results.append(device)
                                }
                            }
                        }
                    }
                }
            }

            return results
        } catch {
            return []
        }
    }

    private func parseDevice(name: String, dict: [String: Any]) -> PeripheralDevice? {
        let address = dict["device_address"] as? String ?? UUID().uuidString
        let minorType = dict["device_minorType"] as? String ?? ""

        // Extract battery level: can be main, left/right, etc.
        var batteryPercent: Int?

        if let main = dict["device_batteryLevelMain"] {
            batteryPercent = parseBatteryValue(main)
        } else if let general = dict["device_batteryLevel"] {
            batteryPercent = parseBatteryValue(general)
        } else if let left = dict["device_batteryPercentLeft"] {
            // For AirPods / TWS earbuds
            batteryPercent = parseBatteryValue(left)
        }

        // Check charging state
        var isCharging = false
        if let chargingStr = dict["device_isCharging"] as? String {
            isCharging = chargingStr.lowercased().contains("yes") || chargingStr.lowercased().contains("true")
        }

        let type = detectType(name: name, minorType: minorType)
        let vendor = detectVendor(name: name)

        // Even if macOS doesn't show battery yet for a connected device, we give it a placeholder or omit
        guard let percent = batteryPercent else {
            // Some generic Bluetooth devices don't report battery via SPBluetooth,
            // but if they are connected, return device if it has battery info
            return nil
        }

        return PeripheralDevice(
            id: "bt_\(address)",
            name: name,
            type: type,
            connection: .bluetooth,
            battery: BatteryState(percent: percent, isCharging: isCharging),
            vendor: vendor,
            model: name
        )
    }

    private func parseBatteryValue(_ value: Any) -> Int? {
        if let intVal = value as? Int {
            return intVal
        }
        if let str = value as? String {
            let digits = str.filter { $0.isNumber }
            return Int(digits)
        }
        return nil
    }

    private func detectType(name: String, minorType: String) -> DeviceType {
        let lower = (name + " " + minorType).lowercased()
        if lower.contains("mouse") || lower.contains("trackball") {
            return .mouse
        } else if lower.contains("keyboard") || lower.contains("keychron") {
            return .keyboard
        } else if lower.contains("headset") || lower.contains("airpods") || lower.contains("buds") || lower.contains("headphones") || lower.contains("beats") || lower.contains("wh-1000") {
            return .headset
        } else if lower.contains("gamepad") || lower.contains("controller") || lower.contains("vader") || lower.contains("apex") || lower.contains("dualsense") || lower.contains("xbox") {
            return .gamepad
        } else if lower.contains("trackpad") {
            return .trackpad
        }
        return .other
    }

    private func detectVendor(name: String) -> String {
        let lower = name.lowercased()
        if lower.contains("apple") || lower.contains("airpods") || lower.contains("magic") {
            return "Apple"
        } else if lower.contains("flydigi") || lower.contains("vader") || lower.contains("apex") {
            return "Flydigi"
        } else if lower.contains("8bitdo") {
            return "8BitDo"
        } else if lower.contains("logitech") || lower.contains("mx master") || lower.contains("g pro") {
            return "Logitech"
        } else if lower.contains("razer") {
            return "Razer"
        } else if lower.contains("sony") || lower.contains("dualsense") {
            return "Sony"
        } else if lower.contains("xbox") || lower.contains("microsoft") {
            return "Microsoft"
        } else if lower.contains("samsung") || lower.contains("galaxy buds") {
            return "Samsung"
        } else if lower.contains("keychron") {
            return "Keychron"
        } else if lower.contains("attack shark") {
            return "Attack Shark"
        } else if lower.contains("darmoshark") {
            return "Darmoshark"
        } else if lower.contains("vgn") || lower.contains("vxe") {
            return "VGN"
        } else if lower.contains("gamesir") {
            return "GameSir"
        }
        return "Bluetooth Peripheral"
    }
}
