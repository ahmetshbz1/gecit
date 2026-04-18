# gecit macOS app

This directory contains the native Swift macOS client for `gecit`.

The app is a menu bar control plane for the bundled runtime binary. It does not implement DPI bypass itself; it installs and manages the packaged `gecit-darwin-arm64` executable.

## Responsibilities

- present onboarding UI
- request privileged helper installation
- install launchd helper assets
- start / stop / cleanup the runtime
- persist user settings
- display status and tail logs in a native popover UI

## Runtime model

The app uses a split model:

1. **Swift UI layer** — menu bar app, onboarding, settings, logs, status
2. **Privileged helper/runtime layer** — installed binary and helper assets under `/Library/Application Support/Gecit`

Control and state move through shared files:

- command file: `/Users/Shared/GecitHelper/command`
- status file: `/Users/Shared/GecitHelper/status.json`
- log file: `/Users/Shared/GecitHelper/gecit.log`

## Main components

- `geçit/App/AppDelegate.swift` — app lifecycle, status bar item, popover, onboarding flow
- `geçit/Core/AppModel.swift` — UI-facing application model
- `geçit/Core/RuntimeStore.swift` — runtime state, polling, primary actions
- `geçit/Core/GecitHelperInstaller.swift` — helper installation pipeline
- `geçit/Core/GecitControlService.swift` — command/status/log file IO
- `geçit/Core/SettingsStore.swift` — persisted settings
- `geçit/Features/*` — onboarding, main page, logs page, settings page

## Installation flow

On first launch, the app shows onboarding and installs the helper with administrator privileges.

The installer:

- writes helper scripts and launchd plist to a temporary directory
- copies the bundled `gecit-darwin-arm64` binary
- marks assets executable
- runs the installation script with elevated privileges

After installation, the app can start and stop the runtime from the menu bar.

## Settings exposed by the UI

- fake TTL
- DoH enabled/disabled
- DoH upstream preset or custom value
- network interface override
- destination ports

These settings are converted into CLI arguments before the runtime starts.

## Build

Open the Xcode project:

```text
geçit.xcodeproj
```

The app expects the runtime binary to be bundled as an app resource.

## Positioning

This app is the main product differentiation of the fork.

The upstream repository provides the underlying network engine; this directory turns that engine into a macOS-native user experience with installation, lifecycle management, and UI.