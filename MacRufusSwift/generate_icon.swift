#!/usr/bin/swift
import AppKit

func makeIconPNG(size: Int) -> Data {
    let bmp = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size, pixelsHigh: size,
        bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0)!

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bmp)

    // Purple rounded-rect background
    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let radius = CGFloat(size) * 0.22
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    NSColor(red: 0.45, green: 0.05, blue: 0.75, alpha: 1.0).setFill()
    path.fill()

    // White bold "R"
    let fontSize = CGFloat(size) * 0.62
    let font = NSFont.boldSystemFont(ofSize: fontSize)
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor.white
    ]
    let str = NSAttributedString(string: "R", attributes: attrs)
    let sz = str.size()
    let x = (CGFloat(size) - sz.width)  / 2.0 + CGFloat(size) * 0.02
    let y = (CGFloat(size) - sz.height) / 2.0
    str.draw(at: NSPoint(x: x, y: y))

    NSGraphicsContext.restoreGraphicsState()
    return bmp.representation(using: .png, properties: [:])!
}

let iconsetPath = "AppIcon.iconset"
try? FileManager.default.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

let specs: [(String, Int)] = [
    ("icon_16x16",       16),
    ("icon_16x16@2x",    32),
    ("icon_32x32",       32),
    ("icon_32x32@2x",    64),
    ("icon_128x128",    128),
    ("icon_128x128@2x", 256),
    ("icon_256x256",    256),
    ("icon_256x256@2x", 512),
    ("icon_512x512",    512),
    ("icon_512x512@2x",1024),
]

for (name, size) in specs {
    let data = makeIconPNG(size: size)
    let url  = URL(fileURLWithPath: "\(iconsetPath)/\(name).png")
    try! data.write(to: url)
    print("  ✓ \(name).png")
}
print("Done — run: iconutil -c icns AppIcon.iconset")
