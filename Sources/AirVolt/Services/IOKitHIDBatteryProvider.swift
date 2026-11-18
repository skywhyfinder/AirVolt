import Foundation
import IOKit
import IOKit.hid

public final class IOKitHIDBatteryProvider {
    public static let shared = IOKitHIDBatteryProvider()

    private var manager: IOHIDManager?
    private var cachedDevices: [String: PeripheralDevice] = [:]
    private var onUpdate: (([PeripheralDevice]) -> Void)?

    private init() {}

    public func start(onUpdate: @escaping ([PeripheralDevice]) -> Void) {
        self.onUpdate = onUpdate

        manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        guard let manager = manager else { return }

        IOHIDManagerSetDeviceMatching(manager, nil)
        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        
        let matchingCallback: IOHIDDeviceCallback = { context, result, sender, device in
            let provider = Unmanaged<IOKitHIDBatteryProvider>.fromOpaque(context!).takeUnretainedValue()
            provider.handleDeviceConnected(device)
        }

        let removalCallback: IOHIDDeviceCallback = { context, result, sender, device in
            let provider = Unmanaged<IOKitHIDBatteryProvider>.fromOpaque(context!).takeUnretainedValue()
            provider.handleDeviceRemoved(device)
        }

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        IOHIDManagerRegisterDeviceMatchingCallback(manager, matchingCallback, selfPtr)
        IOHIDManagerRegisterDeviceRemovalCallback(manager, removalCallback, selfPtr)

        IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        scanAllDevices()
    }

    public func scanAllDevices() {
        guard let manager = manager,
              let devices = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice> else {
            return
        }

        for dev in devices {
            inspectDevice(dev)
        }

        notifyUpdate()
    }

    private func handleDeviceConnected(_ device: IOHIDDevice) {
        inspectDevice(device)
        notifyUpdate()
    }

    private func handleDeviceRemoved(_ device: IOHIDDevice) {
        let key = deviceKey(device)
        cachedDevices.removeValue(forKey: key)
        notifyUpdate()
    }

    private func deviceKey(_ device: IOHIDDevice) -> String {
        let vid = IOHIDDeviceGetProperty(device, kIOHIDVendorIDKey as CFString) as? Int ?? 0
        let pid = IOHIDDeviceGetProperty(device, kIOHIDProductIDKey as CFString) as? Int ?? 0
        let name = IOHIDDeviceGetProperty(device, kIOHIDProductKey as CFString) as? String ?? "Unknown"
        let serial = IOHIDDeviceGetProperty(device, kIOHIDSerialNumberKey as CFString) as? String ?? ""
        return "hid_\(String(format: "%04X_%04X", vid, pid))_\(name)_\(serial)"
    }

