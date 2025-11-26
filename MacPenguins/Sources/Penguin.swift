//
//  Penguin.swift
//  MacPenguins
//
//  Created by MacPenguins on 26/11/2024.
//

import Foundation
import CoreGraphics

// Penguin state enum matching original xpenguins states
enum PenguinState: Int, CaseIterable {
    case walker = 0      // Walking along window tops
    case faller = 1      // Falling from screen top
    case tumbler = 2     // Falling after dropping off windows
    case floater = 3     // Flying/floating movement
    case climber = 4     // Climbing window sides or screen edges
    case exit = 5        // Exit animation sequence
    case explosion = 6   // Simple explosion (no blood)
    case runner = 7      // Faster walking variant
    case splatted = 8    // Landing death animation
    case squashed = 9    // Caught under windows
    case zapped = 10     // Mouse interaction death
    case angel = 11      // Ascending after death
    case action0 = 12    // Custom action (reading)
    case action1 = 13    // Custom action (sleeping)
    case action2 = 14    // Custom action
    case action3 = 15    // Custom action
    case action4 = 16    // Custom action
    case action5 = 17    // Custom action

    var isDeadState: Bool {
        switch self {
        case .splatted, .squashed, .zapped, .angel, .explosion:
            return true
        default:
            return false
        }
    }

    var isActionState: Bool {
        switch self {
        case .action0, .action1, .action2, .action3, .action4, .action5:
            return true
        default:
            return false
        }
    }
}

enum PenguinDirection: Int {
    case left = 0
    case right = 1

    var opposite: PenguinDirection {
        return self == .left ? .right : .left
    }
}

struct PenguinPhysics {
    var velocity: CGPoint = CGPoint.zero
    var acceleration: CGPoint = CGPoint.zero
    var terminalVelocity: CGFloat = 8.0
    var gravity: CGFloat = 0.5
    var bounce: CGFloat = 0.3

    mutating func applyGravity() {
        acceleration.y += gravity
        velocity.y = min(velocity.y + acceleration.y, terminalVelocity)
    }

    mutating func applyFriction() {
        velocity.x *= 0.95
    }

    mutating func reset() {
        velocity = CGPoint.zero
        acceleration = CGPoint.zero
    }
}

class Penguin {

    // Core properties
    let id: UUID = UUID()
    var position: CGPoint
    var state: PenguinState
    var direction: PenguinDirection
    var physics: PenguinPhysics

    // Animation properties
    var currentFrame: Int = 0
    var frameCounter: Int = 0
    var frameDelay: Int
    var animationLoop: Int = 0

    // State timing
    var stateTimer: Int = 0
    var stateDuration: Int = 0

    // Window association
    var associatedWindowID: CGWindowID?
    var lastAssociatedPosition: CGPoint?

    // Theme properties
    var penguinType: String
    var size: CGSize

    // Behavioral properties
    var speed: CGFloat
    var isVisible: Bool = true

    init(
        position: CGPoint,
        penguinType: String = "normal",
        frameDelay: Int = 60
    ) {
        self.position = position
        self.state = .faller // Start as faller from top of screen
        self.direction = Bool.random() ? .left : .right
        self.physics = PenguinPhysics()
        self.frameDelay = frameDelay
        self.penguinType = penguinType
        self.size = CGSize(width: 32, height: 32) // Default size
        self.speed = 2.0
        self.stateDuration = Int.random(in: 120...300) // 2-5 seconds at 60fps
    }

    // MARK: - Public Methods

    func update() {
        updateAnimation()
        updatePhysics()
        updateState()
    }

    func changeState(to newState: PenguinState) {
        guard state != newState else { return }

        state = newState
        currentFrame = 0
        frameCounter = 0
        stateTimer = 0
        animationLoop = 0

        // Reset physics for certain states
        switch newState {
        case .walker, .runner:
            physics.reset()
            physics.velocity.x = (direction == .right ? speed : -speed)

        case .faller, .tumbler:
            physics.velocity.x *= 0.5 // Reduce horizontal speed when falling

        case .floater:
            physics.reset()
            physics.velocity.x = (direction == .right ? speed * 0.5 : -speed * 0.5)
            physics.velocity.y = CGFloat.random(in: -1...1)

        case .climber:
            physics.reset()
            physics.velocity.y = -speed * 0.7

        default:
            physics.reset()
        }

        // Set state duration
        setStateDuration(for: newState)
    }

    func reverseDirection() {
        direction = direction.opposite
        physics.velocity.x = -physics.velocity.x
    }

    func kill(cause: PenguinState) {
        guard !state.isDeadState else { return }

        switch cause {
        case .explosion, .splatted, .squashed, .zapped:
            changeState(to: cause)
        default:
            changeState(to: .explosion)
        }
    }

    func respawn() {
        // Reset penguin to falling state at random screen position
        state = .faller
        direction = Bool.random() ? .left : .right
        physics.reset()
        currentFrame = 0
        frameCounter = 0
        stateTimer = 0
        isVisible = true
        associatedWindowID = nil
        lastAssociatedPosition = nil
    }

