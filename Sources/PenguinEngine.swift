//
//  PenguinEngine.swift
//  MacPenguins
//
//  Created by MacPenguins on 26/11/2024.
//

import Foundation
import CoreGraphics
import AppKit

class PenguinEngine {

    // Dependencies
    private let themeManager: ThemeManager
    private let collisionDetector: CollisionDetector

    // Penguin management
    private var penguins: [Penguin] = []
    private let maxPenguins: Int = 100

    // Callbacks
    var onPenguinsUpdated: (([Penguin]) -> Void)?

    // Spawn configuration
    private var screenBounds: CGRect = CGRect.zero
    private var spawnPoints: [CGPoint] = []

    // Debug
    private var updateCount = 0

    init(themeManager: ThemeManager, collisionDetector: CollisionDetector) {
        self.themeManager = themeManager
        self.collisionDetector = collisionDetector

        updateScreenBounds()
        setupSpawnPoints()
    }

    // MARK: - Public Interface

    func spawnInitialPenguins(count: Int) {
        let actualCount = min(count, maxPenguins)

        for _ in 0..<actualCount {
            spawnPenguin()
        }

        print("Spawned \(actualCount) penguins")
        notifyPenguinsUpdated()
    }

    func adjustPenguinCount(to targetCount: Int) {
        let actualCount = min(targetCount, maxPenguins)

        if actualCount > penguins.count {
            // Add penguins
            let toAdd = actualCount - penguins.count
            for _ in 0..<toAdd {
                spawnPenguin()
            }
        } else if actualCount < penguins.count {
            // Remove penguins gracefully
            let toRemove = penguins.count - actualCount
            for _ in 0..<toRemove {
                if let penguin = penguins.first(where: { !$0.state.isDeadState }) {
                    penguin.changeState(to: .exit)
                }
            }
        }

        notifyPenguinsUpdated()
    }

    func removeAllPenguins() {
        penguins.removeAll()
        notifyPenguinsUpdated()
    }

    func reloadWithNewTheme() {
        // Update existing penguins with new theme data
        for penguin in penguins {
            // Reset animation properties based on new theme
            penguin.currentFrame = 0
            penguin.frameCounter = 0
        }
    }

    func update() {
        updateScreenBounds()

        // Update each penguin
        var indicesToRemove: [Int] = []
        updateCount += 1

        for (index, penguin) in penguins.enumerated() {
            updatePenguin(penguin)

            // Debug: Print first penguin info
            if index == 0 && (updateCount < 10 || updateCount % 60 == 0) {
                print("🐧 Update \(updateCount): Penguin 0 at \(penguin.position), state: \(penguin.state)")
            }

            // Mark invisible penguins for removal
            if !penguin.isVisible {
                indicesToRemove.append(index)
            }
        }

        // Remove invisible penguins
        for index in indicesToRemove.reversed() {
            penguins.remove(at: index)
        }

        // Spawn new penguins if we're below the target count
        maintainPenguinCount()

        // Notify renderer
        notifyPenguinsUpdated()
    }