    private func inspectDevice(_ device: IOHIDDevice) {
        let name = IOHIDDeviceGetProperty(device, kIOHIDProductKey as CFString) as? String ?? ""
        if name.isEmpty || name.lowercased().contains("apple internal") || name.lowercased().contains("keyboard backlight") {
            return
        }

        let vid = IOHIDDeviceGetProperty(device, kIOHIDVendorIDKey as CFString) as? Int ?? 0
        let pid = IOHIDDeviceGetProperty(device, kIOHIDProductIDKey as CFString) as? Int ?? 0
        let transport = IOHIDDeviceGetProperty(device, kIOHIDTransportKey as CFString) as? String ?? "USB"

        // 1. Direct IOHID property check
        if let batt = IOHIDDeviceGetProperty(device, "BatteryPercent" as CFString) as? Int {
            saveDevice(device: device, name: name, vid: vid, pid: pid, transport: transport, battery: batt, isCharging: false)
            return
        }

        // 2. Check HID elements for Battery Strength (Usage Page 0x06, Usage 0x20 or Page 0x01/0x0C)
        if let elements = IOHIDDeviceCopyMatchingElements(device, nil, IOOptionBits(kIOHIDOptionsTypeNone)) as? [IOHIDElement] {
            for element in elements {
                let elemUsagePage = IOHIDElementGetUsagePage(element)
                let elemUsage = IOHIDElementGetUsage(element)

                // Battery Strength usage in Generic Device Controls (0x06:0x20) or Consumer (0x0C:0x20)
                if (elemUsagePage == 0x06 && elemUsage == 0x20) || (elemUsagePage == 0x01 && elemUsage == 0x20) {
                    var valueRef = Unmanaged<IOHIDValue>.fromOpaque(UnsafeRawPointer(bitPattern: 1)!)
                    if IOHIDDeviceGetValue(device, element, &valueRef) == KERN_SUCCESS {
                        let val = valueRef.takeUnretainedValue()
                        let intVal = IOHIDValueGetIntegerValue(val)
                        if intVal > 0 && intVal <= 100 {
                            saveDevice(device: device, name: name, vid: vid, pid: pid, transport: transport, battery: intVal, isCharging: false)
                            return
                        }
                    }
                }
            }
        }

        // 3. Vendor-specific 2.4GHz Dongle checks
        checkVendorProtocols(device: device, name: name, vid: vid, pid: pid, transport: transport)
    }

    private func checkVendorProtocols(device: IOHIDDevice, name: String, vid: Int, pid: Int, transport: String) {
        // Logitech (0x046D) HID++
        if vid == 0x046D {
            if let batt = queryLogitechBattery(device) {
                saveDevice(device: device, name: name, vid: vid, pid: pid, transport: "2.4G Wireless", battery: batt.percent, isCharging: batt.isCharging)
                return
            }
        }

        // Razer (0x1532)
        if vid == 0x1532 {
            if let batt = queryRazerBattery(device) {
                saveDevice(device: device, name: name, vid: vid, pid: pid, transport: "2.4G Wireless", battery: batt.percent, isCharging: batt.isCharging)
                return
            }
        }

        // Chinese 2.4G Mice / Dongles (Attack Shark, Darmoshark, VGN, Ajazz, Delux, CompX, Telink, Rongyuan)
        // Common VIDs: 0x248A, 0x258A, 0x093A, 0x2C22, 0x30FA, 0x19FF, 0x320F, 0x3554
        let chineseDongleVIDs: Set<Int> = [0x248A, 0x258A, 0x093A, 0x2C22, 0x30FA, 0x19FF, 0x320F, 0x3554]
        if chineseDongleVIDs.contains(vid) || isGenericChineseGamingGear(name: name) {
            if let batt = queryGenericCompXReport(device) {
                saveDevice(device: device, name: name, vid: vid, pid: pid, transport: "2.4G Wireless", battery: batt.percent, isCharging: batt.isCharging)
                return
            }
        }
    }

    private func isGenericChineseGamingGear(name: String) -> Bool {
        let lower = name.lowercased()
        return lower.contains("attack shark") || lower.contains("darmoshark") || lower.contains("vgn") ||
               lower.contains("vxe") || lower.contains("ajazz") || lower.contains("delux") ||
               lower.contains("mchose") || lower.contains("zaopin") || lower.contains("incott") ||
               lower.contains("compx") || lower.contains("wireless receiver")
    }

    private func saveDevice(device: IOHIDDevice, name: String, vid: Int, pid: Int, transport: String, battery: Int, isCharging: Bool) {
        let key = deviceKey(device)
        let type = detectType(name: name, vid: vid)
        let vendor = detectVendor(name: name, vid: vid)
        let connType: ConnectionType = transport.lowercased().contains("bluetooth") ? .bluetooth : (transport.lowercased().contains("2.4") ? .wireless24G : .wireless24G)

        let dev = PeripheralDevice(
            id: key,
            name: name.isEmpty ? "\(vendor) Device" : name,
            type: type,
            connection: connType,
            battery: BatteryState(percent: battery, isCharging: isCharging),
            vendor: vendor,
            model: name
        )

        cachedDevices[key] = dev
    }

