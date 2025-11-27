//
//  SimplePenguin.swift
//  MacPenguins - Simplified penguin with proven physics

import Foundation
import CoreGraphics
import AppKit

enum SimplePenguinState {
    case falling
    case walking
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
    private let walkSpeed: CGFloat = 1.0 // Slower walking so we can see animation
    private let maxFallSpeed: CGFloat = 12.0

    // Animation (simplified)
    var currentFrame: Int = 0
    var frameCounter: Int = 0
    private let frameDelay: Int = 4 // Faster animation (4 frames = ~0.07 seconds at 60fps)

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
            position.y = surface.top + size.height / 2 // penguin center = surface top + half height
            velocity.y = 0
            velocity.x = Bool.random() ? walkSpeed : -walkSpeed
            currentSurface = surface
            state = .walking
        } else {
            // Continue falling
            position.y = nextY
        }

        // Check screen bounds - if penguin falls below screen, respawn
        if position.y < -100 {
            respawn()
        }
    }

    private func updateWalking(collision: SimpleCollision) {
        guard let surface = currentSurface else {
            state = .falling
            print("⚠️ Penguin \(id.uuidString.prefix(8)) lost surface, falling")
            return
        }


        // Move horizontally
        position.x += velocity.x

        // Check if we walked off the edge
        if !surface.contains(x: position.x) {
            state = .falling
            currentSurface = nil
            velocity.x *= 0.5 // Keep some horizontal momentum
            return
        }


        // Handle screen wrapping (only for ground level)
        if surface.windowID == nil { // Ground surface
            let screenWidth = NSScreen.main?.frame.width ?? 1440
            if position.x < 0 {
                position.x = screenWidth
            } else if position.x > screenWidth {
                position.x = 0
            }
        }

        // Occasionally reverse direction (more frequent to keep penguins walking)
        if Int.random(in: 1...120) == 1 {
            velocity.x = -velocity.x
        }
    }

    func respawn() {
        // Respawn at random position at top of screen
        let screenWidth = NSScreen.main?.frame.width ?? 1440
        let screenHeight = NSScreen.main?.frame.height ?? 900
        position.x = CGFloat.random(in: 100...(screenWidth - 100))
        position.y = screenHeight + 50 // Above screen (AppKit coordinates: Y=0 at bottom)
        velocity = CGPoint.zero
        state = .falling
        currentSurface = nil
        isVisible = true

        print("🔄 Penguin \(id.uuidString.prefix(8)) respawned")
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