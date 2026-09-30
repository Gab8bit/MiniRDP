// Genera Resources/AppIcon.icns:  swift Tools/make_icon.swift
import AppKit

func render(_ px: Int) -> Data {
    let s = CGFloat(px)
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    // Squircle di sfondo con gradiente blu
    let inset = s * 0.05
    let bg = NSBezierPath(roundedRect: NSRect(x: inset, y: inset, width: s - 2*inset, height: s - 2*inset),
                          xRadius: s * 0.22, yRadius: s * 0.22)
    NSGradient(colors: [NSColor(red: 0.20, green: 0.55, blue: 1.0, alpha: 1),
                        NSColor(red: 0.05, green: 0.20, blue: 0.62, alpha: 1)])!.draw(in: bg, angle: -90)
    // Monitor
    let w = s * 0.56, h = s * 0.38
    let mx = (s - w) / 2, my = s * 0.36
    NSColor.white.setFill()
    NSBezierPath(roundedRect: NSRect(x: mx, y: my, width: w, height: h), xRadius: s*0.03, yRadius: s*0.03).fill()
    NSColor(red: 0.06, green: 0.16, blue: 0.42, alpha: 1).setFill()
    NSBezierPath(roundedRect: NSRect(x: mx + s*0.03, y: my + s*0.03, width: w - s*0.06, height: h - s*0.06),
                 xRadius: s*0.015, yRadius: s*0.015).fill()
    // Prompt ">_" sullo schermo
    NSColor(red: 0.4, green: 1.0, blue: 0.6, alpha: 1).setStroke()
    let a = NSBezierPath(); a.lineWidth = s * 0.028; a.lineCapStyle = .round; a.lineJoinStyle = .round
    a.move(to: NSPoint(x: mx + w*0.22, y: my + h*0.68)); a.line(to: NSPoint(x: mx + w*0.36, y: my + h*0.50))
    a.line(to: NSPoint(x: mx + w*0.22, y: my + h*0.32)); a.stroke()
    let u = NSBezierPath(); u.lineWidth = s * 0.028; u.lineCapStyle = .round
    u.move(to: NSPoint(x: mx + w*0.44, y: my + h*0.32)); u.line(to: NSPoint(x: mx + w*0.64, y: my + h*0.32)); u.stroke()
    // Piedistallo
    NSColor.white.setFill()
    NSBezierPath(rect: NSRect(x: s*0.47, y: s*0.27, width: s*0.06, height: s*0.09)).fill()
    NSBezierPath(roundedRect: NSRect(x: s*0.36, y: s*0.24, width: s*0.28, height: s*0.04), xRadius: s*0.02, yRadius: s*0.02).fill()
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

let dir = "Resources/AppIcon.iconset"
try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
for base in [16, 32, 128, 256, 512] {
    try! render(base).write(to: URL(fileURLWithPath: "\(dir)/icon_\(base)x\(base).png"))
    try! render(base * 2).write(to: URL(fileURLWithPath: "\(dir)/icon_\(base)x\(base)@2x.png"))
}
