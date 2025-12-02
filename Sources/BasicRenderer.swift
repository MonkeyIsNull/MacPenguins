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

        // Create overlay windows for ALL screens
        for (index, screen) in NSScreen.screens.enumerated() {
            let screenFrame = screen.frame

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

            print("✅ Created overlay window \(index) covering screen: \(screenFrame)")
        }
    }

    func updatePenguins(_ penguins: [SimplePenguin]) {
        guard !windows.isEmpty else {
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
            updatePenguinView(penguin)
        }

        // Force a display update on all windows
        for window in windows {
            window.contentView?.needsDisplay = true
        }
    }

    private func updatePenguinView(_ penguin: SimplePenguin) {
        // Find which overlay window this penguin should be rendered on
        let targetWindow = findWindowForPosition(penguin.position)
        guard let targetContentView = targetWindow?.contentView else { return }

        let penguinView: NSView

        if let existingView = penguinViews[penguin.id] {
            penguinView = existingView
            // Move to correct parent if needed
            if penguinView.superview !== targetContentView {
                penguinView.removeFromSuperview()
                targetContentView.addSubview(penguinView)
            }
        } else {
            // Create a new view for this penguin
            penguinView = createPenguinView(for: penguin)
            targetContentView.addSubview(penguinView)
            penguinViews[penguin.id] = penguinView
        }

        // Update sprite for state changes AND direction changes
        updatePenguinSprite(penguin, penguinView: penguinView)

        // Convert from global coordinates to window-local coordinates
        let windowFrame = targetWindow?.frame ?? .zero
        let localX = penguin.position.x - windowFrame.minX  // Convert global X to local window X
        let localY = penguin.position.y - windowFrame.minY  // Convert global Y to local window Y

        let viewFrame = NSRect(
            x: localX - penguin.size.width / 2,
            y: localY - penguin.size.height / 2,
            width: penguin.size.width,
            height: penguin.size.height
        )

        penguinView.frame = viewFrame
    }

    private func findWindowForPosition(_ position: CGPoint) -> NSWindow? {
        // Find the overlay window whose screen contains this position
        for window in windows {
            let frame = window.frame
            if position.x >= frame.minX && position.x <= frame.maxX {
                return window
            }
        }
        // Fallback to first window
        return windows.first
    }

    private func createPenguinView(for penguin: SimplePenguin) -> NSView {
        let imageView = NSImageView()

        // Load sprite based on penguin state and direction
        let spriteName: String
        switch penguin.state {
        case .falling:
            spriteName = "faller_frame1"
        case .walking:
            // Choose animated sprite based on direction and frame (velocity > 0 = moving right)
            let direction = penguin.velocity.x > 0 ? "right" : "left"
            let frame = penguin.currentFrame % 8 // 8 walking frames
            spriteName = "walker_\(direction)_\(frame)"
        case .dead:
            spriteName = "tumbler_frame1" // Use tumbler for dead state
        }

        // Try to load the sprite image
        let spritePath = "./sprites/\(spriteName).png"
        if let image = NSImage(contentsOfFile: spritePath) {
            imageView.image = image
            imageView.imageScaling = .scaleProportionallyUpOrDown
        } else {
            // Fallback to colored rectangle if sprite loading fails
            print("⚠️ Failed to load sprite: \(spritePath), using fallback")
            let fallbackView = NSView()
            fallbackView.wantsLayer = true

            let color: NSColor
            switch penguin.state {
            case .falling:
                color = NSColor.systemRed
            case .walking:
                color = NSColor.systemBlue
            case .dead:
                color = NSColor.systemGray
            }

            fallbackView.layer?.backgroundColor = color.cgColor
            fallbackView.layer?.borderColor = NSColor.white.cgColor
            fallbackView.layer?.borderWidth = 2.0
            fallbackView.layer?.cornerRadius = 4.0

            return fallbackView
        }

        return imageView
    }

    private func updatePenguinSprite(_ penguin: SimplePenguin, penguinView: NSView) {
        // Only update sprite for NSImageView (not fallback colored views)
        guard let imageView = penguinView as? NSImageView else { return }

        let spriteName: String
        switch penguin.state {
        case .falling:
            spriteName = "faller_frame1"
        case .walking:
            // Choose animated sprite based on direction and frame (velocity > 0 = moving right)
            let direction = penguin.velocity.x > 0 ? "right" : "left"
            let frame = penguin.currentFrame % 8 // 8 walking frames
            spriteName = "walker_\(direction)_\(frame)"
        case .dead:
            spriteName = "tumbler_frame1"
        }

        let spritePath = "./sprites/\(spriteName).png"
        if let image = NSImage(contentsOfFile: spritePath) {
            // Always update sprite (with animation)
            imageView.image = image

        } else {
            print("❌ Failed to load sprite: \(spritePath)")
        }
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