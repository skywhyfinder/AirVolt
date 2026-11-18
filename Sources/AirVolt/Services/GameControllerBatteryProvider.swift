import Foundation
import GameController

public final class GameControllerBatteryProvider {
    public static let shared = GameControllerBatteryProvider()

    private var onUpdate: (([PeripheralDevice]) -> Void)?

    private init() {
        setupListeners()
    }

    public func start(onUpdate: @escaping ([PeripheralDevice]) -> Void) {
        self.onUpdate = onUpdate
        GCController.shouldMonitorBackgroundEvents = true
        GCController.startWirelessControllerDiscovery {
            // Background discovery
        }
        pollControllers()
    }

    private func setupListeners() {
        NotificationCenter.default.addObserver(
            forName: .GCControllerDidConnect,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.pollControllers()
        }

        NotificationCenter.default.addObserver(
            forName: .GCControllerDidDisconnect,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.pollControllers()
        }
    }

    public func pollControllers() {
        var devices: [PeripheralDevice] = []

        let controllers = GCController.controllers()
        for (index, controller) in controllers.enumerated() {
            let vendor = controller.vendorName ?? "Gamepad"
            let id = "gamecontroller_\(controller.vendorName ?? "unknown")_\(index)"
            
            var batteryLevel = 100
            var isCharging = false

            if let battery = controller.battery {
                batteryLevel = Int(battery.batteryLevel * 100)
                isCharging = (battery.batteryState == .charging || battery.batteryState == .full)
            } else {
                // If controller doesn't report battery via GCController.battery,
                // we treat as connected with default or 100%
                batteryLevel = 100
            }

            let device = PeripheralDevice(
                id: id,
                name: vendor,
                type: .gamepad,
                connection: .bluetooth,
                battery: BatteryState(percent: batteryLevel, isCharging: isCharging),
                vendor: detectVendor(from: vendor),
                model: vendor
            )
            devices.append(device)
        }

        onUpdate?(devices)
    }

    private func detectVendor(from name: String) -> String {
        let lower = name.lowercased()
        if lower.contains("flydigi") || lower.contains("vader") || lower.contains("apex") {
            return "Flydigi"
        } else if lower.contains("8bitdo") {
            return "8BitDo"
        } else if lower.contains("dualsense") || lower.contains("dualshock") || lower.contains("sony") || lower.contains("playstation") {
            return "Sony"
        } else if lower.contains("xbox") {
            return "Microsoft"
        } else if lower.contains("gamesir") {
            return "GameSir"
        } else if lower.contains("machenike") {
            return "Machenike"
        } else if lower.contains("nintendo") || lower.contains("switch") || lower.contains("joy-con") {
            return "Nintendo"
        }
        return "Generic Gamepad"
    }
}
