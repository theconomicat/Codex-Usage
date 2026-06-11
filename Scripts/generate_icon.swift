import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let assets = root.appendingPathComponent("Assets", isDirectory: true)
let iconset = assets.appendingPathComponent("AppIcon.iconset", isDirectory: true)
let iconURL = assets.appendingPathComponent("AppIcon.icns")

try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
try FileManager.default.createDirectory(at: assets, withIntermediateDirectories: true)

let sizes: [(name: String, points: CGFloat, scale: CGFloat)] = [
    ("icon_16x16.png", 16, 1),
    ("icon_16x16@2x.png", 16, 2),
    ("icon_32x32.png", 32, 1),
    ("icon_32x32@2x.png", 32, 2),
    ("icon_128x128.png", 128, 1),
    ("icon_128x128@2x.png", 128, 2),
    ("icon_256x256.png", 256, 1),
    ("icon_256x256@2x.png", 256, 2),
    ("icon_512x512.png", 512, 1),
    ("icon_512x512@2x.png", 512, 2)
]

for item in sizes {
    let pixels = Int(item.points * item.scale)
    let image = NSImage(size: NSSize(width: pixels, height: pixels), flipped: false) { rect in
        drawIcon(in: rect)
        return true
    }
    try writePNG(image, to: iconset.appendingPathComponent(item.name))
}

try? FileManager.default.removeItem(at: iconURL)
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconset.path, "-o", iconURL.path]
try process.run()
process.waitUntilExit()

guard process.terminationStatus == 0 else {
    throw NSError(domain: "CodexUsageIcon", code: Int(process.terminationStatus))
}

func drawIcon(in rect: NSRect) {
    let size = min(rect.width, rect.height)
    let scale = size / 1024
    let background = NSBezierPath(roundedRect: rect, xRadius: 224 * scale, yRadius: 224 * scale)
    NSColor(calibratedRed: 0.965, green: 0.965, blue: 0.953, alpha: 1).setFill()
    background.fill()

    drawRing(center: CGPoint(x: rect.midX - 128 * scale, y: rect.midY), radius: 168 * scale, progress: 0.78, color: NSColor(calibratedRed: 0.16, green: 0.80, blue: 0.31, alpha: 1), scale: scale)
    drawRing(center: CGPoint(x: rect.midX + 128 * scale, y: rect.midY), radius: 168 * scale, progress: 0.95, color: NSColor(calibratedRed: 1.0, green: 0.73, blue: 0.18, alpha: 1), scale: scale)
}

func drawRing(center: CGPoint, radius: CGFloat, progress: CGFloat, color: NSColor, scale: CGFloat) {
    let lineWidth = 42 * scale

    let base = NSBezierPath()
    base.lineWidth = lineWidth
    base.appendArc(withCenter: center, radius: radius, startAngle: 0, endAngle: 360)
    NSColor(calibratedWhite: 0.82, alpha: 1).setStroke()
    base.stroke()

    let progressPath = NSBezierPath()
    progressPath.lineWidth = lineWidth
    progressPath.lineCapStyle = .round
    progressPath.appendArc(withCenter: center, radius: radius, startAngle: 90, endAngle: 90 - 360 * progress, clockwise: true)
    color.setStroke()
    progressPath.stroke()

    let inner = NSBezierPath(ovalIn: NSRect(x: center.x - 86 * scale, y: center.y - 86 * scale, width: 172 * scale, height: 172 * scale))
    NSColor.white.setFill()
    inner.fill()
}

func writePNG(_ image: NSImage, to url: URL) throws {
    guard
        let tiff = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiff),
        let png = bitmap.representation(using: .png, properties: [:])
    else {
        throw NSError(domain: "CodexUsageIcon", code: 1)
    }
    try png.write(to: url)
}