    func handleSpaceChange() {
        // Hide penguins briefly during space transition
        for penguin in penguins {
            penguin.isVisible = false
        }

        // Remove all penguins and respawn after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.respawnAllPenguins()
        }
    }

    func handleMouseClick(at point: CGPoint) {
        // Find penguin at click location and zap it
        for penguin in penguins {
            let penguinRect = CGRect(
                x: penguin.position.x - penguin.size.width / 2,
                y: penguin.position.y - penguin.size.height / 2,
                width: penguin.size.width,
                height: penguin.size.height
            )

            if penguinRect.contains(point) && !penguin.state.isDeadState {
                penguin.kill(cause: .zapped)
                break
            }
        }
    }

    // MARK: - Private Methods

    private func spawnPenguin() {
        let spawnPoint = getRandomSpawnPoint()
        let penguinTypes = themeManager.getAvailablePenguinTypes()
        let penguinType = penguinTypes.randomElement() ?? "normal"

        let penguin = Penguin(
            position: spawnPoint,
            penguinType: penguinType,
            frameDelay: themeManager.getFrameDelay()
        )

        // Set theme-specific properties
        penguin.size = themeManager.getPenguinSize(for: penguinType)
        penguin.speed = themeManager.getPenguinSpeed(for: penguinType)

        penguins.append(penguin)
    }

    private func updatePenguin(_ penguin: Penguin) {
        // Store old position for collision detection
        let oldPosition = penguin.position

        // Debug: Print penguin info occasionally
        if Int.random(in: 1...180) == 1 {
            print("🐧 Penguin at \(penguin.position), state: \(penguin.state), velocity: \(penguin.physics.velocity)")
            print("   Screen bounds: \(screenBounds)")
        }

        // Update penguin behavior and physics
        penguin.update()

        // Apply collision detection and response
        handleCollisions(for: penguin, from: oldPosition)

        // Handle screen bounds
        handleScreenBounds(for: penguin)

        // Handle window association
        updateWindowAssociation(for: penguin)
    }

    private func handleCollisions(for penguin: Penguin, from oldPosition: CGPoint) {
        let penguinRect = CGRect(
            x: penguin.position.x - penguin.size.width / 2,
            y: penguin.position.y - penguin.size.height / 2,
            width: penguin.size.width,
            height: penguin.size.height
        )

        // Check collision with windows
        let collision = collisionDetector.checkCollision(
            rect: penguinRect,
            velocity: penguin.physics.velocity
        )

        // Debug: Print collision info occasionally
        if Int.random(in: 1...120) == 1 && penguin.state == .faller {
            print("🔍 Collision check: penguin at \(penguin.position), collision type: \(collision.type)")
        }

        switch collision.type {
        case .none:
            // No collision
            break

        case .top:
            // Landed on window top - become walker
            if penguin.state == .faller || penguin.state == .tumbler {
                penguin.position.y = collision.contactPoint.y - penguin.size.height / 2
                penguin.changeState(to: .walker)

                // Associate with this window
                if let windowID = collision.windowID {
                    penguin.associatedWindowID = windowID
                    penguin.lastAssociatedPosition = penguin.position
                }
            }

        case .bottom:
            // Hit window from below - bounce or squash
            penguin.position.y = collision.contactPoint.y + penguin.size.height / 2
            if penguin.physics.velocity.y < -5 {
                penguin.kill(cause: .squashed)
            } else {
                penguin.physics.velocity.y = abs(penguin.physics.velocity.y) * penguin.physics.bounce
            }

        case .left, .right:
            // Hit window side - reverse direction or climb
            penguin.position.x = oldPosition.x // Restore position
            if penguin.state == .walker || penguin.state == .runner {
                if Int.random(in: 0...100) < 20 {
                    penguin.changeState(to: .climber)
                } else {
                    penguin.reverseDirection()
                }
            } else {
                penguin.reverseDirection()
            }

        case .inside:
            // Penguin is inside a window - squash it
            if !penguin.state.isDeadState {
                penguin.kill(cause: .squashed)
            }
        }

        // Check collision with screen bottom (ground)
        if penguin.position.y >= screenBounds.maxY - penguin.size.height / 2 {
            penguin.position.y = screenBounds.maxY - penguin.size.height / 2

            if penguin.state == .faller || penguin.state == .tumbler {
                if penguin.physics.velocity.y > 5 {
                    penguin.kill(cause: .splatted)
                } else {
                    penguin.changeState(to: .walker)
                }
            }
            penguin.physics.velocity.y = 0
        }
    }

    private func handleScreenBounds(for penguin: Penguin) {
        // Handle horizontal screen bounds
        if penguin.position.x < 0 {
            if penguin.state == .climber {
                penguin.position.x = 0
            } else {
                penguin.position.x = screenBounds.maxX
            }
        } else if penguin.position.x > screenBounds.maxX {
            if penguin.state == .climber {
                penguin.position.x = screenBounds.maxX
            } else {
                penguin.position.x = 0
            }
        }

        // Handle vertical screen bounds
        if penguin.position.y < 0 {
            penguin.position.y = 0
            if penguin.state == .climber {
                penguin.changeState(to: .floater)
            }
        }
    }

    private func updateWindowAssociation(for penguin: Penguin) {
        // If penguin is associated with a window, check if window moved
        guard let windowID = penguin.associatedWindowID,
              let lastPos = penguin.lastAssociatedPosition else {
            return
        }

        if let windowBounds = collisionDetector.getWindowBounds(for: windowID) {
            // Window still exists - check if it moved
            let windowMovement = CGPoint(
                x: windowBounds.origin.x - (lastPos.x - penguin.size.width / 2),
                y: windowBounds.origin.y - (lastPos.y - penguin.size.height / 2)
            )

            // If window moved significantly, move penguin with it
            let movementThreshold: CGFloat = 5.0
            if abs(windowMovement.x) > movementThreshold || abs(windowMovement.y) > movementThreshold {
                penguin.position.x += windowMovement.x
                penguin.position.y += windowMovement.y
                penguin.lastAssociatedPosition = penguin.position
            }
        } else {
            // Window disappeared - become tumbler
            if penguin.state == .walker || penguin.state == .runner {
                penguin.changeState(to: .tumbler)
            }
            penguin.associatedWindowID = nil
            penguin.lastAssociatedPosition = nil
        }
    }

    private func updateScreenBounds() {
        // Get combined bounds of all displays
        screenBounds = SimpleWindowManager().getCombinedDisplayBounds()
        setupSpawnPoints()
    }

    private func setupSpawnPoints() {
        spawnPoints = []

        // Add spawn points across the top of all screens
        let pointSpacing: CGFloat = 100
        let startX = screenBounds.minX
        let endX = screenBounds.maxX
        let spawnY = screenBounds.minY - 50 // Above screen

        var x = startX
        while x <= endX {
            spawnPoints.append(CGPoint(x: x, y: spawnY))
            x += pointSpacing
        }

        // Ensure we have at least a few spawn points
        if spawnPoints.isEmpty {
            spawnPoints = [
                CGPoint(x: screenBounds.midX, y: spawnY),
                CGPoint(x: screenBounds.minX + 100, y: spawnY),
                CGPoint(x: screenBounds.maxX - 100, y: spawnY)
            ]
        }
    }

    private func getRandomSpawnPoint() -> CGPoint {
        return spawnPoints.randomElement() ?? CGPoint(x: screenBounds.midX, y: screenBounds.minY - 50)
    }

    private func maintainPenguinCount() {
        // This is handled by the service layer when adjusting penguin count
    }

    private func respawnAllPenguins() {
        let targetCount = penguins.count

        // Remove all penguins
        penguins.removeAll()

        // Respawn them
        spawnInitialPenguins(count: targetCount)
    }

    private func notifyPenguinsUpdated() {
        onPenguinsUpdated?(penguins)
    }
}