public enum SwipeAxis: Equatable, Sendable {
    case horizontal, vertical
}

/// Picks horizontal or vertical from the first few pixels of movement, then sticks with it.
public struct AxisLock: Sendable {
    private let lockDistance: Double
    private let clearRatio = 2.0
    private let giveUpDistance = 40.0
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
        let ax = abs(sumX), ay = abs(sumY)
        let bigger = max(ax, ay), smaller = min(ax, ay)
        guard bigger >= lockDistance else { return nil }
        // Wait for a clear winner, because the first pixels of a mouse movement wobble.
        // Give up waiting and take the larger axis once the movement is long enough.
        guard bigger >= smaller * clearRatio || bigger >= giveUpDistance else { return nil }
        let axis: SwipeAxis = ax >= ay ? .horizontal : .vertical
        locked = axis
        return axis
    }

    public mutating func reset() {
        sumX = 0; sumY = 0; locked = nil
    }
}
