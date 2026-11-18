import Foundation
import UserNotifications

public final class NotificationService {
    public static let shared = NotificationService()

    private var notifiedDeviceMap: [String: Date] = [:]
    private let cooldownInterval: TimeInterval = 1800 // 30 minutes cooldown before repeating alert

    private init() {
        requestAuthorization()
    }

    public func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    public func checkAndNotify(devices: [PeripheralDevice], threshold: Int = 20) {
        let now = Date()

        for device in devices {
            // Only notify if battery is low and NOT currently charging
            if device.battery.percent <= threshold && !device.battery.isCharging {
                if let lastNotified = notifiedDeviceMap[device.id], now.timeIntervalSince(lastNotified) < cooldownInterval {
                    continue
                }

                sendLowBatteryAlert(for: device)
                notifiedDeviceMap[device.id] = now
            } else if device.battery.percent > threshold + 10 || device.battery.isCharging {
                // Reset notification if recharged or plugged in
                notifiedDeviceMap.removeValue(forKey: device.id)
            }
        }
    }

    private func sendLowBatteryAlert(for device: PeripheralDevice) {
        let content = UNMutableNotificationContent()
        content.title = "Низкий заряд батареи: \(device.name)"
        content.body = "Осталось всего \(device.battery.percent)%. Поставьте устройство на зарядку."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "low_batt_\(device.id)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { _ in }
    }
}
