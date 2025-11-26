//
//  BasicRenderer.swift
//  MacPenguins - Basic renderer that works with SimplePenguin

import Foundation
import AppKit

class BasicRenderer {

    private var windows: [NSWindow] = []
    private var penguinViews: [UUID: NSView] = [:]

    func setupOverlayWindows() {
        cleanup()

        // Create one simple overlay window that covers the main screen
        let mainScreen = NSScreen.main ?? NSScreen.screens[0]
        let screenFrame = mainScreen.frame

        let overlayWindow = NSWindow(
            contentRect: screenFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        // Configure window to be on top but not interfere
        overlayWindow.level = NSWindow.Level.floating
        overlayWindow.backgroundColor = NSColor.clear
        overlayWindow.isOpaque = false
        overlayWindow.hasShadow = false
        overlayWindow.ignoresMouseEvents = true
        overlayWindow.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]

        // Make sure the window is visible
        overlayWindow.makeKeyAndOrderFront(nil)
        overlayWindow.orderFrontRegardless()

        windows.append(overlayWindow)

        print("✅ Created overlay window covering screen: \(screenFrame)")
    }

    func updatePenguins(_ penguins: [SimplePenguin]) {
        guard let mainWindow = windows.first,
              let contentView = mainWindow.contentView else {
            return
        }

        // Remove old penguin views for penguins that no longer exist
        let activePenguinIDs = Set(penguins.map { $0.id })
        let viewsToRemove = penguinViews.filter { !activePenguinIDs.contains($0.key) }

        for (_, view) in viewsToRemove {
            view.removeFromSuperview()
        }
        penguinViews = penguinViews.filter { activePenguinIDs.contains($0.key) }

        // Update or create views for each penguin
        for penguin in penguins where penguin.isVisible {
            updatePenguinView(penguin, in: contentView)
        }

        // Force a display update
        contentView.needsDisplay = true
    }

    private func updatePenguinView(_ penguin: SimplePenguin, in parentView: NSView) {
        let penguinView: NSView

        if let existingView = penguinViews[penguin.id] {
            penguinView = existingView
        } else {
            // Create a new view for this penguin
            penguinView = createPenguinView(for: penguin)
            parentView.addSubview(penguinView)
            penguinViews[penguin.id] = penguinView
        }

        // Update position (SimplePenguin already uses AppKit coordinates)
        let viewFrame = NSRect(
            x: penguin.position.x - penguin.size.width / 2,
            y: penguin.position.y - penguin.size.height / 2,
            width: penguin.size.width,
            height: penguin.size.height
        )

        penguinView.frame = viewFrame
    }

    private func createPenguinView(for penguin: SimplePenguin) -> NSView {
        let view = NSView()

        // Set background color based on penguin state
        let color: NSColor
        switch penguin.state {
        case .falling:
            color = NSColor.systemRed
        case .walking:
            color = NSColor.systemBlue
        case .dead:
            color = NSColor.systemGray
        }

        view.wantsLayer = true
        view.layer?.backgroundColor = color.cgColor
        view.layer?.borderColor = NSColor.white.cgColor
        view.layer?.borderWidth = 2.0
        view.layer?.cornerRadius = 4.0

        return view
    }

    func cleanup() {
        for (_, view) in penguinViews {
            view.removeFromSuperview()
        }
        penguinViews.removeAll()

        for window in windows {
            window.close()
        }
        windows.removeAll()
    }

    func handleSpaceChange() {
        // Simple implementation - just hide and show
        for (_, view) in penguinViews {
            view.isHidden = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            for (_, view) in self.penguinViews {
                view.isHidden = false
            }
        }
    }
}