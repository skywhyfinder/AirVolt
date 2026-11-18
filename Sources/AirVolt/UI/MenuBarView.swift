import SwiftUI

public struct MenuBarView: View {
    @ObservedObject var monitor = BatteryMonitor.shared

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.badge.automatic.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.cyan)

                    Text("AirVolt")
                        .font(.system(size: 15, weight: .bold, design: .rounded))

                    if monitor.demoMode {
                        Text("DEMO")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .cornerRadius(4)
                    }
                }

                Spacer()

                HStack(spacing: 12) {
                    // Demo Mode switch button
                    Button(action: {
                        monitor.toggleDemoMode()
                    }) {
                        Image(systemName: monitor.demoMode ? "sparkles.rectangle.stack.fill" : "sparkles.rectangle.stack")
                            .font(.system(size: 13))
                            .foregroundColor(monitor.demoMode ? .orange : .secondary)
                    }
                    .buttonStyle(.plain)
                    .help(monitor.demoMode ? "Выключить демонстрационный режим" : "Включить демонстрационный режим (показ образцов мыши, геймпада Flydigi, наушников)")

                    // Refresh button
                    Button(action: {
                        monitor.refreshAll()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 13, weight: .medium))
                            .rotationEffect(.degrees(monitor.isScanning ? 360 : 0))
                            .animation(monitor.isScanning ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: monitor.isScanning)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Обновить список устройств")

                    // Settings button
                    Button(action: {
                        monitor.showingPreferences.toggle()
                    }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(monitor.showingPreferences ? .primary : .secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Настройки")
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Divider()

            if monitor.showingPreferences {
                PreferencesView()
            } else {
                // Device List
                if monitor.devices.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 34))
                            .foregroundColor(.secondary.opacity(0.5))
                            .padding(.top, 24)

                        Text("Беспроводные устройства не найдены")
                            .font(.system(.subheadline, weight: .semibold))

                        Text("Подключите мышь, клавиатуру, геймпад (Bluetooth или 2.4G свисток) или наушники к Mac.\n\nИли нажмите на значок ✨ вверху для предпросмотра.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)

                        Button(action: {
                            monitor.toggleDemoMode()
                        }) {
                            Text("Показать пример (Демо-режим)")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top, 4)
                        .padding(.bottom, 24)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(monitor.devices) { device in
                                DeviceRowView(device: device)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                    }
                    .frame(maxHeight: 280)
                }
            }

            Divider()

            // Footer
            HStack {
                Text(formattedLastUpdate)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)

                Spacer()

                Button("Выход") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
        }
        .frame(width: 350)
    }

    private var formattedLastUpdate: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return "Обновлено: \(formatter.string(from: monitor.lastRefreshed))"
    }
}
