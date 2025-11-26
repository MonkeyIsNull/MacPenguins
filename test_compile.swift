//
//  test_compile.swift
//  Simple test to verify our core structures compile
//

import Foundation
import CoreGraphics
import AppKit

// Test our basic enums and structs
let testState = PenguinState.walker
let testDirection = PenguinDirection.right
let testPhysics = PenguinPhysics()

print("Basic enums compile successfully")
print("PenguinState.walker = \(testState)")
print("PenguinDirection.right = \(testDirection)")

// Test penguin creation
let testPenguin = Penguin(position: CGPoint(x: 100, y: 100))
print("Penguin created at position: \(testPenguin.position)")
print("Penguin state: \(testPenguin.state)")

// Test window detection structures
let testWindow = WindowInfo()
testWindow.bounds = CGRect(x: 0, y: 0, width: 800, height: 600)
testWindow.windowID = 12345

print("WindowInfo created with bounds: \(testWindow.bounds)")

print("All core structures compile successfully!")