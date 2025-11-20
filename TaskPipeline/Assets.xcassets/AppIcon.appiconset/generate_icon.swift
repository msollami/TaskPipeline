#!/usr/bin/env swift

import Foundation
import AppKit
import CoreGraphics

// Create a 1024x1024 image with gradient background and clock icon
let size = CGSize(width: 1024, height: 1024)
let image = NSImage(size: size)

image.lockFocus()

// Draw gradient background (blue to purple)
let gradient = NSGradient(colors: [
    NSColor(red: 0.39, green: 0.47, blue: 0.83, alpha: 1.0),
    NSColor(red: 0.58, green: 0.39, blue: 0.83, alpha: 1.0)
])!
gradient.draw(in: NSRect(origin: .zero, size: size), angle: 135)

// Draw clock icon
let center = CGPoint(x: size.width / 2, y: size.height / 2)
let radius = size.width / 3

// Clock circle outline
let circlePath = NSBezierPath(ovalIn: CGRect(
    x: center.x - radius,
    y: center.y - radius,
    width: radius * 2,
    height: radius * 2
))
NSColor.white.setStroke()
circlePath.lineWidth = size.width / 30
circlePath.stroke()

// Clock hands (hour and minute)
NSColor.white.setStroke()

// Hour hand (pointing up-left)
let hourHand = NSBezierPath()
hourHand.move(to: center)
hourHand.line(to: CGPoint(x: center.x, y: center.y + radius / 2))
hourHand.lineWidth = size.width / 40
hourHand.stroke()

// Minute hand (pointing right)
let minuteHand = NSBezierPath()
minuteHand.move(to: center)
minuteHand.line(to: CGPoint(x: center.x + radius / 3, y: center.y))
minuteHand.lineWidth = size.width / 40
minuteHand.stroke()

image.unlockFocus()

// Save as PNG
if let tiffData = image.tiffRepresentation,
   let bitmapImage = NSBitmapImageRep(data: tiffData),
   let pngData = bitmapImage.representation(using: .png, properties: [:]) {
    try! pngData.write(to: URL(fileURLWithPath: "/tmp/icon_base.png"))
    print("Created base icon at /tmp/icon_base.png")
}
