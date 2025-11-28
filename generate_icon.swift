#!/usr/bin/env swift

import AppKit

let symbolName = "pencil.line"

let sizes: [(size: Int, scale: Int, name: String)] = [
    (16, 1, "icon_16x16.png"),
    (16, 2, "icon_16x16@2x.png"),
    (32, 1, "icon_32x32.png"),
    (32, 2, "icon_32x32@2x.png"),
    (128, 1, "icon_128x128.png"),
    (128, 2, "icon_128x128@2x.png"),
    (256, 1, "icon_256x256.png"),
    (256, 2, "icon_256x256@2x.png"),
    (512, 1, "icon_512x512.png"),
    (512, 2, "icon_512x512@2x.png"),
]

let iconsetPath = "AppIcon.iconset"
let fileManager = FileManager.default

if fileManager.fileExists(atPath: iconsetPath) {
    try! fileManager.removeItem(atPath: iconsetPath)
}
try! fileManager.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

for (size, scale, name) in sizes {
    let pixelSize = size * scale

    let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelSize,
        pixelsHigh: pixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!

    bitmap.size = NSSize(width: size, height: size)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)

    // White background
    NSColor.white.setFill()
    NSRect(x: 0, y: 0, width: size, height: size).fill()

    // Draw SF Symbol centered
    let symbolPointSize = CGFloat(size) * 0.55
    let config = NSImage.SymbolConfiguration(pointSize: symbolPointSize, weight: .regular)
    if let symbol = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)?.withSymbolConfiguration(config) {
        let symbolSize = symbol.size
        let x = (CGFloat(size) - symbolSize.width) / 2
        let y = (CGFloat(size) - symbolSize.height) / 2
        let rect = NSRect(x: x, y: y, width: symbolSize.width, height: symbolSize.height)
        symbol.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1.0)
    }

    NSGraphicsContext.restoreGraphicsState()

    if let pngData = bitmap.representation(using: .png, properties: [:]) {
        try! pngData.write(to: URL(fileURLWithPath: "\(iconsetPath)/\(name)"))
    }
}

print("Iconset created. Run: iconutil --convert icns AppIcon.iconset")
