# gecit

Native macOS desktop client and UI for the upstream `gecit` DPI bypass engine.

This fork keeps the original cross-platform engine and adds a productized macOS experience on top: onboarding, helper installation, menu bar controls, settings UI, and log viewing. The bundled `gecit` binary is executed as a managed subprocess/helper rather than being reimplemented in Swift.

[Türkçe README](README.tr.md)

## What this repo is

This repository has two layers:

1. **Upstream runtime engine** — the original `gecit` CLI and networking implementation
2. **macOS app client** — a native Swift menu bar app that installs, configures, starts, stops, and monitors the bundled runtime

If you only want the underlying engine, you can still use the CLI directly.
If you want a polished macOS experience, use the native app in `apps/macos`.

## What the macOS app does

The macOS app is not a separate DPI engine. It is a native desktop control plane for the bundled `gecit-darwin-arm64` binary.

It provides:

- first-run onboarding
- privileged helper installation
- menu bar popover UI
- start / stop / cleanup controls
- TTL / DoH / interface / ports settings
- runtime status and recent logs

At runtime, the app installs a helper under `/Library/Application Support/Gecit`, runs the bundled binary, and exchanges control/status data through shared files.

## Repository layout

- `cmd/gecit` — upstream CLI entrypoint
- `pkg/` — upstream networking, TUN, fake packet injection, DNS, capture, raw socket, and platform code
- `apps/macos` — native Swift macOS app
- `bin/` — compiled binaries

## Choose your entrypoint

### Option 1: Use the CLI directly

```bash
sudo gecit run
```

The CLI/runtime behavior remains the same as the upstream project:

- **Linux**: eBPF sock_ops, no proxy, no traffic redirection
- **macOS/Windows**: TUN-based transparent proxy
- built-in DoH DNS resolver
- fake TLS ClientHello injection for DPI desynchronization

### Option 2: Use the native macOS app

Open the Xcode project in `apps/macos`, build the app, then complete onboarding from the native UI.

The app installs the helper once, then lets you manage the runtime from a menu bar interface instead of manually running CLI commands.

For app-specific details, see [apps/macos/README.md](apps/macos/README.md).

## How the underlying engine works

```
App connects to target:443
    ↓
gecit intercepts the connection
  Linux:  eBPF sock_ops fires
  macOS/Windows: TUN device captures packet, gVisor netstack terminates TCP
    ↓
Fake ClientHello with SNI "www.google.com" sent with low TTL
    ↓
Fake reaches DPI → DPI records benign SNI → allows connection
Fake expires before server → server never sees it
    ↓
Real ClientHello passes through → DPI is already desynchronized
```

Some ISPs inspect the TLS ClientHello SNI field to identify and block specific domains. `gecit` sends a fake ClientHello with a different SNI and a low TTL before the real one. The DPI processes the fake and lets the connection through, while the fake packet expires before reaching the server.

The engine also includes a built-in DoH DNS resolver to bypass DNS poisoning.

## Requirements

| | Linux | macOS | Windows |
|---|---|---|---|
| **OS** | Kernel 5.10+ | macOS 12+ | Windows 10+ |
| **Privileges** | root / sudo | root / sudo | Administrator |
| **Dependencies** | None | None | [Npcap](https://npcap.com) |

## Build

### Build the runtime binaries

```bash
make gecit-linux-amd64
make gecit-linux-arm64
make gecit-darwin-arm64
make gecit-darwin-amd64
make gecit-windows-amd64
```

### Build the macOS app

Open:

```text
apps/macos/geçit.xcodeproj
```

The macOS app expects the bundled runtime binary and installs it during helper setup.

## CLI usage

```bash
# Default
sudo gecit run

# Use Google DoH
sudo gecit run --doh-upstream google

# Multiple upstreams
sudo gecit run --doh-upstream cloudflare,quad9

# Custom DoH URL
sudo gecit run --doh-upstream https://8.8.8.8/dns-query

# Custom TTL
sudo gecit run --fake-ttl 12

# Check system capabilities
sudo gecit status

# Restore system settings after a crash
sudo gecit cleanup
```

## CLI flags

| Flag | Default | Description |
|------|---------|-------------|
| `--doh-upstream` | `cloudflare` | DoH upstream preset name or URL; comma-separated for fallback |
| `--fake-ttl` | `8` | TTL for fake packets |
| `--mss` | `40` | TCP MSS for ClientHello fragmentation on Linux |
| `--ports` | `443` | Target destination ports |
| `--interface` | auto | Network interface |
| `-v` | off | Verbose logging |

## Platform differences

| | Linux | macOS | Windows |
|---|---|---|---|
| **Engine** | eBPF sock_ops | TUN + gVisor netstack | TUN + gVisor netstack |
| **Fake injection** | Raw socket | Raw socket | Raw socket via Npcap |
| **DNS bypass** | DoH + `/etc/resolv.conf` | DoH + `networksetup` | DoH + `netsh` |
| **Root required** | Yes | Yes | Yes |

## FAQ

**Is this repo mainly a macOS app now?**
Yes. The main differentiation of this fork is the native macOS client experience. The upstream CLI/runtime is still present and still does the actual network work.

**Does the macOS app replace the runtime engine?**
No. It manages the bundled binary as a subprocess/helper.

**Is this a VPN?**
No. There is no remote tunnel or anonymity layer. Traffic still goes directly to the internet.

**Does this hide my IP address?**
No. It only targets DPI/DNS-based blocking behavior.

## License

GPL-3.0. See [LICENSE](LICENSE).

Copyright (c) 2026 Bora Tanrikulu <me@bora.sh>
