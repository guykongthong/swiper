/// Turns raw mouse movement into gesture progress.
/// Progress 1.0 is about one full desktop slide at the default sensitivity.
/// Sign convention (to be confirmed against the real gesture in Task 6):
/// with natural scrolling, moving the mouse right gives positive progress.
public struct GestureMapper: Sendable {
    private static let pixelsPerUnit = 600.0
    private static let sensitivityFactor: [Double] = [0.5, 0.75, 1.0, 1.5, 2.0]

    private let factor: Double
    private let direction: Double
    private var total = 0.0

    public init(sensitivity: Int, naturalScrolling: Bool) {
        let index = min(max(sensitivity, 1), 5) - 1
        factor = Self.sensitivityFactor[index] / Self.pixelsPerUnit
        direction = naturalScrolling ? 1 : -1
    }

    public mutating func progress(axis: SwipeAxis, dx: Double, dy: Double) -> Double {
        switch axis {
        case .horizontal: total += dx * factor * direction
        case .vertical: total += -dy * factor
        }
        return total
    }
}
