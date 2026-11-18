import Foundation
import SwiftUI
import Combine

public final class BatteryMonitor: ObservableObject {
    public static let shared = BatteryMonitor()

    @Published public var devices: [PeripheralDevice] = []
    @Published public var isScanning: Bool = false
    @Published public var lastRefreshed: Date = Date()
    @Published public var demoMode: Bool = false
    @Published public var showingPreferences: Bool = false
    @Published public var launchAtLogin: Bool = LaunchAtLoginManager.shared.isEnabled

    // Settings
    @AppStorage("alertThreshold") public var alertThreshold: Int = 20
    @AppStorage("showPercentagesInMenuBar") public var showPercentagesInMenuBar: Bool = true
    @AppStorage("showIconsInMenuBar") public var showIconsInMenuBar: Bool = true
    @AppStorage("menuBarMode") public var menuBarMode: String = "all" // "all", "lowest", "iconOnly"

    private var pollTimer: AnyCancellable?
    private var iokitDevices: [PeripheralDevice] = []
    private var gameControllerDevices: [PeripheralDevice] = []
    private var bluetoothDevices: [PeripheralDevice] = []
    private var powerSourceDevices: [PeripheralDevice] = []

    private init() {
        start()
    }

    public func start() {
        // Start GameController provider
        GameControllerBatteryProvider.shared.start { [weak self] gcList in
            DispatchQueue.main.async {
                self?.gameControllerDevices = gcList
                self?.combineAndPublish()
            }
        }

        // Start IOKit HID provider
        IOKitHIDBatteryProvider.shared.start { [weak self] hidList in
            DispatchQueue.main.async {
                self?.iokitDevices = hidList
                self?.combineAndPublish()
            }
        }

        // Refresh initially
        refreshAll()

        // Setup timer every 15 seconds
        pollTimer = Timer.publish(every: 15, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refreshAll()
            }
    }

    public func refreshAll() {
        isScanning = true

        // 1. Refresh Power Sources
        self.powerSourceDevices = PowerSourceBatteryProvider.shared.fetchDevices()

        // 2. Refresh Game Controllers
        GameControllerBatteryProvider.shared.pollControllers()

        // 3. Refresh Bluetooth
        BluetoothBatteryProvider.shared.fetchDevices { [weak self] btList in
            guard let self = self else { return }
            self.bluetoothDevices = btList
            self.combineAndPublish()
            self.isScanning = false
            self.lastRefreshed = Date()
        }
    }

    public func toggleDemoMode() {
        demoMode.toggle()
        combineAndPublish()
    }

    public func updateLaunchAtLogin(_ enabled: Bool) {
        launchAtLogin = enabled
        LaunchAtLoginManager.shared.setEnabled(enabled)
    }

    private func combineAndPublish() {
        if demoMode {
            devices = [
                PeripheralDevice(
                    id: "demo_mouse",
                    name: "Attack Shark X3",
                    type: .mouse,
                    connection: .wireless24G,
                    battery: BatteryState(percent: 88, isCharging: false),
                    vendor: "Attack Shark",
                    model: "X3 Wireless"
                ),
                PeripheralDevice(
                    id: "demo_gamepad",
                    name: "Flydigi VADER3",
                    type: .gamepad,
                    connection: .bluetooth,
                    battery: BatteryState(percent: 64, isCharging: false),
                    vendor: "Flydigi",
                    model: "Vader 3 Pro"
                ),
                PeripheralDevice(
                    id: "demo_headset",
                    name: "AirPods Max (Danny)",
                    type: .headset,
                    connection: .bluetooth,
                    battery: BatteryState(percent: 18, isCharging: false),
                    vendor: "Apple",
                    model: "AirPods Max"
                ),
                PeripheralDevice(
                    id: "demo_keyboard",
                    name: "Keychron K2 Pro",
                    type: .keyboard,
                    connection: .wireless24G,
                    battery: BatteryState(percent: 95, isCharging: true),
                    vendor: "Keychron",
                    model: "K2 Pro"
                )
            ]
            return
        }

        var map: [String: PeripheralDevice] = [:]

        // Merge in order of priority: IOKit HID -> GameController -> Bluetooth -> PowerSource
        for dev in powerSourceDevices {
            map[normalizedKey(dev)] = dev
        }

        for dev in bluetoothDevices {
            map[normalizedKey(dev)] = dev
        }

        for dev in gameControllerDevices {
            map[normalizedKey(dev)] = dev
        }

        for dev in iokitDevices {
            map[normalizedKey(dev)] = dev
        }

        let combined = Array(map.values).sorted { lhs, rhs in
            if lhs.type != rhs.type {
                return lhs.type.rawValue < rhs.type.rawValue
            }
            return lhs.battery.percent < rhs.battery.percent
        }

        self.devices = combined

        // Check notifications
        NotificationService.shared.checkAndNotify(devices: combined, threshold: alertThreshold)
    }

    private func normalizedKey(_ dev: PeripheralDevice) -> String {
        let clean = dev.name.lowercased()
            .replacingOccurrences(of: "wireless", with: "")
            .replacingOccurrences(of: "controller", with: "")
            .replacingOccurrences(of: "bluetooth", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return "\(dev.type.rawValue)_\(clean)"
    }

    public var menuBarTitle: String {
        if devices.isEmpty {
            return "⚡"
        }

        switch menuBarMode {
        case "iconOnly":
            return "⚡"
        case "lowest":
            if let lowest = devices.min(by: { $0.battery.percent < $1.battery.percent }) {
                let charge = lowest.battery.isCharging ? "⚡" : ""
                return "\(lowest.type.unicodeEmoji) \(lowest.battery.percent)%\(charge)"
            }
            return "⚡"
        default: // "all"
            let parts = devices.prefix(3).map { dev in
                let charge = dev.battery.isCharging ? "⚡" : ""
                if showPercentagesInMenuBar {
                    return "\(dev.type.unicodeEmoji) \(dev.battery.percent)%\(charge)"
                } else {
                    return "\(dev.type.unicodeEmoji)\(charge)"
                }
            }
            return parts.joined(separator: "  ")
        }
    }
}
