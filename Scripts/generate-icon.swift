#!/usr/bin/env swift

import AppKit

guard CommandLine.arguments.count == 2 else {
    fputs("Usage: generate-icon.swift OUTPUT.icns\n", stderr)
    exit(2)
}

let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)

image.lockFocus()
guard let context = NSGraphicsContext.current?.cgContext else {
    fputs("Could not create drawing context.\n", stderr)
    exit(1)
}

context.setAllowsAntialiasing(true)
context.setShouldAntialias(true)

let backgroundRect = NSRect(x: 72, y: 72, width: 880, height: 880)
let backgroundPath = NSBezierPath(roundedRect: backgroundRect, xRadius: 210, yRadius: 210)
let gradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.23, green: 0.18, blue: 0.58, alpha: 1),
    NSColor(calibratedRed: 0.43, green: 0.25, blue: 0.78, alpha: 1)
])
gradient?.draw(in: backgroundPath, angle: -55)

context.saveGState()
backgroundPath.addClip()
let highlight = NSBezierPath(ovalIn: NSRect(x: 170, y: 540, width: 680, height: 500))
NSColor.white.withAlphaComponent(0.07).setFill()
highlight.fill()
context.restoreGState()

// Original vector artwork. SF Symbols remain useful inside the app UI, but
// Apple's license does not allow them to be used in an app icon or logo.
let markColor = NSColor.white
markColor.setFill()
markColor.setStroke()

let cup = NSBezierPath()
cup.move(to: NSPoint(x: 278, y: 604))
cup.line(to: NSPoint(x: 694, y: 604))
cup.line(to: NSPoint(x: 658, y: 414))
cup.curve(
    to: NSPoint(x: 594, y: 350),
    controlPoint1: NSPoint(x: 650, y: 374),
    controlPoint2: NSPoint(x: 624, y: 350)
)
cup.line(to: NSPoint(x: 378, y: 350))
cup.curve(
    to: NSPoint(x: 314, y: 414),
    controlPoint1: NSPoint(x: 348, y: 350),
    controlPoint2: NSPoint(x: 322, y: 374)
)
cup.close()
cup.fill()

let rim = NSBezierPath(roundedRect: NSRect(x: 264, y: 576, width: 444, height: 58), xRadius: 29, yRadius: 29)
rim.fill()

let handle = NSBezierPath()
handle.move(to: NSPoint(x: 682, y: 550))
handle.curve(
    to: NSPoint(x: 678, y: 414),
    controlPoint1: NSPoint(x: 848, y: 566),
    controlPoint2: NSPoint(x: 846, y: 396)
)
handle.lineWidth = 48
handle.lineCapStyle = .round
handle.stroke()

let saucer = NSBezierPath(roundedRect: NSRect(x: 246, y: 282, width: 512, height: 42), xRadius: 21, yRadius: 21)
saucer.fill()

func drawSteam(from start: NSPoint, to end: NSPoint, bend: CGFloat) {
    let steam = NSBezierPath()
    steam.move(to: start)
    steam.curve(
        to: end,
        controlPoint1: NSPoint(x: start.x - bend, y: start.y + 54),
        controlPoint2: NSPoint(x: end.x + bend, y: end.y - 54)
    )
    steam.lineWidth = 30
    steam.lineCapStyle = .round
    steam.stroke()
}

drawSteam(from: NSPoint(x: 382, y: 696), to: NSPoint(x: 398, y: 840), bend: 34)
drawSteam(from: NSPoint(x: 486, y: 686), to: NSPoint(x: 486, y: 850), bend: 38)
drawSteam(from: NSPoint(x: 590, y: 696), to: NSPoint(x: 574, y: 840), bend: 34)

image.unlockFocus()

func pngRepresentation(of source: NSImage, pixels: Int) -> Data? {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ), let graphicsContext = NSGraphicsContext(bitmapImageRep: bitmap) else {
        return nil
    }

    bitmap.size = NSSize(width: pixels, height: pixels)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = graphicsContext
    graphicsContext.imageInterpolation = .high
    source.draw(
        in: NSRect(x: 0, y: 0, width: pixels, height: pixels),
        from: NSRect(x: 0, y: 0, width: source.size.width, height: source.size.height),
        operation: .copy,
        fraction: 1
    )
    NSGraphicsContext.restoreGraphicsState()

    return bitmap.representation(using: .png, properties: [:])
}

func bigEndianData(_ value: Int) -> Data {
    var encoded = UInt32(value).bigEndian
    return Data(bytes: &encoded, count: MemoryLayout<UInt32>.size)
}

// An ICNS file is a sequence of typed, length-prefixed image records. Modern
// macOS accepts PNG payloads for these standard representation types.
let representations: [(type: String, pixels: Int)] = [
    ("icp4", 16),
    ("icp5", 32),
    ("icp6", 64),
    ("ic07", 128),
    ("ic08", 256),
    ("ic09", 512),
    ("ic10", 1024)
]

var records = Data()
for representation in representations {
    guard let type = representation.type.data(using: .ascii),
          let png = pngRepresentation(of: image, pixels: representation.pixels) else {
        fputs("Could not encode the \(representation.pixels)-pixel app icon.\n", stderr)
        exit(1)
    }

    records.append(type)
    records.append(bigEndianData(png.count + 8))
    records.append(png)
}

var icon = Data("icns".utf8)
icon.append(bigEndianData(records.count + 8))
icon.append(records)

do {
    try icon.write(to: outputURL, options: .atomic)
} catch {
    fputs("Could not write app icon: \(error.localizedDescription)\n", stderr)
    exit(1)
}
