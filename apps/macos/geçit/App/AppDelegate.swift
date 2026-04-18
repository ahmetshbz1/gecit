import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let model = AppModel()
    private var statusItem: NSStatusItem?
    private var onboardingController: OnboardingWindowController?
    private var dashboardController: DashboardWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        if model.onboardingCompleted {
            NSApp.setActivationPolicy(.accessory)
            launchMainApp()
        } else {
            showOnboarding()
        }
    }

    private func launchMainApp() {
        setupStatusBar()
        model.refresh()
    }

    private func showOnboarding() {
        NSApp.setActivationPolicy(.regular)
        let controller = OnboardingWindowController(model: model) { [weak self] in
            self?.onboardingController?.close()
            self?.onboardingController = nil
            NSApp.setActivationPolicy(.accessory)
            self?.launchMainApp()
            self?.showDashboard(nil)
        }
        onboardingController = controller
        controller.show()
        NSApp.activate(ignoringOtherApps: true)
    }

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "shield.lefthalf.filled", accessibilityDescription: "geçit")
            button.imagePosition = .imageLeading
            button.title = " geçit"
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Paneli Aç", action: #selector(showDashboard), keyEquivalent: "o"))
        menu.addItem(NSMenuItem(title: "Başlat", action: #selector(startEngine), keyEquivalent: "s"))
        menu.addItem(NSMenuItem(title: "Durdur", action: #selector(stopEngine), keyEquivalent: "d"))
        menu.addItem(NSMenuItem(title: "Temizle", action: #selector(cleanupEngine), keyEquivalent: "c"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Çıkış", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem?.menu = menu
    }

    @objc private func showDashboard(_ sender: Any?) {
        if dashboardController == nil {
            dashboardController = DashboardWindowController(model: model)
        }
        dashboardController?.show()
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func startEngine() {
        model.start()
    }

    @objc private func stopEngine() {
        model.stop()
    }

    @objc private func cleanupEngine() {
        model.cleanup()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
