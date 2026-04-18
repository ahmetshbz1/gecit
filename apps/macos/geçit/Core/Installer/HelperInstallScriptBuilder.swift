import Foundation

struct HelperInstallScriptBuilder {
    func render(daemonURL: String, plistURL: String, binaryURL: String) -> String {
        """
        #!/bin/bash
        set -euo pipefail
        mkdir -p "/Library/Application Support/Gecit"
        install -m 755 "\(daemonURL)" "\(AppPaths.helperScriptPath)"
        install -m 755 "\(binaryURL)" "\(AppPaths.installedBinaryPath)"
        install -m 644 "\(plistURL)" "\(AppPaths.helperPlistPath)"
        echo "\(AppPaths.helperVersion)" > "\(AppPaths.helperVersionPath)"
        mkdir -p "\(AppPaths.sharedDirectory)"
        chmod 777 "\(AppPaths.sharedDirectory)"
        touch "\(AppPaths.commandFile)" "\(AppPaths.logFile)"
        chmod 666 "\(AppPaths.commandFile)" "\(AppPaths.logFile)"
        launchctl bootout system/\(AppPaths.helperIdentifier) >/dev/null 2>&1 || true
        launchctl bootstrap system "\(AppPaths.helperPlistPath)"
        launchctl kickstart -k system/\(AppPaths.helperIdentifier)
        """
    }
}
