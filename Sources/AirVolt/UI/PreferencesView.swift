import SwiftUI

public struct PreferencesView: View {
    @ObservedObject var monitor = BatteryMonitor.shared

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Настройки AirVolt")
                .font(.headline)
                .padding(.bottom, 4)

            // Menu Bar Display Mode
            VStack(alignment: .leading, spacing: 8) {
                Text("Отображение в Menu Bar:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Picker("", selection: $monitor.menuBarMode) {
                    Text("Все устройства (до 3)").tag("all")
                    Text("Только с минимальным зарядом").tag("lowest")
                    Text("Только иконка").tag("iconOnly")
                }
                .pickerStyle(.segmented)
            }

            Toggle("Показывать процент заряда в строке меню", isOn: $monitor.showPercentagesInMenuBar)

            Divider()

            // Notification Threshold
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Предупреждать о низком заряде:")
                    Spacer()
                    Text("≤ \(monitor.alertThreshold)%")
                        .font(.system(.body, design: .rounded, weight: .bold))
                        .foregroundColor(.orange)
                }

                Slider(
                    value: Binding(
                        get: { Double(monitor.alertThreshold) },
                        set: { monitor.alertThreshold = Int($0) }
                    ),
                    in: 5...35,
                    step: 5
                )
            }

            Divider()

            // Launch at login
            Toggle("Запускать AirVolt при входе в систему", isOn: Binding(
                get: { monitor.launchAtLogin },
                set: { monitor.updateLaunchAtLogin($0) }
            ))

            // Demo Mode
            Toggle("Режим демонстрации (тестовые устройства)", isOn: Binding(
                get: { monitor.demoMode },
                set: { _ in monitor.toggleDemoMode() }
            ))

            Spacer()
        }
        .padding(18)
        .frame(width: 360, height: 350)
    }
}
