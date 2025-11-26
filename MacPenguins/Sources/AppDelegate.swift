//
//  AppDelegate.swift
//  MacPenguins
//
//  Created by MacPenguins on 26/11/2024.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    private var macPenguinsService: MacPenguinsService?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize the main service
        macPenguinsService = MacPenguinsService()

        // Start the penguin service
        macPenguinsService?.start()

        // Hide dock icon since we're a background service
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Clean shutdown
        macPenguinsService?.stop()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Don't terminate when windows close (we're a background service)
        return false
    }
}