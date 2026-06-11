import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let assets = root.appendingPathComponent("Assets", isDirectory: true)
let iconset = assets.appendingPathComponent("AppIcon.iconset", isDirectory: true)
let iconURL = assets.appendingPathComponent("AppIcon.icns")

try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

let sizes: [(String, CGFloat, CGFloat)] = [
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

for (name, points, scale) in sizes {
    let pixels = Int(points * scale)
    let image = NSImage(size: NSSize(width: pixels, height: pixels), flipped: false) { rect in
        drawIcon(in: rect)
        return true
    }
    try writePNG(image, to: iconset.appendingPathComponent(name))
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
    let bounds = NSRect(x: rect.midX - size / 2, y: rect.midY - size / 2, width: size, height: size)

    let background = NSBezierPath(roundedRect: bounds, xRadius: 220 * scale, yRadius: 220 * scale)
    NSColor(calibratedRed: 0.965, green: 0.965, blue: 0.955, alpha: 1).setFill()
    background.fill()

    let border = NSBezierPath(roundedRect: bounds.insetBy(dx: 18 * scale, dy: 18 * scale), xRadius: 202 * scale, yRadius: 202 * scale)
    border.lineWidth = 20 * scale
    NSColor(calibratedWhite: 0.0, alpha: 0.07).setStroke()
    border.stroke()

    let text = "C"
    let font = NSFont.systemFont(ofSize: 560 * scale, weight: .semibold)
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor(calibratedWhite: 0.08, alpha: 1)
    ]
    let attributed = NSAttributedString(string: text, attributes: attributes)
    let textSize = attributed.size()
    attributed.draw(at: NSPoint(
        x: bounds.midX - textSize.width / 2,
        y: bounds.midY - textSize.height / 2 - 18 * scale
    ))
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
