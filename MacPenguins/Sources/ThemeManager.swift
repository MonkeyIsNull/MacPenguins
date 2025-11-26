//
//  ThemeManager.swift
//  MacPenguins
//
//  Created by MacPenguins on 26/11/2024.
//

import Foundation
import AppKit

struct ThemeInfo {
    let name: String
    let path: String
    let frameDelay: Int
    let penguinTypes: [String]
}

struct PenguinTypeInfo {
    let name: String
    let size: CGSize
    let speed: CGFloat
    let frames: Int
    let directions: Int
}

class ThemeManager {

    // Theme data
    private var currentTheme: ThemeInfo?
    private var penguinTypes: [String: PenguinTypeInfo] = [:]
    private var sprites: [String: [PenguinState: [PenguinDirection: [NSImage]]]] = [:]

    // Default configuration
    private let defaultFrameDelay: Int = 60
    private let defaultSize: CGSize = CGSize(width: 32, height: 32)
    private let defaultSpeed: CGFloat = 2.0

    // Theme search paths
    private let themeDirectories: [String]

    init() {
        // Set up theme search paths
        let bundlePath = Bundle.main.bundlePath
        let userThemePath = NSHomeDirectory() + "/Library/Application Support/MacPenguins/Themes"

        themeDirectories = [
            bundlePath + "/Contents/Resources/Themes",
            userThemePath,
            "./MacPenguins/Themes",
            "./Themes"
        ]

        setupDefaultTheme()
    }

    // MARK: - Public Interface

    func loadTheme(named themeName: String) throws {
        print("Loading theme: \(themeName)")

        guard let themePath = findThemeDirectory(named: themeName) else {
            throw ThemeError.themeNotFound(themeName)
        }

        // Load theme configuration
        let themeInfo = try loadThemeConfig(at: themePath, name: themeName)
        currentTheme = themeInfo

        // Load penguin type configurations
        try loadPenguinTypes(at: themePath)

        // Load sprite assets
        try loadSprites(at: themePath)

        print("Successfully loaded theme: \(themeName)")
    }

    func getAvailableThemes() -> [String] {
        var themes: Set<String> = []

        for directory in themeDirectories {
            let url = URL(fileURLWithPath: directory)
            if let contents = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil) {
                for item in contents {
                    if item.hasDirectoryPath {
                        themes.insert(item.lastPathComponent)
                    }
                }
            }
        }

