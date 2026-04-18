import AppKit
import SwiftUI

@MainActor
final class OnboardingWindowController: NSWindowController {
    private let onComplete: () -> Void

    init(model: AppModel, onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
        let view = OnboardingView(model: model, onComplete: onComplete)
        let hosting = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: hosting)
        window.title = "geçit Kurulum"
        window.setContentSize(NSSize(width: 720, height: 520))
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
