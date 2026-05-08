//
//  SimplePenguin.swift
//  MacPenguins - Simplified penguin with proven physics

import Foundation
import CoreGraphics
import AppKit

enum SimplePenguinState {
    case falling   // gentle drop from above the screen
    case walking
    case tumbling  // walked off a window edge: stronger gravity, keeps horizontal momentum
    case acting    // idle action (e.g., reading a book) — paused on the current surface
    case dead
}

class SimplePenguin {
    // Core properties
    let id: UUID = UUID()
    var position: CGPoint
    var velocity: CGPoint = CGPoint.zero
    var state: SimplePenguinState = .falling
    var currentSurface: WindowSurface?

    // Visual properties
    var isVisible: Bool = true
    var penguinType: String

    var size: CGSize = CGSize(width: 30, height: 30)

    // Physics constants
    private let gravity: CGFloat = 0.8
    private let maxFallSpeed: CGFloat = 12.0
    private var walkSpeed: CGFloat {
        // Skateboarder is faster than the normal walker (matches the original
        // xpenguins theme: skateboarder speed 6 vs normal speed 4).
        penguinType == "skateboarder" ? 2.0 : 1.0
    }

    // Animation (simplified)
    var currentFrame: Int = 0
    var frameCounter: Int = 0
    private let frameDelay: Int = 4 // Faster animation (4 frames = ~0.07 seconds at 60fps)

    // Action state (e.g., reading): how many update ticks remain before the
    // penguin resumes walking. Only meaningful while state == .acting.
    var actionTicks: Int = 0

    init(position: CGPoint, penguinType: String = "normal") {
        self.position = position
        self.penguinType = penguinType
        self.state = .falling
    }

    func update(collision: SimpleCollision) {
        // Update animation
        frameCounter += 1
        if frameCounter >= frameDelay {
            frameCounter = 0
            currentFrame = (currentFrame + 1) % 8
        }

        switch state {
        case .falling:
            updateFalling(collision: collision)

        case .walking:
            updateWalking(collision: collision)

        case .tumbling:
            updateTumbling(collision: collision)

        case .acting:
            updateActing(collision: collision)

        case .dead:
            // Dead penguins don't move
            break
        }
    }

    private func updateFalling(collision: SimpleCollision) {
        // Apply gravity
        velocity.y += gravity
        velocity.y = min(velocity.y, maxFallSpeed)

        // Calculate next position
        let nextY = position.y - velocity.y

        // Use EXACT collision logic from working physics demo
        let penguinBottomY = position.y - size.height / 2
        let nextBottomY = nextY - size.height / 2


        if let surface = collision.checkFallingCollision(
            penguinX: position.x,
            penguinY: penguinBottomY,
            nextY: nextBottomY
        ) {
            // Land on surface - EXACT logic from working demo
            let newY = surface.top + size.height / 2 // penguin center = surface top + half height
            let isAlreadyCloseToSurface = abs(position.y - newY) < 1.5

            // Only update if significantly different position (avoid jittering)
            if !isAlreadyCloseToSurface {
                position.y = newY
                velocity.y = 0
                velocity.x = Bool.random() ? walkSpeed : -walkSpeed
                state = .walking
            } else {
                // Already close to surface, just ensure we're in walking state
                velocity.y = 0
                state = .walking
            }

            currentSurface = surface
        } else {
            // Continue falling
            position.y = nextY
        }

        // Check screen bounds - if penguin falls below screen, respawn
        // Find the lowest screen bottom
        let lowestScreenBottom = NSScreen.screens.map { $0.frame.minY }.min() ?? 0
        if position.y < lowestScreenBottom - 100 {
            respawn()
        }
    }

