//
//  BasicRenderer.swift
//  MacPenguins - Basic renderer that works with SimplePenguin

import Foundation
import AppKit

class BasicRenderer {

    private var windows: [NSWindow] = []
    private var penguinViews: [UUID: NSView] = [:]
    private var spriteCache: [String: NSImage] = [:]

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

            // Configure window to be on top but not interfere.
            // .popUpMenu (101) sits above the Dock (level 20) so penguins render in front of it.
            overlayWindow.level = NSWindow.Level.popUpMenu
            overlayWindow.backgroundColor = NSColor.clear
            overlayWindow.isOpaque = false
            overlayWindow.hasShadow = false
            overlayWindow.ignoresMouseEvents = true
            overlayWindow.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]

            // Make sure the window is visible
            overlayWindow.makeKeyAndOrderFront(nil)
            overlayWindow.orderFrontRegardless()

            windows.append(overlayWindow)

            print("Created overlay window \(index) covering screen: \(screenFrame)")
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
        if let image = image(for: penguin) {
            imageView.image = image
            imageView.imageScaling = .scaleProportionallyUpOrDown
            return imageView
        }

        // Fallback to colored rectangle if sprite loading fails
        print("[WARN] No sprite for penguin (state=\(penguin.state), type=\(penguin.penguinType)), using fallback")
        let fallbackView = NSView()
        fallbackView.wantsLayer = true
        let color: NSColor
        switch penguin.state {
        case .falling:  color = NSColor.systemRed
        case .walking:  color = NSColor.systemBlue
        case .tumbling: color = NSColor.systemOrange
        case .acting:   color = NSColor.systemGreen
        case .dead:     color = NSColor.systemGray
        }
        fallbackView.layer?.backgroundColor = color.cgColor
        fallbackView.layer?.borderColor = NSColor.white.cgColor
        fallbackView.layer?.borderWidth = 2.0
        fallbackView.layer?.cornerRadius = 4.0
        return fallbackView
    }

    private func updatePenguinSprite(_ penguin: SimplePenguin, penguinView: NSView) {
        // Only update sprite for NSImageView (not fallback colored views)
        guard let imageView = penguinView as? NSImageView else { return }
        if let image = image(for: penguin) {
            imageView.image = image
        }
    }

    // Resolves the sprite for a given penguin's state/type/direction/frame, with caching.
    // Skateboarder walkers come from a 30x60 strip in the Themes folder (top half = right,
    // bottom half = left); the reader is a 360x30 12-frame strip. Both are sliced and
    // cached on first use.
    private func image(for penguin: SimplePenguin) -> NSImage? {
        let direction = penguin.velocity.x > 0 ? "right" : "left"

        if penguin.penguinType == "skateboarder" && penguin.state == .walking {
            let key = "skateboarder_walker_\(direction)"
            if let cached = spriteCache[key] { return cached }
            if let split = loadSkateboarderWalker() {
                spriteCache["skateboarder_walker_right"] = split.right
                spriteCache["skateboarder_walker_left"] = split.left
                return spriteCache[key]
            }
            return nil
        }

        if penguin.state == .acting && penguin.penguinType == "normal" {
            // Reader animates through 12 frames at the same cadence as walker.
            let frame = penguin.currentFrame % 12
            let key = "reader_\(frame)"
            if let cached = spriteCache[key] { return cached }
            if loadReaderFrames() {
                return spriteCache[key]
            }
            return nil
        }

        let spriteName: String
        switch penguin.state {
        case .falling:  spriteName = "faller_frame1"
        case .walking:
            let frame = penguin.currentFrame % 8
            spriteName = "walker_\(direction)_\(frame)"
        case .tumbling: spriteName = "tumbler_frame1"
        case .acting:   spriteName = "walker_\(direction)_0" // skateboarder fallback
        case .dead:     spriteName = "tumbler_frame1"
        }

        if let cached = spriteCache[spriteName] { return cached }
        let path = "./sprites/\(spriteName).png"
        guard let img = NSImage(contentsOfFile: path) else {
            print("[ERR] Failed to load sprite: \(path)")
            return nil
        }
        spriteCache[spriteName] = img
        return img
    }

    @discardableResult
    private func loadReaderFrames() -> Bool {
        let path = "./MacPenguins/Themes/Penguins/normal_reader.png"
        guard let strip = NSImage(contentsOfFile: path),
              let cg = strip.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            print("[ERR] Failed to load reader strip: \(path)")
            return false
        }
        let frameCount = 12
        let frameW = cg.width / frameCount
        let frameH = cg.height
        let size = NSSize(width: frameW, height: frameH)
        for i in 0..<frameCount {
            guard let frameCG = cg.cropping(to: CGRect(x: i * frameW, y: 0, width: frameW, height: frameH)) else {
                continue
            }
            spriteCache["reader_\(i)"] = NSImage(cgImage: frameCG, size: size)
        }
        return true
    }

    private func loadSkateboarderWalker() -> (right: NSImage, left: NSImage)? {
        let path = "./MacPenguins/Themes/Penguins/skateboarder_walker.png"
        guard let strip = NSImage(contentsOfFile: path),
              let cg = strip.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            print("[ERR] Failed to load skateboarder strip: \(path)")
            return nil
        }
        let frameW = cg.width
        let frameH = cg.height / 2 // 2 directions stacked vertically
        guard let topCG = cg.cropping(to: CGRect(x: 0, y: 0, width: frameW, height: frameH)),
              let bottomCG = cg.cropping(to: CGRect(x: 0, y: frameH, width: frameW, height: frameH)) else {
            return nil
        }
        let size = NSSize(width: frameW, height: frameH)
        return (right: NSImage(cgImage: topCG, size: size),
                left:  NSImage(cgImage: bottomCG, size: size))
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