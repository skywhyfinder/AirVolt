import AppKit
import SwiftUI
import Combine

public final class StatusMenuController: NSObject {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var monitorCancellable: AnyCancellable?
    private let monitor = BatteryMonitor.shared

    public override init() {
        super.init()
        setupStatusItem()
        setupPopover()
        observeMonitor()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.target = self
            button.action = #selector(togglePopover)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            updateButtonContent()
        }
    }

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 350, height: 320)
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(rootView: MenuBarView())
    }

    private func observeMonitor() {
        monitorCancellable = monitor.$devices
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateButtonContent()
            }
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    public func updateButtonContent() {
        guard let button = statusItem.button else { return }

        let title = monitor.menuBarTitle
        button.title = title

        // If title is just the bolt icon, provide a clean fallback SF Symbol
        if title == "⚡" {
            let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
            if let img = NSImage(systemSymbolName: "bolt.batteryblock.fill", accessibilityDescription: "AirVolt")?.withSymbolConfiguration(config) {
                img.isTemplate = true
                button.image = img
                button.imagePosition = .imageOnly
            } else {
                button.title = "⚡"
            }
        } else {
            button.image = nil
            button.imagePosition = .noImage
        }
    }
}
