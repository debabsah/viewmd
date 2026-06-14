import AppKit

// viewmd app icon: teal-to-sky gradient rounded square + white SF Rounded "M"
// with a rounded down-chevron (the Markdown mark, soft variant).
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

let teal0 = NSColor(srgbRed: 0.078, green: 0.722, blue: 0.651, alpha: 1) // #14B8A6
let teal1 = NSColor(srgbRed: 0.055, green: 0.647, blue: 0.914, alpha: 1) // #0EA5E9
let white = NSColor.white

func roundedFont(_ size: CGFloat, _ w: NSFont.Weight) -> NSFont {
    let base = NSFont.systemFont(ofSize: size, weight: w)
    if let d = base.fontDescriptor.withDesign(.rounded) { return NSFont(descriptor: d, size: size) ?? base }
    return base
}

func draw(px: Int) -> NSImage {
    let s = CGFloat(px)
    let img = NSImage(size: NSSize(width: s, height: s))
    img.lockFocus()

    // gradient squircle
    let inset = s * 0.06
    let rect = NSRect(x: inset, y: inset, width: s - inset * 2, height: s - inset * 2)
    let tile = NSBezierPath(roundedRect: rect, xRadius: s * 0.225, yRadius: s * 0.225)
    NSGradient(colors: [teal0, teal1])!.draw(in: tile, angle: -50)

    // "M" + rounded down-chevron, centered as a group
    let mAttrs: [NSAttributedString.Key: Any] = [
        .font: roundedFont(s * 0.46, .heavy), .foregroundColor: white]
    let m = "M" as NSString
    let mSz = m.size(withAttributes: mAttrs)
    let symW = s * 0.22, symH = s * 0.16, gap = s * 0.05
    let groupW = mSz.width + gap + symW
    let startX = (s - groupW) / 2
    m.draw(at: NSPoint(x: startX, y: (s - mSz.height) / 2), withAttributes: mAttrs)

    let cr = NSRect(x: startX + mSz.width + gap, y: s / 2 - symH / 2, width: symW, height: symH)
    let chevron = NSBezierPath()
    chevron.move(to: NSPoint(x: cr.minX, y: cr.maxY))
    chevron.line(to: NSPoint(x: cr.midX, y: cr.minY))
    chevron.line(to: NSPoint(x: cr.maxX, y: cr.maxY))
    chevron.lineWidth = s * 0.06
    chevron.lineCapStyle = .round
    chevron.lineJoinStyle = .round
    white.setStroke()
    chevron.stroke()

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
