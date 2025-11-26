//
//  AnimationRenderer.swift
//  MacPenguins
//
//  Created by MacPenguins on 26/11/2024.
//

import Foundation
import CoreGraphics
import AppKit
import QuartzCore

class PenguinLayer: CALayer {
    var penguinID: UUID?
    var spriteFrames: [CGImage] = []
    var currentState: PenguinState = .walker
    var currentDirection: PenguinDirection = .right

    override init() {
        super.init()
        setupLayer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayer()
    }

    private func setupLayer() {
        // Configure layer properties
        contentsGravity = .center
        masksToBounds = false
        isOpaque = false
    }

    func updateSprite(frame: Int, state: PenguinState, direction: PenguinDirection) {
        guard frame < spriteFrames.count else { return }

        currentState = state
        currentDirection = direction

        // Set the sprite image
        contents = spriteFrames[frame]

        // Flip horizontally if needed
        if direction == .left {
            transform = CATransform3DMakeScale(-1, 1, 1)
        } else {
            transform = CATransform3DIdentity
        }
    }

    func setSpriteFrames(_ frames: [CGImage]) {
        spriteFrames = frames
    }
}

class OverlayWindow: NSWindow {
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: [.borderless], backing: backingStoreType, defer: flag)

        setupWindow()
    }

    private func setupWindow() {
        // Configure window for desktop overlay
        level = .floating
        backgroundColor = NSColor.clear
        isOpaque = false
        hasShadow = false
        ignoresMouseEvents = true
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]

        // Make window layer-backed for Core Animation
        contentView?.wantsLayer = true
        contentView?.layer?.backgroundColor = NSColor.clear.cgColor
    }
}

class AnimationRenderer {

    // Overlay windows for each display
    private var overlayWindows: [OverlayWindow] = []
    private var penguinLayers: [UUID: PenguinLayer] = [:]

    // Theme management
    private var spriteCache: [String: [PenguinState: [PenguinDirection: [CGImage]]]] = [:]

    // Display tracking
    private var displayBounds: [CGRect] = []

    init() {
        setupDisplayTracking()
    }

    deinit {
        cleanup()
    }

    // MARK: - Public Interface

    func setupOverlayWindows() {
        cleanup()

        updateDisplayBounds()

        for (index, bounds) in displayBounds.enumerated() {
            let overlayWindow = OverlayWindow(
                contentRect: bounds,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )

            overlayWindow.orderFrontRegardless()
            overlayWindows.append(overlayWindow)

            print("Created overlay window \(index + 1) at \(bounds)")
        }
    }

    func updatePenguins(_ penguins: [Penguin]) {
        // Remove layers for penguins that no longer exist
        let activePenguinIDs = Set(penguins.map { $0.id })
        let layersToRemove = penguinLayers.keys.filter { !activePenguinIDs.contains($0) }

        for penguinID in layersToRemove {
            if let layer = penguinLayers[penguinID] {
                layer.removeFromSuperlayer()
                penguinLayers.removeValue(forKey: penguinID)
            }
        }

        // Update or create layers for each penguin
        for penguin in penguins {
            updatePenguinLayer(penguin)
        }
    }

    func loadSpritesForTheme(themeName: String, penguinType: String, sprites: [PenguinState: [PenguinDirection: [NSImage]]]) {
        var penguinCache: [PenguinState: [PenguinDirection: [CGImage]]] = [:]

        for (state, directionSprites) in sprites {
            var stateCache: [PenguinDirection: [CGImage]] = [:]

            for (direction, images) in directionSprites {
                let cgImages = images.compactMap { image -> CGImage? in
                    return image.cgImage(forProposedRect: nil, context: nil, hints: nil)
                }
                stateCache[direction] = cgImages
            }

            penguinCache[state] = stateCache
        }

        spriteCache[penguinType] = penguinCache
        print("Loaded sprites for theme: \(themeName), type: \(penguinType)")
    }

