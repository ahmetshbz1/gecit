import AppKit
import SwiftUI

@MainActor
final class DashboardWindowController: NSWindowController {
    init(model: AppModel) {
        let hosting = NSHostingController(rootView: ContentView(model: model))
        let window = NSWindow(contentViewController: hosting)
        window.title = "geçit"
        window.setContentSize(NSSize(width: 760, height: 600))
        window.center()
        window.styleMask = [.titled, .closable, .miniaturizable, .fullSizeContentView]
        super.init(window: window)
        shouldCascadeWindows = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func show() {
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
    }
}
