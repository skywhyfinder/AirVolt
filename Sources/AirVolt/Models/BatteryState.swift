import Foundation
import SwiftUI

public struct BatteryState: Codable, Equatable {
    public var percent: Int
    public var isCharging: Bool
    public var isAsleep: Bool

    public init(percent: Int, isCharging: Bool = false, isAsleep: Bool = false) {
        self.percent = max(0, min(100, percent))
        self.isCharging = isCharging
        self.isAsleep = isAsleep
    }

    public var isLow: Bool {
        return percent <= 20 && !isCharging
    }

    public var isCritical: Bool {
        return percent <= 10 && !isCharging
    }

    public var statusColor: Color {
        if isCharging {
            return .cyan
        }
        if percent <= 10 {
            return .red
        }
        if percent <= 25 {
            return .orange
        }
        if percent <= 50 {
            return .yellow
        }
        return .green
    }

    public var statusDescription: String {
        if isCharging {
            return "Заряжается ⚡"
        }
        if isAsleep {
            return "Спит"
        }
        if isCritical {
            return "Критический заряд"
        }
        if isLow {
            return "Низкий заряд"
        }
        return "В норме"
    }
}
