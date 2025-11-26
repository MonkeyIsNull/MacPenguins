//
//  main.swift
//  MacPenguins
//
//  Created by MacPenguins on 26/11/2024.
//

import Foundation
import AppKit

print("Starting MacPenguins...")

// Create and configure the application
let app = NSApplication.shared

// Set up as background app (no dock icon)
app.setActivationPolicy(.accessory)

// Create a simple delegate to handle app lifecycle
class SimpleAppDelegate: NSObject, NSApplicationDelegate {
    private var service: MacPenguinsService?

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("MacPenguins launched!")

        // Create and start the service
        service = MacPenguinsService()
        service?.start()

        print("MacPenguins service started. Press Ctrl+C to quit.")
    }

    func applicationWillTerminate(_ notification: Notification) {
        print("MacPenguins shutting down...")
        service?.stop()
    }
}

// Set the delegate
let delegate = SimpleAppDelegate()
app.delegate = delegate

// Run the app
app.run()