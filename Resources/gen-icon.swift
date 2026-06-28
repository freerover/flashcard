import Cocoa

let size: CGFloat = 1024
let scale: CGFloat = 1
let cgSize = CGSize(width: size, height: size)

let colorSpace = CGColorSpaceCreateDeviceRGB()
let ctx = CGContext(data: nil, width: Int(size), height: Int(size),
                    bitsPerComponent: 8, bytesPerRow: 0,
                    space: colorSpace,
                    bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)!

ctx.setShouldAntialias(true)
ctx.setAllowsAntialiasing(true)
ctx.interpolationQuality = .high

// Background: rounded rect with gradient
let path = CGPath(roundedRect: CGRect(x: 0, y: 0, width: size, height: size),
                  cornerWidth: size * 0.22, cornerHeight: size * 0.22, transform: nil)
ctx.addPath(path)
ctx.clip()

let gradient = CGGradient(
    colorsSpace: colorSpace,
    colors: [
        NSColor(red: 0.25, green: 0.55, blue: 0.95, alpha: 1).cgColor,
        NSColor(red: 0.15, green: 0.40, blue: 0.85, alpha: 1).cgColor,
    ] as CFArray,
    locations: [0, 1]
)!
ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: size), end: CGPoint(x: size, y: 0), options: [])

// Card shape
let cardW = size * 0.55
let cardH = size * 0.70
let cardX = (size - cardW) / 2
let cardY = (size - cardH) / 2
let cardCorner = size * 0.06

ctx.setFillColor(NSColor.white.withAlphaComponent(0.95).cgColor)
let cardPath = CGPath(roundedRect: CGRect(x: cardX, y: cardY, width: cardW, height: cardH),
                      cornerWidth: cardCorner, cornerHeight: cardCorner, transform: nil)
ctx.addPath(cardPath)
ctx.fillPath()

// Text lines on card
ctx.setFillColor(NSColor(red: 0.2, green: 0.45, blue: 0.85, alpha: 1).cgColor)
let lineW = cardW * 0.65
let lineH: CGFloat = size * 0.028
let lineY = cardY + cardH * 0.25

for i in 0..<5 {
    let lineWidth = lineW * (i == 0 ? 0.7 : (i == 1 ? 0.9 : [0.8, 0.6, 0.75][i - 2]))
    let lineX = cardX + (cardW - lineWidth) / 2
    let y = lineY + CGFloat(i) * (lineH * 2.2)
    let linePath = CGPath(roundedRect: CGRect(x: lineX, y: y, width: lineWidth, height: lineH),
                          cornerWidth: lineH / 2, cornerHeight: lineH / 2, transform: nil)
    ctx.addPath(linePath)
    ctx.fillPath()
}

// Book/notch accent on top of card
ctx.setFillColor(NSColor(red: 0.2, green: 0.5, blue: 0.95, alpha: 0.15).cgColor)
let notchW = cardW * 0.3
let notchH = size * 0.04
let notchPath = CGPath(roundedRect: CGRect(x: cardX + (cardW - notchW) / 2, y: cardY + cardH - notchH - size * 0.04,
                                            width: notchW, height: notchH),
                       cornerWidth: notchH / 2, cornerHeight: notchH / 2, transform: nil)
ctx.addPath(notchPath)
ctx.fillPath()

let cgImage = ctx.makeImage()!

// Output iconset
let iconsetPath = "/tmp/Flashcard.iconset"
let fm = FileManager.default
try? fm.removeItem(atPath: iconsetPath)
try fm.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

let sizes: [(name: String, w: Int, h: Int, scale: Int)] = [
    ("icon_16x16", 16, 16, 1),
    ("icon_16x16@2x", 32, 32, 2),
    ("icon_32x32", 32, 32, 1),
    ("icon_32x32@2x", 64, 64, 2),
    ("icon_128x128", 128, 128, 1),
    ("icon_128x128@2x", 256, 256, 2),
    ("icon_256x256", 256, 256, 1),
    ("icon_256x256@2x", 512, 512, 2),
    ("icon_512x512", 512, 512, 1),
    ("icon_512x512@2x", 1024, 1024, 2),
]

for s in sizes {
    let resizedCtx = CGContext(data: nil, width: s.w, height: s.h,
                               bitsPerComponent: 8, bytesPerRow: 0,
                               space: colorSpace,
                               bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)!
    resizedCtx.interpolationQuality = .high
    resizedCtx.draw(cgImage, in: CGRect(x: 0, y: 0, width: s.w, height: s.h))
    let resizedImg = resizedCtx.makeImage()!
    let rep = NSBitmapImageRep(cgImage: resizedImg)
    let data = rep.representation(using: .png, properties: [:])!
    try data.write(to: URL(fileURLWithPath: "\(iconsetPath)/\(s.name).png"))
}

// Convert to .icns
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconsetPath, "-o", "/tmp/Flashcard.icns"]
try process.run()
process.waitUntilExit()

guard process.terminationStatus == 0 else {
    fputs("iconutil failed\n", stderr)
    exit(1)
}

let icnsData = try Data(contentsOf: URL(fileURLWithPath: "/tmp/Flashcard.icns"))
try icnsData.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
try? fm.removeItem(atPath: iconsetPath)
try? fm.removeItem(atPath: "/tmp/Flashcard.icns")
