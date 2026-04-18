import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let model = AppModel()
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var eventMonitor: EventMonitor?
    private var onboardingController: OnboardingWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        if model.shouldShowOnboardingOnLaunch {
            showOnboarding()
        } else {
            NSApp.setActivationPolicy(.accessory)
            launchMainApp()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationWillTerminate(_ notification: Notification) {
        eventMonitor?.stop()
        model.stopObserving()
        model.cleanup()
    }

    private func launchMainApp() {
        setupStatusBar()
        setupPopover()
        setupEventMonitor()
        model.refresh()
    }

    private func showOnboarding() {
        NSApp.setActivationPolicy(.regular)
        model.startObserving()
        let controller = OnboardingWindowController(model: model) { [weak self] in
            self?.handleOnboardingCompletion()
        }
        onboardingController = controller
        controller.show()
        NSApp.activate(ignoringOtherApps: true)
    }

    private func handleOnboardingCompletion() {
        onboardingController?.close()
        onboardingController = nil
        NSApp.setActivationPolicy(.accessory)
        launchMainApp()
        showPopover()
    }

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        setupStatusItemButton()
    }

    private func setupStatusItemButton() {
        guard let button = statusItem?.button else { return }
        button.image = NSImage(systemSymbolName: "shield.lefthalf.filled", accessibilityDescription: "geçit")
        button.action = #selector(togglePopover)
        button.target = self
    }

    private func setupPopover() {
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 360, height: 500)
        popover.behavior = .transient
        popover.animates = true
        self.popover = popover
    }

    private func makePopoverContentController() -> NSHostingController<ContentView> {
        NSHostingController(rootView: ContentView(model: model))
    }

    private func setupEventMonitor() {
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self, let popover = self.popover, popover.isShown else { return }
            if let window = popover.contentViewController?.view.window {
                let mouseLocation = NSEvent.mouseLocation
                if window.frame.contains(mouseLocation) {
                    return
                }
            }
            self.closePopover()
        }
    }

    @objc private func togglePopover() {
        guard let popover else { return }
        if popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard let button = statusItem?.button, let popover else { return }
        model.startObserving()
        if popover.contentViewController == nil {
            popover.contentViewController = makePopoverContentController()
        }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        eventMonitor?.start()
        activateAndFocus(popover: popover)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self, weak popover] in
            guard let self, let popover else { return }
            self.activateAndFocus(popover: popover)
        }
    }

    private func activateAndFocus(popover: NSPopover) {
        NSApp.activate(ignoringOtherApps: true)
        popover.contentViewController?.view.window?.makeKeyAndOrderFront(nil)
    }

    private func closePopover() {
        popover?.performClose(nil)
        popover?.contentViewController = nil
        eventMonitor?.stop()
        model.stopObserving()
        model.resetTransientState()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
