//
//  CollisionDetector.swift
//  MacPenguins
//
//  Created by MacPenguins on 26/11/2024.
//

import Foundation
import CoreGraphics

enum CollisionType {
    case none
    case top      // Penguin is on top of window
    case bottom   // Penguin hit window from below
    case left     // Penguin hit left side of window
    case right    // Penguin hit right side of window
    case inside   // Penguin is inside window bounds
}

struct CollisionResult {
    let type: CollisionType
    let contactPoint: CGPoint
    let windowID: CGWindowID?
    let windowBounds: CGRect?

    static let none = CollisionResult(
        type: .none,
        contactPoint: CGPoint.zero,
        windowID: nil,
        windowBounds: nil
    )
}

class CollisionDetector {

    // Window data for collision detection
    private var windowBounds: [CGWindowID: CGRect] = [:]
    private var sortedWindows: [CGWindowID] = [] // Sorted by window level

    // Collision detection settings
    private let collisionMargin: CGFloat = 2.0
    private let walkingThreshold: CGFloat = 5.0 // Max height difference for walking

    // MARK: - Public Interface

    func updateWindowBounds(_ windows: [Window]) {
        windowBounds.removeAll()
        sortedWindows.removeAll()

        // Store window bounds and sort by level (higher level = on top)
        let sortedWindowList = windows.sorted { $0.level > $1.level }

        for window in sortedWindowList {
            windowBounds[window.id] = window.bounds
            sortedWindows.append(window.id)
        }

        print("Updated collision detection with \(windows.count) windows")
    }

    func updateWindowBounds(_ bounds: [CGRect]) {
        windowBounds.removeAll()
        sortedWindows.removeAll()

        // Create synthetic window IDs for bounds-only updates
        for (index, rect) in bounds.enumerated() {
            let syntheticID = CGWindowID(1000 + index)
            windowBounds[syntheticID] = rect
            sortedWindows.append(syntheticID)
        }
    }

    func checkCollision(rect: CGRect, velocity: CGPoint) -> CollisionResult {
        // Check collision with all windows in order (topmost first)
        for windowID in sortedWindows {
            guard let windowRect = windowBounds[windowID] else { continue }

            let collision = checkCollisionWithWindow(
                penguinRect: rect,
                velocity: velocity,
                windowRect: windowRect,
                windowID: windowID
            )

            if collision.type != .none {
                return collision
            }
        }

        return CollisionResult.none
    }

    func getWindowBounds(for windowID: CGWindowID) -> CGRect? {
        return windowBounds[windowID]
    }

    func findSupportingSurface(at point: CGPoint, maxDistance: CGFloat = 50.0) -> CGPoint? {
        // Find the nearest window top surface below the given point
        var nearestSurface: CGPoint?
        var nearestDistance: CGFloat = maxDistance

        for windowRect in windowBounds.values {
            // Check if point is horizontally within window bounds
            if point.x >= windowRect.minX && point.x <= windowRect.maxX {
                let surfaceY = windowRect.minY
                let distance = point.y - surfaceY

                if distance > 0 && distance < nearestDistance {
                    nearestDistance = distance
                    nearestSurface = CGPoint(x: point.x, y: surfaceY)
                }
            }
        }

        return nearestSurface
    }

    func isPointOnWindowSurface(_ point: CGPoint, tolerance: CGFloat = 5.0) -> Bool {
        for windowRect in windowBounds.values {
            // Check if point is on top edge of window
            if point.x >= windowRect.minX - tolerance &&
               point.x <= windowRect.maxX + tolerance &&
               abs(point.y - windowRect.minY) <= tolerance {
                return true
            }
        }
        return false
    }

    // MARK: - Private Methods

    private func checkCollisionWithWindow(
        penguinRect: CGRect,
        velocity: CGPoint,
        windowRect: CGRect,
        windowID: CGWindowID
    ) -> CollisionResult {

        // Expand window rect slightly for collision detection
        let expandedWindow = windowRect.insetBy(dx: -collisionMargin, dy: -collisionMargin)

        // Quick intersection test
        if !penguinRect.intersects(expandedWindow) {
            return CollisionResult.none
        }

        // Determine collision type based on penguin position and velocity
        let penguinCenter = CGPoint(
            x: penguinRect.midX,
            y: penguinRect.midY
        )

        // Check if penguin is inside window
        if windowRect.contains(penguinCenter) {
            return CollisionResult(
                type: .inside,
                contactPoint: penguinCenter,
                windowID: windowID,
                windowBounds: windowRect
            )
        }

        // Check collision with each edge of the window
        return checkEdgeCollision(
            penguinRect: penguinRect,
            velocity: velocity,
            windowRect: windowRect,
            windowID: windowID
        )
    }

