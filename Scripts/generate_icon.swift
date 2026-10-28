import Cocoa
import CoreGraphics

func createIconData() -> Data {
    let width = 1024
    let height = 1024
    
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: width,
        pixelsHigh: height,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    
    let nsCtx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = nsCtx
    let ctx = nsCtx.cgContext
    
    ctx.clear(CGRect(x: 0, y: 0, width: width, height: height))
    
    let iconRect = CGRect(x: 100, y: 100, width: 824, height: 824)
    let cornerRadius: CGFloat = 185
    let squirclePath = CGPath(roundedRect: iconRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    
    // 1. Drop shadow under squircle
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -18), blur: 32, color: CGColor(gray: 0, alpha: 0.38))
    ctx.setFillColor(NSColor(red: 0.15, green: 0.2, blue: 0.4, alpha: 0.8).cgColor)
    ctx.addPath(squirclePath)
    ctx.fillPath()
    ctx.restoreGState()
    
    // 2. Base gradient background
    ctx.saveGState()
    ctx.addPath(squirclePath)
    ctx.clip()
    
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bgColors = [
        NSColor(red: 0.22, green: 0.42, blue: 0.98, alpha: 1.0).cgColor, // Vibrant Blue (#386BFA)
        NSColor(red: 0.50, green: 0.25, blue: 0.92, alpha: 1.0).cgColor, // Purple (#8040EB)
        NSColor(red: 0.10, green: 0.12, blue: 0.28, alpha: 1.0).cgColor  // Midnight Navy (#1A1F47)
    ] as CFArray
    let bgLocations: [CGFloat] = [0.0, 0.55, 1.0]
    if let gradient = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: bgLocations) {
        ctx.drawLinearGradient(
            gradient,
            start: CGPoint(x: 100, y: 924),
            end: CGPoint(x: 924, y: 100),
            options: []
        )
    }
    
    // 3. Ambient radial glow behind center
    let glowColors = [
        NSColor(red: 0.5, green: 0.75, blue: 1.0, alpha: 0.4).cgColor,
        NSColor(red: 0.3, green: 0.4, blue: 0.9, alpha: 0.0).cgColor
    ] as CFArray
    if let radialGlow = CGGradient(colorsSpace: colorSpace, colors: glowColors, locations: [0.0, 1.0]) {
        ctx.drawRadialGradient(
            radialGlow,
            startCenter: CGPoint(x: 512, y: 530),
            startRadius: 0,
            endCenter: CGPoint(x: 512, y: 530),
            endRadius: 380,
            options: []
        )
    }
    
    // 4. Keyboard keycap tile
    let keyRect = CGRect(x: 232, y: 232, width: 560, height: 560)
    let keyRadius: CGFloat = 110
    let keyPath = CGPath(roundedRect: keyRect, cornerWidth: keyRadius, cornerHeight: keyRadius, transform: nil)
    
    // Keycap shadow
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 20, color: CGColor(gray: 0, alpha: 0.45))
    ctx.setFillColor(CGColor(gray: 0.1, alpha: 1.0))
    ctx.addPath(keyPath)
    ctx.fillPath()
    ctx.restoreGState()
    
    // Keycap surface gradient
    ctx.saveGState()
    ctx.addPath(keyPath)
    ctx.clip()
    
    let keyColors = [
        NSColor(white: 0.25, alpha: 0.88).cgColor,
        NSColor(white: 0.09, alpha: 0.94).cgColor
    ] as CFArray
    if let keyGradient = CGGradient(colorsSpace: colorSpace, colors: keyColors, locations: [0.0, 1.0]) {
        ctx.drawLinearGradient(
            keyGradient,
            start: CGPoint(x: 512, y: 792),
            end: CGPoint(x: 512, y: 232),
            options: []
        )
    }
    
    // Keycap inner stroke
    ctx.setLineWidth(2.5)
    ctx.setStrokeColor(NSColor(white: 1.0, alpha: 0.25).cgColor)
    ctx.addPath(keyPath)
    ctx.strokePath()
    ctx.restoreGState()
    
    // 5. Draw Command symbol ⌘
    let symbolString = "⌘" as NSString
    let font = NSFont.systemFont(ofSize: 280, weight: .bold)
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.45)
    shadow.shadowOffset = CGSize(width: 0, height: -6)
    shadow.shadowBlurRadius = 10
    
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor.white,
        .shadow: shadow
    ]
    let strSize = symbolString.size(withAttributes: attrs)
    let strRect = CGRect(
        x: (1024 - strSize.width) / 2,
        y: (1024 - strSize.height) / 2 + 10,
        width: strSize.width,
        height: strSize.height
    )
    symbolString.draw(in: strRect, withAttributes: attrs)
    
    // 6. Accent status dot (indicator) at bottom of keycap
    let dotRect = CGRect(x: 487, y: 275, width: 50, height: 10)
    let dotPath = CGPath(roundedRect: dotRect, cornerWidth: 5, cornerHeight: 5, transform: nil)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: 0), blur: 8, color: NSColor(red: 0.3, green: 0.8, blue: 1.0, alpha: 0.9).cgColor)
    ctx.setFillColor(NSColor(red: 0.4, green: 0.85, blue: 1.0, alpha: 0.95).cgColor)
    ctx.addPath(dotPath)
    ctx.fillPath()
    ctx.restoreGState()
    
    // 7. Outer squircle rim light & border
    ctx.setLineWidth(2.0)
    ctx.setStrokeColor(NSColor(white: 1.0, alpha: 0.3).cgColor)
    ctx.addPath(squirclePath)
    ctx.strokePath()
    
    ctx.restoreGState() // restore squircle clip
    
    NSGraphicsContext.restoreGraphicsState()
    
    guard let pngData = rep.representation(using: .png, properties: [:]) else {
        fatalError("Failed to convert to PNG")
    }
    return pngData
}

let pngData = createIconData()
let outputDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
let outputPath = (outputDir as NSString).appendingPathComponent("AppIcon_1024.png")
try pngData.write(to: URL(fileURLWithPath: outputPath))
print("Successfully generated \(outputPath)")