        return Array(themes).sorted()
    }

    func getAvailablePenguinTypes() -> [String] {
        return Array(penguinTypes.keys)
    }

    func getPenguinSize(for type: String) -> CGSize {
        return penguinTypes[type]?.size ?? defaultSize
    }

    func getPenguinSpeed(for type: String) -> CGFloat {
        return penguinTypes[type]?.speed ?? defaultSpeed
    }

    func getFrameDelay() -> Int {
        return currentTheme?.frameDelay ?? defaultFrameDelay
    }

    func getSprites(for penguinType: String) -> [PenguinState: [PenguinDirection: [NSImage]]]? {
        return sprites[penguinType]
    }

    func getCurrentThemeName() -> String? {
        return currentTheme?.name
    }

    // MARK: - Private Methods

    private func setupDefaultTheme() {
        // Set up a basic default theme
        currentTheme = ThemeInfo(
            name: "Default",
            path: "",
            frameDelay: defaultFrameDelay,
            penguinTypes: ["normal"]
        )

        penguinTypes["normal"] = PenguinTypeInfo(
            name: "normal",
            size: defaultSize,
            speed: defaultSpeed,
            frames: 8,
            directions: 2
        )

        // Create basic colored rectangle sprites for default theme
        sprites["normal"] = createDefaultSprites()
    }

    private func findThemeDirectory(named themeName: String) -> String? {
        for directory in themeDirectories {
            let themePath = directory + "/" + themeName
            if FileManager.default.fileExists(atPath: themePath) {
                return themePath
            }
        }
        return nil
    }

    private func loadThemeConfig(at path: String, name: String) throws -> ThemeInfo {
        let configPath = path + "/config"

        var frameDelay = defaultFrameDelay
        var penguinTypes: [String] = ["normal"]

        // Try to load config file
        if FileManager.default.fileExists(atPath: configPath) {
            let configContent = try String(contentsOfFile: configPath)
            let config = parseThemeConfig(configContent)

            frameDelay = config["delay"].flatMap(Int.init) ?? defaultFrameDelay

            // Extract penguin types from config (simplified parsing)
            if configContent.contains("skateboarder") {
                penguinTypes.append("skateboarder")
            }
        }

        return ThemeInfo(
            name: name,
            path: path,
            frameDelay: frameDelay,
            penguinTypes: penguinTypes
        )
    }

    private func parseThemeConfig(_ content: String) -> [String: String] {
        var config: [String: String] = [:]

        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty && !trimmed.hasPrefix("#") {
                let parts = trimmed.components(separatedBy: " ")
                if parts.count >= 2 {
                    config[parts[0]] = parts[1]
                }
            }
        }

        return config
    }

    private func loadPenguinTypes(at path: String) throws {
        guard let theme = currentTheme else { return }

        penguinTypes.removeAll()

        for typeName in theme.penguinTypes {
            // Load penguin type configuration
            let typeConfig = try loadPenguinTypeConfig(at: path, typeName: typeName)
            penguinTypes[typeName] = typeConfig
        }

        // Ensure we have at least one penguin type
        if penguinTypes.isEmpty {
            penguinTypes["normal"] = PenguinTypeInfo(
                name: "normal",
                size: defaultSize,
                speed: defaultSpeed,
                frames: 8,
                directions: 2
            )
        }
    }

    private func loadPenguinTypeConfig(at path: String, typeName: String) throws -> PenguinTypeInfo {
        // For now, use default values
        // In a full implementation, this would parse penguin-specific config
        return PenguinTypeInfo(
            name: typeName,
            size: defaultSize,
            speed: typeName == "skateboarder" ? defaultSpeed * 1.5 : defaultSpeed,
            frames: 8,
            directions: 2
        )
    }

    private func loadSprites(at path: String) throws {
        sprites.removeAll()

        for (typeName, _) in penguinTypes {
            let penguinSprites = try loadSpritesForPenguinType(at: path, typeName: typeName)
            sprites[typeName] = penguinSprites
        }
    }

    private func loadSpritesForPenguinType(at path: String, typeName: String) throws -> [PenguinState: [PenguinDirection: [NSImage]]] {
        var penguinSprites: [PenguinState: [PenguinDirection: [NSImage]]] = [:]

        // Try to load PNG files first, then fall back to XPM conversion
        for state in PenguinState.allCases {
            let stateName = getSpriteStateName(state)

            var stateSprites: [PenguinDirection: [NSImage]] = [:]

            // Load sprites for both directions
            for direction in [PenguinDirection.left, PenguinDirection.right] {
                let directionName = direction == .right ? "right" : "left"
                let spriteImages = try loadSpriteFrames(
                    at: path,
                    typeName: typeName,
                    stateName: stateName,
                    directionName: directionName
                )

                if !spriteImages.isEmpty {
                    stateSprites[direction] = spriteImages
                }
            }

            if !stateSprites.isEmpty {
                penguinSprites[state] = stateSprites
            }
        }

        // Fall back to default sprites if none found
        if penguinSprites.isEmpty {
            penguinSprites = createDefaultSprites()
        }

        return penguinSprites
    }

    private func loadSpriteFrames(at path: String, typeName: String, stateName: String, directionName: String) throws -> [NSImage] {
        var images: [NSImage] = []

        // Try different naming conventions
        let namingPatterns = [
            "\(typeName)_\(stateName)_\(directionName)",
            "\(stateName)_\(directionName)",
            "\(typeName)_\(stateName)",
            stateName
        ]

        for pattern in namingPatterns {
            // Try PNG files first
            for frameIndex in 0..<16 {
                let pngPath = "\(path)/\(pattern)_\(frameIndex).png"
                if FileManager.default.fileExists(atPath: pngPath),
                   let image = NSImage(contentsOfFile: pngPath) {
                    images.append(image)
                } else {
                    break
                }
            }

            if !images.isEmpty {
                break
            }

            // Try numbered files without frame index
            let singlePngPath = "\(path)/\(pattern).png"
            if FileManager.default.fileExists(atPath: singlePngPath),
               let image = NSImage(contentsOfFile: singlePngPath) {
                images.append(image)
                break
            }

            // Try XPM files (would need conversion utility)
            let xpmPath = "\(path)/\(pattern).xpm"
            if FileManager.default.fileExists(atPath: xpmPath) {
                if let image = try? convertXPMtoNSImage(at: xpmPath) {
                    images.append(image)
                    break
                }
            }
        }

        return images
    }

    private func getSpriteStateName(_ state: PenguinState) -> String {
        switch state {
        case .walker: return "walker"
        case .faller: return "faller"
        case .tumbler: return "tumbler"
        case .floater: return "floater"
        case .climber: return "climber"
        case .exit: return "exit"
        case .explosion: return "explosion"
        case .runner: return "runner"
        case .splatted: return "splatted"
        case .squashed: return "squashed"
        case .zapped: return "zapped"
        case .angel: return "angel"
        case .action0: return "reader"
        case .action1: return "sleeper"
        case .action2: return "action2"
        case .action3: return "action3"
        case .action4: return "action4"
        case .action5: return "action5"
        }
    }

    private func convertXPMtoNSImage(at path: String) throws -> NSImage {
        // Simplified XPM to NSImage conversion
        // In a real implementation, this would parse XPM format properly

        let xpmContent = try String(contentsOfFile: path)

        // For now, create a placeholder colored rectangle
        let size = NSSize(width: 32, height: 32)
        let image = NSImage(size: size)

        image.lockFocus()
        NSColor.blue.set()
        NSRect(origin: .zero, size: size).fill()
        image.unlockFocus()

        return image
    }

    private func createDefaultSprites() -> [PenguinState: [PenguinDirection: [NSImage]]] {
        var defaultSprites: [PenguinState: [PenguinDirection: [NSImage]]] = [:]

        let colors: [NSColor] = [.blue, .red, .green, .orange, .purple, .brown, .cyan, .magenta]

        for state in PenguinState.allCases {
            var stateSprites: [PenguinDirection: [NSImage]] = [:]

            for direction in [PenguinDirection.left, PenguinDirection.right] {
                var frames: [NSImage] = []

                // Create 8 frames with different colors
                for i in 0..<8 {
                    let color = colors[i % colors.count]
                    let frame = createColoredRectangleImage(size: defaultSize, color: color)
                    frames.append(frame)
                }

                stateSprites[direction] = frames
            }

            defaultSprites[state] = stateSprites
        }

        return defaultSprites
    }

    private func createColoredRectangleImage(size: CGSize, color: NSColor) -> NSImage {
        let image = NSImage(size: size)

        image.lockFocus()
        color.set()
        NSRect(origin: .zero, size: size).fill()

        // Add a simple border
        NSColor.black.set()
        NSRect(origin: .zero, size: size).frame()

        image.unlockFocus()

        return image
    }
}

// MARK: - Theme Errors

enum ThemeError: Error {
    case themeNotFound(String)
    case configurationError(String)
    case spriteLoadError(String)

    var localizedDescription: String {
        switch self {
        case .themeNotFound(let name):
            return "Theme '\(name)' not found"
        case .configurationError(let message):
            return "Theme configuration error: \(message)"
        case .spriteLoadError(let message):
            return "Sprite loading error: \(message)"
        }
    }
}