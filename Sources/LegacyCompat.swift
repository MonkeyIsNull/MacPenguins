//
//  LegacyCompat.swift
//  MacPenguins - Compatibility layer for old renderer

import Foundation
import CoreGraphics

// Legacy penguin state for renderer compatibility
enum PenguinState {
    case walker
    case faller
    case splatted
}

enum PenguinDirection {
    case left
    case right
}

// Minimal legacy penguin class for renderer
class Penguin {
    var position: CGPoint
    var state: PenguinState
    var size: CGSize
    var isVisible: Bool

    init(position: CGPoint) {
        self.position = position
        self.state = .faller
        self.size = CGSize(width: 30, height: 30)
        self.isVisible = true
    }
}