//
//  MacPenguinsService.swift
//  MacPenguins
//
//  Created by MacPenguins on 26/11/2024.
//

import Foundation
import CoreGraphics
import AppKit

class MacPenguinsService {

    // Core components
    private let windowManager: SimpleWindowManager
    private let penguinEngine: PenguinEngine
    private let animationRenderer: SimpleRenderer
    private let themeManager: ThemeManager
    private let collisionDetector: CollisionDetector

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
        self.themeManager = ThemeManager()
        self.collisionDetector = CollisionDetector()
        self.animationRenderer = SimpleRenderer()
        self.penguinEngine = PenguinEngine(
            themeManager: themeManager,
            collisionDetector: collisionDetector
        )

        setupComponents()
    }

    deinit {
        stop()
    }

    // MARK: - Public Interface

    func start() {
        guard !isRunning else { return }

        print("Starting MacPenguins service...")

        // Load default theme
        do {
            try themeManager.loadTheme(named: currentTheme)
        } catch {
            print("Failed to load theme '\(currentTheme)': \(error)")
            return
        }

        // Setup animation rendering
        animationRenderer.setupOverlayWindows()

        // Initialize penguins
        penguinEngine.spawnInitialPenguins(count: penguinCount)

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
        penguinEngine.removeAllPenguins()

        isRunning = false
        print("MacPenguins service stopped")
    }

    func setPenguinCount(_ count: Int) {
        penguinCount = max(0, min(count, 100)) // Limit between 0 and 100

        if isRunning {
            penguinEngine.adjustPenguinCount(to: penguinCount)
        }
    }

    func setTheme(_ themeName: String) {
        currentTheme = themeName

        if isRunning {
            do {
                try themeManager.loadTheme(named: themeName)
                penguinEngine.reloadWithNewTheme()
                print("Switched to theme: \(themeName)")
            } catch {
                print("Failed to switch to theme '\(themeName)': \(error)")
            }
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

        // Configure penguin engine callbacks
        penguinEngine.onPenguinsUpdated = { [weak self] penguins in
            self?.animationRenderer.updatePenguins(penguins)
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
            print("🔄 First update() call - main loop is running!")
        }

        // Update collision data
        let windows = windowManager.getCurrentSpaceWindows()
        collisionDetector.updateWindowBounds(windows.map { $0.bounds })

        // Debug: Always print window count for first few seconds
        debugCounter += 1
        if debugCounter < 10 || debugCounter % 60 == 0 {
            print("🪟 Update \(debugCounter): Detected \(windows.count) windows for collision")
            if windows.count > 0 {
                print("   First window: \(windows[0].bounds)")
            }
        }

        // Update penguin physics and behavior
        penguinEngine.update()

        // Rendering is handled by the renderer via callbacks
    }

    private func handleWindowsChanged() {
        // Windows have changed - penguins will adapt automatically via collision detection
        print("Windows configuration changed")
    }

    private func handleSpaceChanged() {
        // Space/desktop changed - hide penguins briefly then respawn
        print("Desktop space changed")

        penguinEngine.handleSpaceChange()

        // Update overlay windows for new space
        animationRenderer.handleSpaceChange()
    }
}