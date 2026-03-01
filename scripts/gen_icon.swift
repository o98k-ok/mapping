#!/usr/bin/env swift
import AppKit

let size = 1024
let img = NSImage(size: NSSize(width: size, height: size))
img.lockFocus()

let ctx = NSGraphicsContext.current!.cgContext
let rect = CGRect(x: 0, y: 0, width: size, height: size)

// Gradient background
let colors = [
    CGColor(red: 0.35, green: 0.55, blue: 0.94, alpha: 1.0),
    CGColor(red: 0.78, green: 0.47, blue: 0.87, alpha: 1.0),
]
let gradient = CGGradient(
    colorsSpace: CGColorSpaceCreateDeviceRGB(),
    colors: colors as CFArray,
    locations: [0, 1]
)!
ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: size), end: CGPoint(x: size, y: 0), options: [])

// ⌘ symbol centered
let attrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 620, weight: .light),
    .foregroundColor: NSColor.white,
]
let str = NSAttributedString(string: "⌘", attributes: attrs)
let s = str.size()
str.draw(at: NSPoint(x: (CGFloat(size) - s.width) / 2, y: (CGFloat(size) - s.height) / 2))

img.unlockFocus()

let tiff = img.tiffRepresentation!
let bmp = NSBitmapImageRep(data: tiff)!
let png = bmp.representation(using: .png, properties: [:])!
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon_1024.png"
try! png.write(to: URL(fileURLWithPath: out))
print("Generated \(out)")
