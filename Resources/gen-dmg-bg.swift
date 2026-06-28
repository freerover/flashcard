import Cocoa

let w: CGFloat = 560, h: CGFloat = 360
let size = NSSize(width: w, height: h)
let image = NSImage(size: size)

image.lockFocus()

NSColor(white: 0.98, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: w, height: h).fill()

let box = NSRect(x: 20, y: 20, width: w - 40, height: h - 40)
NSColor(white: 0.95, alpha: 1).setFill()
NSBezierPath(roundedRect: box, xRadius: 16, yRadius: 16).fill()

NSColor(red: 0.2, green: 0.5, blue: 0.95, alpha: 0.08).setFill()
let topBar = NSRect(x: 20, y: 290, width: w - 40, height: 50)
NSBezierPath(roundedRect: topBar, xRadius: 16, yRadius: 16).fill()

let iconSize: CGFloat = 64
let iconY: CGFloat = 200

let appIcon = NSRect(x: 80, y: iconY, width: iconSize, height: iconSize)
NSColor(red: 0.2, green: 0.5, blue: 0.95, alpha: 0.15).setFill()
NSBezierPath(roundedRect: appIcon, xRadius: 14, yRadius: 14).fill()
let appLabel: NSString = "Flashcard"
appLabel.draw(at: NSPoint(x: 72, y: iconY - 22), withAttributes: [
    .font: NSFont.systemFont(ofSize: 12),
    .foregroundColor: NSColor.gray
])

let arrowPath = NSBezierPath()
arrowPath.lineWidth = 2.5
arrowPath.lineCapStyle = .round
arrowPath.lineJoinStyle = .round
NSColor(red: 0.2, green: 0.5, blue: 0.95, alpha: 1).setStroke()
arrowPath.move(to: NSPoint(x: 165, y: iconY + iconSize / 2))
arrowPath.line(to: NSPoint(x: 285, y: iconY + iconSize / 2))
arrowPath.stroke()
let arrowSize: CGFloat = 10
let head = NSBezierPath()
head.move(to: NSPoint(x: 285, y: iconY + iconSize / 2))
head.line(to: NSPoint(x: 285 - arrowSize, y: iconY + iconSize / 2 - arrowSize / 2))
head.line(to: NSPoint(x: 285 - arrowSize, y: iconY + iconSize / 2 + arrowSize / 2))
head.close()
NSColor(red: 0.2, green: 0.5, blue: 0.95, alpha: 1).setFill()
head.fill()

let appIcon2 = NSRect(x: 310, y: iconY, width: iconSize, height: iconSize)
NSColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1).setFill()
NSBezierPath(roundedRect: appIcon2, xRadius: 14, yRadius: 14).fill()
let appLabel2: NSString = "Applications"
appLabel2.draw(at: NSPoint(x: 298, y: iconY - 22), withAttributes: [
    .font: NSFont.systemFont(ofSize: 12),
    .foregroundColor: NSColor.gray
])

let title: NSString = "将 Flashcard 拖动到 Applications 中进行安装"
title.draw(at: NSPoint(x: 110, y: 305), withAttributes: [
    .font: NSFont.boldSystemFont(ofSize: 16),
    .foregroundColor: NSColor(white: 0.25, alpha: 1)
])

let detail: NSString = "安装完成后，请从菜单栏图标启动 Flashcard"
detail.draw(at: NSPoint(x: 160, y: 80), withAttributes: [
    .font: NSFont.systemFont(ofSize: 12),
    .foregroundColor: NSColor(white: 0.55, alpha: 1)
])

image.unlockFocus()

guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    exit(1)
}
let rep = NSBitmapImageRep(cgImage: cgImage)
guard let data = rep.representation(using: .png, properties: [:]) else {
    exit(1)
}
let output = CommandLine.arguments[1]
try data.write(to: URL(fileURLWithPath: output))
