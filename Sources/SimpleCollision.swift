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
    private var groundSurfaces: [WindowSurface] = []  // One ground per screen
    private var hasShownScreenInfo = false

    func updateWindows(_ windows: [SimpleWindow], dockBounds: CGRect? = nil) {
        windowSurfaces.removeAll()

        // Debug multi-monitor setup (only show once at startup)
        let allScreens = NSScreen.screens
        if !hasShownScreenInfo && windowSurfaces.isEmpty {
            print("Multi-monitor setup: \(allScreens.count) screens detected")
            hasShownScreenInfo = true
        }

        for window in windows {
            // Filter reasonable windows
            if window.bounds.width > 50 && window.bounds.height > 30 {

                // Convert CGWindow coordinates to global AppKit coordinates
                // CGWindow: Y=0 at top of the MAIN screen (with menu bar), Y increases downward
                // AppKit: Y=0 at bottom of the PRIMARY screen (screens[0]), Y increases upward
                //
                // To convert CGWindow Y to AppKit Y:
                // 1. CGWindow Y=0 is at top of main screen (NSScreen.main)
                // 2. Main screen in AppKit has frame.maxY at its top
                // 3. AppKit Y = mainScreen.maxY - CGWindow.Y
                let mainScreen = NSScreen.main ?? NSScreen.screens[0]
                let appKitY = mainScreen.frame.maxY - window.bounds.minY

                let surface = WindowSurface(
                    left: window.bounds.minX,
                    right: window.bounds.maxX,
                    top: appKitY,
                    windowID: window.id
                )


                // Add window surface if it's in a reasonable range (filter out extreme values)
                // Use primary screen height as reference
                if surface.top > -600 && surface.top < 2000 {
                    windowSurfaces.append(surface)
                }
            }
        }

        // Sort by height (lowest first)
        windowSurfaces.sort { $0.top < $1.top }

        // Add ground surfaces for ALL screens
        groundSurfaces.removeAll()
        for screen in allScreens {
            let screenFrame = screen.frame
            // Full-width baseline: catches penguins falling past either side of the Dock.
            let ground = WindowSurface(
                left: screenFrame.minX,
                right: screenFrame.maxX,
                top: screenFrame.minY,
                windowID: nil
            )
            groundSurfaces.append(ground)
        }

        // Add the Dock as a narrow surface at its actual width, if we got bounds.
        // CGWindow Y is measured from the top of the main screen downward; convert
        // to AppKit (origin bottom-left, Y up).
        if let dock = dockBounds {
            let mainScreen = NSScreen.main ?? NSScreen.screens[0]
            let dockTopAppKit = mainScreen.frame.maxY - dock.minY
            let dockSurface = WindowSurface(
                left: dock.minX,
                right: dock.maxX,
                top: dockTopAppKit,
                windowID: nil
            )
            groundSurfaces.append(dockSurface)
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

        // Check ground collision for all screens
        for ground in groundSurfaces {
            if ground.contains(x: penguinX) &&
               nextY <= ground.top + 5 {
                return ground
            }
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

        // Check all ground surfaces
        for ground in groundSurfaces {
            if ground.contains(x: x) && abs(y - ground.top) < 10 {
                return ground
            }
        }

        return nil
    }

    func getAllSurfaces() -> [WindowSurface] {
        var all = windowSurfaces
        all.append(contentsOf: groundSurfaces)
        return all
    }
}