    func handleSpaceChange() {
        // Hide all penguin layers briefly during space transition
        for (_, layer) in penguinLayers {
            layer.isHidden = true
        }

        // Show them again after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            for (_, layer) in self.penguinLayers {
                layer.isHidden = false
            }
        }
    }

    func cleanup() {
        // Remove all penguin layers
        for (_, layer) in penguinLayers {
            layer.removeFromSuperlayer()
        }
        penguinLayers.removeAll()

        // Close overlay windows
        for window in overlayWindows {
            window.close()
        }
        overlayWindows.removeAll()
    }

    // MARK: - Private Methods

    private func updatePenguinLayer(_ penguin: Penguin) {
        // Get or create layer for this penguin
        let layer: PenguinLayer
        if let existingLayer = penguinLayers[penguin.id] {
            layer = existingLayer
        } else {
            layer = PenguinLayer()
            layer.penguinID = penguin.id
            penguinLayers[penguin.id] = layer

            // Load sprites for this penguin type
            loadSpritesForPenguin(penguin, into: layer)

            // Add layer to appropriate overlay window
            addLayerToOverlayWindow(layer, at: penguin.position)
        }

        // Update layer properties
        updateLayerPosition(layer, penguin: penguin)
        updateLayerSprite(layer, penguin: penguin)
        updateLayerVisibility(layer, penguin: penguin)
    }

    private func loadSpritesForPenguin(_ penguin: Penguin, into layer: PenguinLayer) {
        guard let penguinSprites = spriteCache[penguin.penguinType],
              let stateSprites = penguinSprites[penguin.state],
              let directionSprites = stateSprites[penguin.direction] else {
            print("Warning: No sprites found for penguin type: \(penguin.penguinType), state: \(penguin.state)")
            return
        }

        layer.setSpriteFrames(directionSprites)
    }

    private func updateLayerPosition(_ layer: PenguinLayer, penguin: Penguin) {
        // Convert penguin position to layer position
        let layerPosition = CGPoint(
            x: penguin.position.x,
            y: penguin.position.y
        )

        // Animate position change smoothly
        CATransaction.begin()
        CATransaction.setDisableActions(false)
        CATransaction.setAnimationDuration(1.0/60.0) // 60 FPS

        layer.position = layerPosition
        layer.bounds = CGRect(origin: CGPoint.zero, size: penguin.size)

        CATransaction.commit()
    }

    private func updateLayerSprite(_ layer: PenguinLayer, penguin: Penguin) {
        // Update sprite if state or direction changed
        if layer.currentState != penguin.state || layer.currentDirection != penguin.direction {
            loadSpritesForPenguin(penguin, into: layer)
        }

        // Update current frame
        layer.updateSprite(
            frame: penguin.currentFrame,
            state: penguin.state,
            direction: penguin.direction
        )
    }

    private func updateLayerVisibility(_ layer: PenguinLayer, penguin: Penguin) {
        layer.isHidden = !penguin.isVisible
    }

    private func addLayerToOverlayWindow(_ layer: PenguinLayer, at position: CGPoint) {
        // Find the appropriate overlay window for this position
        let overlayWindow = findOverlayWindowForPosition(position)
        guard let contentLayer = overlayWindow?.contentView?.layer else {
            print("Warning: No overlay window found for position: \(position)")
            return
        }

        contentLayer.addSublayer(layer)
    }

    private func findOverlayWindowForPosition(_ position: CGPoint) -> OverlayWindow? {
        for (index, bounds) in displayBounds.enumerated() {
            if bounds.contains(position) && index < overlayWindows.count {
                return overlayWindows[index]
            }
        }

        // Return first overlay window as fallback
        return overlayWindows.first
    }

    private func setupDisplayTracking() {
        // Monitor for display configuration changes
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleDisplayConfigurationChange()
        }
    }

    private func handleDisplayConfigurationChange() {
        print("Display configuration changed - updating overlay windows")

        // Recreate overlay windows for new display configuration
        DispatchQueue.main.async { [weak self] in
            self?.setupOverlayWindows()
        }
    }

    private func updateDisplayBounds() {
        displayBounds = []

        for screen in NSScreen.screens {
            displayBounds.append(screen.frame)
        }

        print("Updated display bounds: \(displayBounds)")
    }
}