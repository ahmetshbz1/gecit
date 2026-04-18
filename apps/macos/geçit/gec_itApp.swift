//
//  gec_itApp.swift
//  geçit
//
//  Created by Ahmet on 18.04.2026.
//

import SwiftUI

@main
struct gec_itApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}
