//
//  SimpleWindowManager.swift
//  MacPenguins - Simplified version without Objective-C dependencies
//
//  Created by MacPenguins on 26/11/2024.
//

import Foundation
import CoreGraphics
import AppKit

struct SimpleWindow {
    let id: CGWindowID
    let bounds: CGRect
    let level: Int
    let ownerName: String
    let windowName: String
    let isOnScreen: Bool
}

class SimpleWindowManager {

    // Callbacks
    var onWindowsChanged: (() -> Void)?
    var onSpaceChanged: (() -> Void)?

    // State
    private var isMonitoring = false
    private var lastWindowList: [SimpleWindow] = []
    private var monitoringTimer: Timer?

    // MARK: - Public Interface

    func startMonitoring() {
        guard !isMonitoring else { return }

        lastWindowList = getCurrentSpaceWindows()

        // Use timer-based monitoring
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }

        isMonitoring = true
        print("SimpleWindowManager started monitoring")
    }

    func stopMonitoring() {
        guard isMonitoring else { return }

        monitoringTimer?.invalidate()
        monitoringTimer = nil

        isMonitoring = false
        print("SimpleWindowManager stopped monitoring")
    }

    func getAllWindows() -> [SimpleWindow] {
        return getWindowsFromCGAPI()
    }

    func getVisibleWindows() -> [SimpleWindow] {
        return getAllWindows().filter { window in
            window.isOnScreen &&
            window.bounds.width > 50 &&
            window.bounds.height > 50 &&
            window.level >= 0 && window.level < 20
        }
    }

    func getCurrentSpaceWindows() -> [SimpleWindow] {
        // For now, just return visible windows
        // In a full implementation, this would filter by current space
        return getVisibleWindows()
    }

    func getAllDisplayBounds() -> [CGRect] {
        return NSScreen.screens.map { $0.frame }
    }

    func getCombinedDisplayBounds() -> CGRect {
        let screens = NSScreen.screens
        guard !screens.isEmpty else { return CGRect.zero }

        var combinedBounds = screens[0].frame
        for screen in screens.dropFirst() {
            combinedBounds = combinedBounds.union(screen.frame)
        }
        return combinedBounds
    }

    // MARK: - Private Methods

    private func getWindowsFromCGAPI() -> [SimpleWindow] {
        guard let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            return []
        }

        var windows: [SimpleWindow] = []

        for windowDict in windowList {
            guard let windowID = windowDict[kCGWindowNumber as String] as? CGWindowID,
                  let boundsDict = windowDict[kCGWindowBounds as String] as? [String: Any] else {
                continue
            }

            var bounds = CGRect.zero
            CGRectMakeWithDictionaryRepresentation(boundsDict as CFDictionary, &bounds)

            let window = SimpleWindow(
                id: windowID,
                bounds: bounds,
                level: windowDict[kCGWindowLayer as String] as? Int ?? 0,
                ownerName: windowDict[kCGWindowOwnerName as String] as? String ?? "Unknown",
                windowName: windowDict[kCGWindowName as String] as? String ?? "",
                isOnScreen: windowDict[kCGWindowIsOnscreen as String] as? Bool ?? false
            )

            windows.append(window)
        }

        return windows
    }

    private func checkForChanges() {
        let currentWindows = getCurrentSpaceWindows()

        if windowListsAreDifferent(currentWindows, lastWindowList) {
            lastWindowList = currentWindows
            DispatchQueue.main.async { [weak self] in
                self?.onWindowsChanged?()
            }
        }
    }

    private func windowListsAreDifferent(_ list1: [SimpleWindow], _ list2: [SimpleWindow]) -> Bool {
        if list1.count != list2.count {
            return true
        }

        let dict1 = Dictionary(uniqueKeysWithValues: list1.map { ($0.id, $0) })
        let dict2 = Dictionary(uniqueKeysWithValues: list2.map { ($0.id, $0) })

        if dict1.keys != dict2.keys {
            return true
        }

        for (windowID, window1) in dict1 {
            guard let window2 = dict2[windowID] else { return true }

            if !window1.bounds.equalTo(window2.bounds) {
                return true
            }
        }

        return false
    }
}

// MARK: - CGRect Extension

extension CGRect {
    func equalTo(_ other: CGRect) -> Bool {
        return abs(origin.x - other.origin.x) < 1.0 &&
               abs(origin.y - other.origin.y) < 1.0 &&
               abs(size.width - other.size.width) < 1.0 &&
               abs(size.height - other.size.height) < 1.0
    }
}