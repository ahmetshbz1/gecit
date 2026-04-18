import AppKit
import Combine
import Foundation
import SwiftUI

enum Page {
    case main
    case logs
    case settings
}

@MainActor
final class AppModel: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()
    static let dohPresets = SettingsStore.dohPresets

    let settings: SettingsStore
    let runtime: RuntimeStore
    private var cancellables = Set<AnyCancellable>()

    init(settings: SettingsStore? = nil, runtime: RuntimeStore? = nil) {
        self.settings = settings ?? SettingsStore()
        self.runtime = runtime ?? RuntimeStore()

        self.runtime.objectWillChange
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    var settingsFakeTTL: Int {
        get { settings.fakeTTL }
        set { settings.fakeTTL = newValue }
    }

    var settingsDoHEnabled: Bool {
        get { settings.doHEnabled }
        set { settings.doHEnabled = newValue }
    }

    var settingsDoHUpstream: String {
        get { settings.doHUpstream }
        set { settings.doHUpstream = newValue }
    }

    var settingsInterface: String {
        get { settings.interface }
        set { settings.interface = newValue }
    }

    var settingsPorts: String {
        get { settings.ports }
        set { settings.ports = newValue }
    }

    var helperInstalled: Bool {
        get { runtime.helperInstalled }
        set { runtime.helperInstalled = newValue }
    }

    var onboardingCompleted: Bool {
        get { runtime.onboardingCompleted }
        set { runtime.onboardingCompleted = newValue }
    }

    var status: GecitStatus {
        get { runtime.status }
        set { runtime.status = newValue }
    }

    var logs: String {
        get { runtime.logs }
        set { runtime.logs = newValue }
    }

    var installError: String? {
        get { runtime.installError }
        set { runtime.installError = newValue }
    }

    var currentPage: Page {
        get { runtime.currentPage }
        set { runtime.currentPage = newValue }
    }

    func installHelper() {
        runtime.installHelper()
    }

    func start() {
        runtime.start(with: settings)
    }

    func stop() {
        runtime.stop()
    }

    func cleanup() {
        runtime.cleanup()
    }

    func refresh() {
        runtime.refresh()
    }

    func startObserving() {
        runtime.startObserving()
    }

    func stopObserving() {
        runtime.stopObserving()
    }

    func resetTransientState() {
        runtime.resetTransientState()
    }

    var statusTitle: String {
        runtime.statusTitle
    }

    var canStart: Bool {
        runtime.canStart
    }

    var needsHelperReinstall: Bool {
        runtime.needsHelperReinstall
    }

    var canStop: Bool {
        runtime.canStop
    }

    var primaryActionTitle: String {
        runtime.primaryActionTitle
    }

    var primaryActionSymbol: String {
        runtime.primaryActionSymbol
    }

    func performPrimaryAction() {
        runtime.performPrimaryAction { [weak self] in
            self?.start()
        }
    }

    func resetSettingsToDefault() {
        settings.resetToDefault()
    }

    var currentSettingsSummary: String {
        settings.summary
    }
}