    // MARK: - Private Methods

    private func updateAnimation() {
        frameCounter += 1

        if frameCounter >= frameDelay {
            frameCounter = 0
            currentFrame += 1

            // Handle animation loops based on state
            let maxFrames = getMaxFramesForState()
            if currentFrame >= maxFrames {
                handleAnimationLoop()
            }
        }
    }

    private func updatePhysics() {
        switch state {
        case .walker, .runner:
            // Walking physics - maintain horizontal speed
            physics.velocity.x = (direction == .right ? speed : -speed)
            if state == .runner {
                physics.velocity.x *= 1.5
            }

        case .faller, .tumbler:
            // Falling physics
            physics.applyGravity()
            physics.applyFriction()

        case .floater:
            // Floating physics - gentle movement
            physics.velocity.x += CGFloat.random(in: -0.2...0.2)
            physics.velocity.y += CGFloat.random(in: -0.2...0.2)
            physics.velocity.x = max(-2, min(2, physics.velocity.x))
            physics.velocity.y = max(-2, min(2, physics.velocity.y))

        case .climber:
            // Climbing physics - vertical movement
            physics.velocity.y = -speed * 0.7
            physics.velocity.x = 0

        default:
            // Static or special states
            physics.reset()
        }

        // Apply velocity to position
        position.x += physics.velocity.x
        position.y += physics.velocity.y
    }

    private func updateState() {
        stateTimer += 1

        // Check for state transitions
        switch state {
        case .faller:
            // Will transition to walker/tumbler when hitting surface (handled by collision detection)
            break

        case .walker, .runner:
            // Occasionally change to action states or runner/walker
            if stateTimer > stateDuration && Int.random(in: 0...100) < 5 {
                if state == .walker && Int.random(in: 0...100) < 30 {
                    changeState(to: .runner)
                } else if state == .runner && Int.random(in: 0...100) < 50 {
                    changeState(to: .walker)
                } else if Int.random(in: 0...100) < 20 {
                    let actionStates: [PenguinState] = [.action0, .action1]
                    changeState(to: actionStates.randomElement()!)
                }
            }

        case .tumbler:
            // Will transition when hitting ground (handled by collision detection)
            break

        case .floater:
            // Random state changes for floating
            if stateTimer > stateDuration && Int.random(in: 0...100) < 10 {
                changeState(to: Bool.random() ? .walker : .faller)
            }

        case .climber:
            // Stop climbing after a while
            if stateTimer > 60 { // 1 second
                changeState(to: .walker)
            }

        case .splatted, .squashed, .zapped:
            // Death states - transition to angel
            if stateTimer > 120 { // 2 seconds
                changeState(to: .angel)
            }

        case .angel:
            // Ascending - respawn after reaching top
            if stateTimer > 180 { // 3 seconds
                respawn()
            }

        case .action0, .action1, .action2, .action3, .action4, .action5:
            // Action states - return to walking after duration
            if stateTimer > stateDuration {
                changeState(to: .walker)
            }

        case .explosion:
            // Short explosion animation
            if stateTimer > 30 { // 0.5 seconds
                changeState(to: .splatted)
            }

        case .exit:
            // Mark for removal
            isVisible = false

        default:
            break
        }
    }

    private func getMaxFramesForState() -> Int {
        // This would normally come from theme data
        switch state {
        case .walker: return 8
        case .runner: return 8
        case .faller, .tumbler: return 4
        case .floater: return 6
        case .climber: return 6
        case .explosion: return 8
        case .splatted: return 8
        case .squashed: return 6
        case .zapped: return 10
        case .angel: return 8
        case .action0: return 12 // Reading
        case .action1: return 6  // Sleeping
        case .exit: return 8
        default: return 4
        }
    }

    private func handleAnimationLoop() {
        animationLoop += 1

        switch state {
        case .walker, .runner, .floater:
            // Loop indefinitely
            currentFrame = 0

        case .action0, .action1, .action2, .action3, .action4, .action5:
            // Loop a few times then return to walking
            if animationLoop >= 3 {
                changeState(to: .walker)
            } else {
                currentFrame = 0
            }

        case .angel:
            // Move up and fade
            position.y -= 2
            currentFrame = 0

        case .explosion, .splatted, .squashed, .zapped:
            // Play once then hold last frame
            if animationLoop == 0 {
                currentFrame = getMaxFramesForState() - 1
                animationLoop = 1
            }

        default:
            currentFrame = 0
        }
    }

    private func setStateDuration(for state: PenguinState) {
        switch state {
        case .walker, .runner:
            stateDuration = Int.random(in: 180...600) // 3-10 seconds

        case .action0, .action1, .action2, .action3, .action4, .action5:
            stateDuration = Int.random(in: 120...300) // 2-5 seconds

        case .floater:
            stateDuration = Int.random(in: 300...900) // 5-15 seconds

        default:
            stateDuration = Int.random(in: 60...180) // 1-3 seconds
        }
    }
}