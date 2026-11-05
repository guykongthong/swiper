public enum SwipeAxis: Equatable, Sendable {
    case horizontal, vertical
}

/// Picks horizontal or vertical from the first few pixels of movement, then sticks with it.
public struct AxisLock: Sendable {
    private let lockDistance: Double
    private var sumX = 0.0
    private var sumY = 0.0
    private var locked: SwipeAxis?

    public init(lockDistance: Double) {
        self.lockDistance = lockDistance
    }

    public mutating func feed(dx: Double, dy: Double) -> SwipeAxis? {
        if let locked { return locked }
        sumX += dx
        sumY += dy
        guard max(abs(sumX), abs(sumY)) >= lockDistance else { return nil }
        let axis: SwipeAxis = abs(sumX) >= abs(sumY) ? .horizontal : .vertical
        locked = axis
        return axis
    }

    public mutating func reset() {
        sumX = 0; sumY = 0; locked = nil
    }
}