    private func updateTumbling(collision: SimpleCollision) {
        // Stronger acceleration and a lower terminal velocity than the gentle
        // .falling state, matching the original xpenguins tumbler config
        // (acceleration 1, terminal_velocity 8).
        velocity.y += 1.0
        velocity.y = min(velocity.y, 8.0)

        let nextX = position.x + velocity.x
        let nextY = position.y - velocity.y
        let penguinBottomY = position.y - size.height / 2
        let nextBottomY = nextY - size.height / 2

        if let surface = collision.checkFallingCollision(
            penguinX: nextX,
            penguinY: penguinBottomY,
            nextY: nextBottomY
        ) {
            // Land and resume walking
            position.x = nextX
            position.y = surface.top + size.height / 2
            velocity.y = 0
            velocity.x = Bool.random() ? walkSpeed : -walkSpeed
            state = .walking
            currentSurface = surface
        } else {
            position.x = nextX
            position.y = nextY
        }

        // Respawn if the tumble took us off the bottom of the world
        let lowestScreenBottom = NSScreen.screens.map { $0.frame.minY }.min() ?? 0
        if position.y < lowestScreenBottom - 100 {
            respawn()
        }
    }

    private func updateWalking(collision: SimpleCollision) {
        guard let cached = currentSurface else {
            state = .falling
            return
        }

        // Re-resolve window-backed surfaces every frame so penguins ride windows
        // as they move/resize. If the window is gone, fall.
        let surface: WindowSurface
        if let id = cached.windowID {
            guard let live = collision.getSurface(forWindowID: id) else {
                state = .falling
                currentSurface = nil
                return
            }
            surface = live
            position.y = surface.top + size.height / 2
            currentSurface = surface
        } else {
            surface = cached
        }

        // Move horizontally
        position.x += velocity.x

        // Walked off the surface? Behavior depends on what surface it was:
        //   - Window edge: tumble off with horizontal momentum (cartwheel arc).
        //   - Screen-bottom ground edge: fall straight off the screen, respawn
        //     from the top — keeps the population cycling instead of clumping.
        if !surface.contains(x: position.x) {
            if surface.windowID != nil {
                state = .tumbling
            } else {
                velocity.x = 0
                state = .falling
            }
            currentSurface = nil
            return
        }

        // Occasionally pause to read a book. Normal penguins only — skateboarders
        // don't have a digger sprite shipped, and a stationary skateboarder looks
        // wrong anyway.
        if penguinType == "normal" && Int.random(in: 1...600) == 1 {
            state = .acting
            velocity.x = 0
            actionTicks = 200 // ~3.3s at 60fps
            currentFrame = 0
            return
        }

        // Occasionally reverse direction (more frequent to keep penguins walking)
        if Int.random(in: 1...120) == 1 {
            velocity.x = -velocity.x
        }
    }

    private func updateActing(collision: SimpleCollision) {
        // Re-resolve window-backed surfaces so a reader rides a moving window.
        guard let cached = currentSurface else {
            state = .falling
            return
        }
        let surface: WindowSurface
        if let id = cached.windowID {
            guard let live = collision.getSurface(forWindowID: id) else {
                // Window vanished mid-read — drop into a fall.
                state = .falling
                currentSurface = nil
                return
            }
            surface = live
            position.y = surface.top + size.height / 2
            currentSurface = surface
        } else {
            surface = cached
        }

        // If the window narrowed underfoot, treat like walking off it.
        if !surface.contains(x: position.x) {
            if surface.windowID != nil {
                state = .tumbling
            } else {
                velocity.x = 0
                state = .falling
            }
            currentSurface = nil
            return
        }

        actionTicks -= 1
        if actionTicks <= 0 {
            state = .walking
            velocity.x = Bool.random() ? walkSpeed : -walkSpeed
            currentFrame = 0
        }
    }

    func respawn() {
        // Respawn at random position at top of main screen
        let mainScreen = NSScreen.main ?? NSScreen.screens[0]
        let screenFrame = mainScreen.frame

        // Use actual screen bounds for spawning
        let minX = screenFrame.minX + 100
        let maxX = screenFrame.maxX - 100
        position.x = CGFloat.random(in: minX...maxX)
        position.y = screenFrame.maxY + 50 // Above screen's top edge (not just height!)
        velocity = CGPoint.zero
        state = .falling
        currentSurface = nil
        isVisible = true

    }

    func kill() {
        state = .dead
        // Could add death animation here

        // Respawn after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.respawn()
        }
    }
}