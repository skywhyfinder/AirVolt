import SwiftUI

public struct BatteryLevelView: View {
    public let state: BatteryState
    public var showText: Bool = true

    public var body: some View {
        HStack(spacing: 6) {
            if showText {
                Text("\(state.percent)%")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundColor(state.statusColor)
            }

            ZStack(alignment: .leading) {
                // Outer battery body
                RoundedRectangle(cornerRadius: 3.5)
                    .stroke(Color.secondary.opacity(0.35), lineWidth: 1.5)
                    .frame(width: 28, height: 14)

                // Battery terminal cap
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.secondary.opacity(0.35))
                    .frame(width: 2, height: 6)
                    .offset(x: 29)

                // Fill level
                let fillWidth = max(2.0, Double(state.percent) / 100.0 * 24.0)
                RoundedRectangle(cornerRadius: 2)
                    .fill(state.statusColor)
                    .frame(width: CGFloat(fillWidth), height: 10)
                    .padding(.leading, 2)

                // Charging bolt icon inside battery
                if state.isCharging {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.4), radius: 1)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .frame(width: 32, height: 14)
        }
    }
}
