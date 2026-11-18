import AppKit
import SwiftUI

public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusMenuController: StatusMenuController?

    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as accessory app without dock icon
        NSApp.setActivationPolicy(.accessory)

        statusMenuController = StatusMenuController()
        NotificationService.shared.requestAuthorization()
    }
}
