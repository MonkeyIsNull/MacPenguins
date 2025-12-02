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
    private var hasShownScreenInfo = false

    func updateWindows(_ windows: [SimpleWindow]) {
        windowSurfaces.removeAll()

        // Debug multi-monitor setup (only show once at startup)
        let allScreens = NSScreen.screens
        if !hasShownScreenInfo && windowSurfaces.isEmpty {
            print("🖥️ \(allScreens.count) screens detected:")
            for (i, screen) in allScreens.enumerated() {
                print("   Screen \(i): \(screen.frame)")
            }
            hasShownScreenInfo = true
        }

        for window in windows {
            // Filter reasonable windows
            if window.bounds.width > 50 && window.bounds.height > 30 {

                // Find which screen this window is on
                let windowScreen = findScreenForWindow(window, allScreens: allScreens)
                let screenFrame = windowScreen.frame

                // Convert CGWindow coordinates to AppKit coordinates
                // CGWindow Y=0 is at top of primary display, AppKit Y=0 is at bottom of screen
                // We need to convert from global CGWindow coords to local screen coords
                let localWindowY = window.bounds.minY - screenFrame.minY // Convert to screen-relative
                let appKitY = screenFrame.height - localWindowY // Convert to AppKit coordinates

                let surface = WindowSurface(
                    left: window.bounds.minX,
                    right: window.bounds.maxX,
                    top: appKitY,
                    windowID: window.id
                )

                // Debug coordinate conversion (only show once at startup)
                if windowSurfaces.count < 3 && !hasShownScreenInfo {
                    print("🔧 Window \(window.ownerName): X=\(Int(surface.left)), Y=\(Int(surface.top)), W=\(Int(surface.right - surface.left))")
                }

                // Re-enable window surfaces - penguins should land on open windows
                if surface.top > 50 && surface.top < screenFrame.height - 50 {
                    windowSurfaces.append(surface)
                }
            }
        }

        // Sort by height (lowest first)
        windowSurfaces.sort { $0.top < $1.top }

        // Add simple ground surface
        let mainScreen = NSScreen.main ?? NSScreen.screens[0]
        let screenFrame = mainScreen.frame
        groundSurface = WindowSurface(
            left: screenFrame.minX,
            right: screenFrame.maxX,
            top: 20, // Ground level
            windowID: nil
        )

        if !hasShownScreenInfo {
            print("🌍 Ground surface: X=\(Int(screenFrame.minX)) to \(Int(screenFrame.maxX)), Y=20")
        }

    }

    private func findScreenForWindow(_ window: SimpleWindow, allScreens: [NSScreen]) -> NSScreen {
        // Find the screen that contains this window's center point
        let windowCenterX = window.bounds.midX
        let windowCenterY = window.bounds.midY

        for screen in allScreens {
            let screenFrame = screen.frame
            // Check if window center is within this screen's bounds
            if windowCenterX >= screenFrame.minX &&
               windowCenterX <= screenFrame.maxX &&
               windowCenterY >= screenFrame.minY &&
               windowCenterY <= screenFrame.maxY {
                return screen
            }
        }

        // Fallback to main screen if no match found
        return NSScreen.main ?? allScreens[0]
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
           ground.contains(x: penguinX) &&
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
        if let ground = groundSurface, ground.contains(x: x) && abs(y - ground.top) < 10 {
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