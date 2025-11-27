//
//  SimpleCollision.swift
//  MacPenguins - Simple collision system that actually works

import Foundation
import CoreGraphics
import AppKit

struct WindowSurface {
    let left: CGFloat
    let right: CGFloat
    let top: CGFloat
    let windowID: CGWindowID?

    func contains(x: CGFloat) -> Bool {
        return x >= left && x <= right
    }

    var width: CGFloat {
        return right - left
    }
}

class SimpleCollision {
    private var windowSurfaces: [WindowSurface] = []
    private var groundSurface: WindowSurface?

    func updateWindows(_ windows: [SimpleWindow]) {
        windowSurfaces.removeAll()

        // Convert windows to surfaces
        let screenHeight = NSScreen.main?.frame.height ?? 900

        for window in windows {
            // Filter reasonable windows
            if window.bounds.width > 50 && window.bounds.height > 30 {
                let surface = WindowSurface(
                    left: window.bounds.minX,
                    right: window.bounds.maxX,
                    top: screenHeight - window.bounds.minY, // Convert to AppKit coordinates
                    windowID: window.id
                )



                // Re-enable window surfaces - penguins should land on open windows
                if surface.top > 50 && surface.top < screenHeight - 50 {
                    windowSurfaces.append(surface)
                    print("🪟 Added window surface: \(window.ownerName) at Y=\(surface.top) (width: \(surface.right - surface.left))")
                }
            }
        }

        // Sort by height (lowest first)
        windowSurfaces.sort { $0.top < $1.top }

        // Add ground surface
        let screenWidth = NSScreen.main?.frame.width ?? 1440
        groundSurface = WindowSurface(
            left: 0,
            right: screenWidth,
            top: 20, // Ground level
            windowID: nil
        )

    }

    func checkFallingCollision(penguinX: CGFloat, penguinY: CGFloat, nextY: CGFloat) -> WindowSurface? {
        // Check window surfaces (in order from lowest to highest)
        for surface in windowSurfaces {
            if surface.contains(x: penguinX) &&
               penguinY > surface.top &&
               nextY <= surface.top + 5 {
                return surface
            }
        }

        // Check ground collision
        if let ground = groundSurface,
           nextY <= ground.top + 5 {
            return ground
        }

        return nil
    }

    func getSurfaceForWalking(at x: CGFloat, y: CGFloat) -> WindowSurface? {
        // Find the surface we're currently on
        for surface in windowSurfaces {
            if surface.contains(x: x) && abs(y - surface.top) < 10 {
                return surface
            }
        }

        // Check ground
        if let ground = groundSurface, abs(y - ground.top) < 10 {
            return ground
        }

        return nil
    }

    func getAllSurfaces() -> [WindowSurface] {
        var all = windowSurfaces
        if let ground = groundSurface {
            all.append(ground)
        }
        return all
    }
}