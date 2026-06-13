import AppKit

// viewmd app icon: indigo-gradient rounded square + white document-lines glyph.
let sizes: [(name: String, px: Int)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024)
]
let outDir = "/tmp/viewmd.iconset"
try? FileManager.default.removeItem(atPath: outDir)
try! FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

func draw(px: Int) -> NSImage {
    let s = CGFloat(px)
    let img = NSImage(size: NSSize(width: s, height: s))
    img.lockFocus()
    let inset = s * 0.06
    let rect = NSRect(x: inset, y: inset, width: s - inset * 2, height: s - inset * 2)
    let path = NSBezierPath(roundedRect: rect, xRadius: s * 0.20, yRadius: s * 0.20)
    NSGradient(colors: [
        NSColor(srgbRed: 0.388, green: 0.400, blue: 0.945, alpha: 1),
        NSColor(srgbRed: 0.545, green: 0.361, blue: 0.965, alpha: 1)
    ])!.draw(in: path, angle: -50)
    NSColor.white.setFill()
    let lineX = rect.minX + rect.width * 0.24
    let lineW = rect.width * 0.52
    let lineH = max(s * 0.05, 1)
    func bar(y: CGFloat, w: CGFloat, h: CGFloat) {
        NSBezierPath(roundedRect: NSRect(x: lineX, y: y, width: w, height: h),
                     xRadius: h / 2, yRadius: h / 2).fill()
    }
    bar(y: rect.minY + rect.height * 0.60, w: lineW, h: lineH * 1.7)
    bar(y: rect.minY + rect.height * 0.44, w: lineW * 0.82, h: lineH)
    bar(y: rect.minY + rect.height * 0.31, w: lineW * 0.64, h: lineH)
    img.unlockFocus()
    return img
}

for (name, px) in sizes {
    let img = draw(px: px)
    let rep = NSBitmapImageRep(data: img.tiffRepresentation!)!
    rep.size = NSSize(width: px, height: px)
    try! rep.representation(using: .png, properties: [:])!
        .write(to: URL(fileURLWithPath: "\(outDir)/\(name).png"))
}
print("iconset written to \(outDir)")