    private func checkEdgeCollision(
        penguinRect: CGRect,
        velocity: CGPoint,
        windowRect: CGRect,
        windowID: CGWindowID
    ) -> CollisionResult {

        let penguinCenter = CGPoint(x: penguinRect.midX, y: penguinRect.midY)

        // Calculate distances to each edge
        let distanceToTop = penguinRect.maxY - windowRect.minY
        let distanceToBottom = windowRect.maxY - penguinRect.minY
        let distanceToLeft = penguinRect.maxX - windowRect.minX
        let distanceToRight = windowRect.maxX - penguinRect.minX

        // Find the closest edge that the penguin is intersecting
        let minDistance = min(distanceToTop, distanceToBottom, distanceToLeft, distanceToRight)

        if minDistance > collisionMargin {
            return CollisionResult.none
        }

        // Determine collision type based on closest edge and velocity
        if minDistance == distanceToTop && velocity.y >= 0 {
            // Collision with top of window (penguin landing on window)
            let contactPoint = CGPoint(x: penguinCenter.x, y: windowRect.minY)
            return CollisionResult(
                type: .top,
                contactPoint: contactPoint,
                windowID: windowID,
                windowBounds: windowRect
            )
        }
        else if minDistance == distanceToBottom && velocity.y <= 0 {
            // Collision with bottom of window (penguin hit window from below)
            let contactPoint = CGPoint(x: penguinCenter.x, y: windowRect.maxY)
            return CollisionResult(
                type: .bottom,
                contactPoint: contactPoint,
                windowID: windowID,
                windowBounds: windowRect
            )
        }
        else if minDistance == distanceToLeft && velocity.x >= 0 {
            // Collision with left side of window
            let contactPoint = CGPoint(x: windowRect.minX, y: penguinCenter.y)
            return CollisionResult(
                type: .left,
                contactPoint: contactPoint,
                windowID: windowID,
                windowBounds: windowRect
            )
        }
        else if minDistance == distanceToRight && velocity.x <= 0 {
            // Collision with right side of window
            let contactPoint = CGPoint(x: windowRect.maxX, y: penguinCenter.y)
            return CollisionResult(
                type: .right,
                contactPoint: contactPoint,
                windowID: windowID,
                windowBounds: windowRect
            )
        }

        return CollisionResult.none
    }

    // MARK: - Advanced Collision Detection

    func checkWalkingPath(from start: CGPoint, to end: CGPoint, penguinSize: CGSize) -> Bool {
        // Check if penguin can walk from start to end without falling off or hitting obstacles
        let stepSize: CGFloat = penguinSize.width / 4
        let steps = Int(abs(end.x - start.x) / stepSize) + 1

        for i in 0...steps {
            let progress = CGFloat(i) / CGFloat(steps)
            let checkPoint = CGPoint(
                x: start.x + (end.x - start.x) * progress,
                y: start.y
            )

            // Check if there's a surface to walk on
            let supportPoint = findSupportingSurface(at: checkPoint, maxDistance: walkingThreshold)
            if supportPoint == nil {
                return false
            }

            // Check for obstacles at walking height
            let walkingRect = CGRect(
                x: checkPoint.x - penguinSize.width / 2,
                y: checkPoint.y - penguinSize.height,
                width: penguinSize.width,
                height: penguinSize.height
            )

            if hasObstacleInPath(walkingRect) {
                return false
            }
        }

        return true
    }

    private func hasObstacleInPath(_ rect: CGRect) -> Bool {
        for windowRect in windowBounds.values {
            // Check if the walking path intersects with any window
            let obstacleRect = windowRect.insetBy(dx: -collisionMargin, dy: 0)
            if rect.intersects(obstacleRect) {
                return true
            }
        }
        return false
    }

    func getWalkableSurfaces() -> [CGRect] {
        // Return all window top surfaces that penguins can walk on
        var walkableSurfaces: [CGRect] = []

        for windowRect in windowBounds.values {
            // Create a thin rectangle representing the walkable surface on top of the window
            let surface = CGRect(
                x: windowRect.minX,
                y: windowRect.minY - collisionMargin,
                width: windowRect.width,
                height: collisionMargin * 2
            )
            walkableSurfaces.append(surface)
        }

        return walkableSurfaces
    }
}