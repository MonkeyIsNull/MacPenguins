//
//  SimpleRenderer.swift
//  MacPenguins - Ultra-simple renderer that definitely shows penguins
//
//  Created by MacPenguins on 26/11/2024.
//

import Foundation
import AppKit

class SimpleRenderer {

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
        print("   Window level: \(overlayWindow.level.rawValue)")
        print("   Window is visible: \(overlayWindow.isVisible)")
    }

    func updatePenguins(_ penguins: [Penguin]) {
        guard let mainWindow = windows.first,
              let contentView = mainWindow.contentView else {
            print("❌ No overlay window available for rendering")
            return
        }

        // Remove old penguin views
        for (penguinID, view) in penguinViews {
            if !penguins.contains(where: { $0.id == penguinID }) {
                view.removeFromSuperview()
                penguinViews.removeValue(forKey: penguinID)
            }
        }

        // Update or create views for each penguin
        var stateCount: [PenguinState: Int] = [:]
        for penguin in penguins where penguin.isVisible {
            updatePenguinView(penguin, in: contentView)
            stateCount[penguin.state, default: 0] += 1
        }

        // Debug: Print penguin states occasionally
        if penguins.count > 0 && Int.random(in: 1...300) == 1 {
            print("🐧 Penguin states: \(stateCount)")
        }

        // Force a display update
        contentView.needsDisplay = true
    }

    private func updatePenguinView(_ penguin: Penguin, in parentView: NSView) {
        let penguinView: NSView

        if let existingView = penguinViews[penguin.id] {
            penguinView = existingView
        } else {
            // Create a new view for this penguin
            penguinView = createPenguinView(for: penguin)
            parentView.addSubview(penguinView)
            penguinViews[penguin.id] = penguinView

            print("🐧 Created penguin view at \(penguin.position)")
        }

        // Update position (convert from screen coordinates)
        let screenHeight = parentView.bounds.height
        let viewFrame = NSRect(
            x: penguin.position.x - penguin.size.width / 2,
            y: screenHeight - penguin.position.y - penguin.size.height / 2, // Flip Y coordinate
            width: penguin.size.width,
            height: penguin.size.height
        )

        penguinView.frame = viewFrame
    }

    private func createPenguinView(for penguin: Penguin) -> NSView {
        let view = NSView()

        // Set background color based on penguin state and type
        let color: NSColor
        switch (penguin.state, penguin.penguinType) {
        case (.walker, "normal"):
            color = NSColor.blue
        case (.walker, "skateboarder"):
            color = NSColor.green
        case (.faller, _):
            color = NSColor.red
        case (.tumbler, _):
            color = NSColor.orange
        case (.climber, _):
            color = NSColor.purple
        case (.floater, _):
            color = NSColor.cyan
        case (.angel, _):
            color = NSColor.white
        case (.explosion, _), (.splatted, _), (.squashed, _), (.zapped, _):
            color = NSColor.black
        case (.action0, _):
            color = NSColor.brown  // Reading
        case (.action1, _):
            color = NSColor.gray   // Sleeping
        default:
            color = NSColor.yellow
        }

        view.wantsLayer = true
        view.layer?.backgroundColor = color.cgColor
        view.layer?.borderColor = NSColor.black.cgColor
        view.layer?.borderWidth = 1.0

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