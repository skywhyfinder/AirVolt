import SwiftUI

public struct DeviceRowView: View {
    public let device: PeripheralDevice

    public var body: some View {
        HStack(spacing: 12) {
            // Icon squircle
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(iconBackgroundColor.opacity(0.15))
                    .frame(width: 38, height: 38)

                Image(systemName: device.type.sfSymbol)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(iconBackgroundColor)
            }

            // Info details
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(device.name)
                        .font(.system(.body, design: .default, weight: .semibold))
                        .lineLimit(1)

                    if let vendor = device.vendor, !vendor.isEmpty {
                        Text(vendor)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1.5)
                            .background(Color.secondary.opacity(0.12))
                            .cornerRadius(4)
                            .foregroundColor(.secondary)
                    }
                }

                HStack(spacing: 6) {
                    HStack(spacing: 3) {
                        Image(systemName: device.connection.sfSymbol)
                            .font(.system(size: 9))
                        Text(device.connection.rawValue)
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.secondary)

                    Text("•")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.5))

                    Text(device.battery.statusDescription)
                        .font(.system(size: 11))
                        .foregroundColor(device.battery.statusColor)
                }
            }

            Spacer()

            // Battery graphic & percentage
            BatteryLevelView(state: device.battery)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.6))
        )
    }

    private var iconBackgroundColor: Color {
        switch device.type {
        case .mouse:
            return .blue
        case .keyboard:
            return .purple
        case .headset:
            return .orange
        case .gamepad:
            return .green
        case .trackpad:
            return .indigo
        case .other:
            return .secondary
        }
    }
}
