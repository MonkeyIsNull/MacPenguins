//
//  MacPenguinsService.swift
//  MacPenguins

import Foundation
import CoreGraphics
import AppKit

class MacPenguinsService {

    // Core components
    private let windowManager: SimpleWindowManager
    private let animationRenderer: BasicRenderer
    private let collision: SimpleCollision

    // Simple penguin management
    private var penguins: [SimplePenguin] = []

    // Service state
    private var isRunning = false
    private var updateTimer: Timer?

    // Configuration
    private var penguinCount: Int = 10
    private var currentTheme: String = "Penguins"

    // Debug
    private var debugCounter = 0

    init() {
        // Initialize core components
        self.windowManager = SimpleWindowManager()
        self.collision = SimpleCollision()
        self.animationRenderer = BasicRenderer()

        setupComponents()
    }

    deinit {
        stop()
    }

    // MARK: - Public Interface

    func start() {
        guard !isRunning else { return }

        print("Starting MacPenguins service...")

        // Setup animation rendering
        animationRenderer.setupOverlayWindows()

        // Initialize penguins
        spawnPenguins(count: penguinCount)

        // Start window monitoring
        windowManager.startMonitoring()

        // Start main update loop
        startUpdateLoop()

        isRunning = true
        print("MacPenguins service started with \(penguinCount) penguins")
        print("Update timer started, should update every 1/60 second")
    }

    func stop() {
        guard isRunning else { return }

        print("Stopping MacPenguins service...")

        stopUpdateLoop()
        windowManager.stopMonitoring()
        animationRenderer.cleanup()
        penguins.removeAll()

        isRunning = false
        print("MacPenguins service stopped")
    }

    func setPenguinCount(_ count: Int) {
        penguinCount = max(0, min(count, 100)) // Limit between 0 and 100

        if isRunning {
            adjustPenguinCount(to: penguinCount)
        }
    }


    // MARK: - Private Methods

    private func setupComponents() {
        // Configure window manager callbacks
        windowManager.onWindowsChanged = { [weak self] in
            self?.handleWindowsChanged()
        }

        windowManager.onSpaceChanged = { [weak self] in
            self?.handleSpaceChanged()
        }
    }

    private func startUpdateLoop() {
        // Run update loop at 60 FPS
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
            self?.update()
        }
    }

    private func stopUpdateLoop() {
        updateTimer?.invalidate()
        updateTimer = nil
    }

    private func update() {
        if debugCounter == 0 {
            print("First update() call - main loop is running!")
        }

        // Update collision data with current windows + Dock bounds
        let windows = windowManager.getCurrentSpaceWindows()
        let dockBounds = windowManager.getDockBounds()
        collision.updateWindows(windows, dockBounds: dockBounds)

        // Debug output
        debugCounter += 1
        if debugCounter < 5 || debugCounter % 180 == 0 {
            print("Update \(debugCounter): \(windows.count) windows, \(penguins.count) penguins")
        }

        // Update all penguins with simple physics
        for penguin in penguins {
            penguin.update(collision: collision)
        }

        // Update renderer with current penguins
        updateRenderer()
    }

    private func handleWindowsChanged() {
        // Windows have changed - penguins will adapt automatically via collision detection
        print("Windows configuration changed")
    }

    private func handleSpaceChanged() {
        // Space/desktop changed - hide penguins briefly then respawn
        print("Desktop space changed")

        // Remove all penguins and respawn
        penguins.removeAll()
        spawnPenguins(count: penguinCount)

        // Update overlay windows for new space
        animationRenderer.handleSpaceChange()
    }

    // MARK: - Penguin Management

    private func spawnPenguins(count: Int) {
        let mainScreen = NSScreen.main ?? NSScreen.screens[0]
        let screenFrame = mainScreen.frame

        for _ in 0..<count {
            // Use actual screen bounds (minX to maxX, not just width)
            let x = CGFloat.random(in: (screenFrame.minX + 100)...(screenFrame.maxX - 100))
            let y: CGFloat = screenFrame.maxY + 50 // Above screen's top edge
            let penguin = SimplePenguin(position: CGPoint(x: x, y: y))
            penguins.append(penguin)
        }

        print("Spawned \(count) penguins on screen: \(screenFrame)")
    }

    private func adjustPenguinCount(to targetCount: Int) {
        if targetCount > penguins.count {
            // Add penguins
            let toAdd = targetCount - penguins.count
            spawnPenguins(count: toAdd)
        } else if targetCount < penguins.count {
            // Remove excess penguins
            let toRemove = penguins.count - targetCount
            penguins.removeLast(toRemove)
        }
    }

    private func updateRenderer() {
        // BasicRenderer works directly with SimplePenguin
        animationRenderer.updatePenguins(penguins)
    }
}