//
//  WindowManager.swift
//  MacPenguins
//
//  Created by MacPenguins on 26/11/2024.
//

import Foundation
import CoreGraphics
import AppKit

struct Window {
    let id: CGWindowID
    let bounds: CGRect
    let level: Int
    let workspace: Int
    let ownerName: String
    let windowName: String
    let isOnScreen: Bool

    init(from windowInfo: WindowInfo) {
        self.id = windowInfo.windowID
        self.bounds = windowInfo.bounds
        self.level = windowInfo.level
        self.workspace = windowInfo.workspace
        self.ownerName = windowInfo.ownerName
        self.windowName = windowInfo.windowName
        self.isOnScreen = windowInfo.isOnScreen
    }
}

class WindowManager {

    // Callbacks
    var onWindowsChanged: (() -> Void)?
    var onSpaceChanged: (() -> Void)?

    // State
    private var isMonitoring = false
    private var currentSpace: Int = -1
    private var lastWindowList: [Window] = []

    // Window detector
    private let windowDetector = WindowDetector.shared()

    // MARK: - Public Interface

    func startMonitoring() {
        guard !isMonitoring else { return }

        // Get initial state
        currentSpace = windowDetector.getCurrentSpace().intValue
        lastWindowList = getCurrentSpaceWindows()

        // Start monitoring for changes
        windowDetector.startMonitoring { [weak self] in
            self?.checkForChanges()
        }

        // Monitor for workspace changes
        startWorkspaceMonitoring()

        isMonitoring = true
        print("WindowManager started monitoring")
    }

    func stopMonitoring() {
        guard isMonitoring else { return }

        windowDetector.stopMonitoring()
        stopWorkspaceMonitoring()

        isMonitoring = false
        print("WindowManager stopped monitoring")
    }

    func getAllWindows() -> [Window] {
        let windowInfos = windowDetector.getAllWindows()
        return windowInfos.map { Window(from: $0) }
    }

    func getVisibleWindows() -> [Window] {
        let windowInfos = windowDetector.getVisibleWindows()
        return windowInfos.map { Window(from: $0) }
    }

    func getCurrentSpaceWindows() -> [Window] {
        let windowInfos = windowDetector.getWindowsInCurrentSpace()
        return windowInfos.map { Window(from: $0) }
    }

    func getAllSpaces() -> [Int] {
        let spaces = windowDetector.getAllSpaces()
        return spaces.map { $0.intValue }
    }

    func getCurrentSpace() -> Int {
        return windowDetector.getCurrentSpace().intValue
    }

    func getAllDisplayBounds() -> [CGRect] {
        let bounds = windowDetector.getAllDisplayBounds()
        return bounds.map { $0.rectValue }
    }

    func getCombinedDisplayBounds() -> CGRect {
        return windowDetector.getCombinedDisplayBounds()
    }

    // MARK: - Private Methods

    private func checkForChanges() {
        // Check for space changes first
        let newSpace = getCurrentSpace()
        if newSpace != currentSpace {
            currentSpace = newSpace
            lastWindowList = getCurrentSpaceWindows()
            DispatchQueue.main.async { [weak self] in
                self?.onSpaceChanged?()
            }
            return
        }

        // Check for window changes in current space
        let currentWindows = getCurrentSpaceWindows()

        if windowListsAreDifferent(currentWindows, lastWindowList) {
            lastWindowList = currentWindows
            DispatchQueue.main.async { [weak self] in
                self?.onWindowsChanged?()
            }
        }
    }

    private func windowListsAreDifferent(_ list1: [Window], _ list2: [Window]) -> Bool {
        if list1.count != list2.count {
            return true
        }

        // Create dictionaries for efficient comparison
        let dict1 = Dictionary(uniqueKeysWithValues: list1.map { ($0.id, $0) })
        let dict2 = Dictionary(uniqueKeysWithValues: list2.map { ($0.id, $0) })

        if dict1.keys != dict2.keys {
            return true
        }

        // Check for bounds changes
        for (windowID, window1) in dict1 {
            guard let window2 = dict2[windowID] else { return true }

            if !window1.bounds.equalTo(window2.bounds) {
                return true
            }
        }

        return false
    }

    private func startWorkspaceMonitoring() {
        // Monitor for space changes using NSWorkspace
        NotificationCenter.default.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.checkForChanges()
        }
    }

    private func stopWorkspaceMonitoring() {
        NotificationCenter.default.removeObserver(
            self,
            name: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil
        )
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