    private func notifyUpdate() {
        let list = Array(cachedDevices.values)
        onUpdate?(list)
    }

    // MARK: - Vendor Protocol Helpers

    private func queryLogitechBattery(_ device: IOHIDDevice) -> (percent: Int, isCharging: Bool)? {
        var report = [UInt8](repeating: 0, count: 7)
        var reportLength = report.count
        let res = IOHIDDeviceGetReport(device, kIOHIDReportTypeFeature, 0x10, &report, &reportLength)
        if res == KERN_SUCCESS && reportLength >= 4 {
            let batt = Int(report[2])
            if batt > 0 && batt <= 100 {
                let charging = (report[3] & 0x01) != 0
                return (batt, charging)
            }
        }
        return nil
    }

    private func queryRazerBattery(_ device: IOHIDDevice) -> (percent: Int, isCharging: Bool)? {
        var report = [UInt8](repeating: 0, count: 90)
        var length = report.count
        let res = IOHIDDeviceGetReport(device, kIOHIDReportTypeFeature, 0x00, &report, &length)
        if res == KERN_SUCCESS && length >= 10 {
            let batt = Int(report[9])
            if batt > 0 && batt <= 100 {
                let charging = report[10] == 1
                return (batt, charging)
            }
        }
        return nil
    }

    private func queryGenericCompXReport(_ device: IOHIDDevice) -> (percent: Int, isCharging: Bool)? {
        for reportId in [0x04, 0x08, 0x09, 0x00] {
            var report = [UInt8](repeating: 0, count: 64)
            var length = report.count
            let res = IOHIDDeviceGetReport(device, kIOHIDReportTypeFeature, reportId, &report, &length)
            if res == KERN_SUCCESS && length >= 6 {
                let batt1 = Int(report[4])
                let batt2 = Int(report[5])
                if batt1 > 0 && batt1 <= 100 {
                    let isCharging = (report[3] & 0x01) != 0
                    return (batt1, isCharging)
                } else if batt2 > 0 && batt2 <= 100 {
                    let isCharging = (report[3] & 0x01) != 0
                    return (batt2, isCharging)
                }
            }
        }
        return nil
    }

    private func detectType(name: String, vid: Int) -> DeviceType {
        let lower = name.lowercased()
        if lower.contains("mouse") || lower.contains("shark") || lower.contains("m800") || lower.contains("m900") || lower.contains("dragonfly") {
            return .mouse
        } else if lower.contains("keyboard") || lower.contains("keychron") || lower.contains("aula") {
            return .keyboard
        } else if lower.contains("headset") || lower.contains("headphone") || lower.contains("void") || lower.contains("cloud") || lower.contains("arctis") {
            return .headset
        } else if lower.contains("controller") || lower.contains("gamepad") || lower.contains("vader") || lower.contains("apex") || lower.contains("8bitdo") {
            return .gamepad
        }
        return .other
    }

    private func detectVendor(name: String, vid: Int) -> String {
        switch vid {
        case 0x046D: return "Logitech"
        case 0x1532: return "Razer"
        case 0x1038: return "SteelSeries"
        case 0x1B1C: return "Corsair"
        case 0x0951, 0x03F0: return "HyperX"
        case 0x248A, 0x258A: return "Attack Shark / CompX"
        case 0x320F: return "Darmoshark"
        case 0x3554: return "VGN / VXE"
        case 0x2C22: return "Ajazz"
        default:
            let lower = name.lowercased()
            if lower.contains("flydigi") || lower.contains("vader") || lower.contains("apex") {
                return "Flydigi"
            } else if lower.contains("8bitdo") {
                return "8BitDo"
            } else if lower.contains("gamesir") {
                return "GameSir"
            } else if lower.contains("keychron") {
                return "Keychron"
            }
            return "Wireless Peripheral"
        }
    }
}
