import AppKit

/// The menu bar glyph (design option 1b: two dots with motion lines), drawn in code on an 18 x 18 grid.
/// It is a template image, so macOS tints it for light mode, dark mode and the highlighted state.
enum MenuBarIcon {
    static func image(paused: Bool) -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: true) { _ in
            NSColor.black.set()
            if paused {
                // Outlined dots, no motion lines.
                for x in [8.8, 14.6] {
                    let path = NSBezierPath(ovalIn: NSRect(x: x - 1.95, y: 9 - 1.95, width: 3.9, height: 3.9))
                    path.lineWidth = 1.1
                    path.stroke()
                }
            } else {
                let lines: [(x1: Double, x2: Double, y: Double)] = [(2.6, 5.2, 6.5), (1.2, 5.2, 9), (3.0, 5.2, 11.5)]
                for line in lines {
                    let path = NSBezierPath()
                    path.move(to: NSPoint(x: line.x1, y: line.y))
                    path.line(to: NSPoint(x: line.x2, y: line.y))
                    path.lineWidth = 1.5
                    path.lineCapStyle = .round
                    path.stroke()
                }
                for x in [8.8, 14.6] {
                    NSBezierPath(ovalIn: NSRect(x: x - 2.5, y: 9 - 2.5, width: 5, height: 5)).fill()
                }
            }
            return true
        }
        image.isTemplate = true
        return image
    }
}
