import SwiperCore

/// Everything that fakes the trackpad's Dock swipe lives behind this protocol,
/// so the undocumented parts can be replaced or patched in one place.
protocol GesturePosting: AnyObject {
    func begin(axis: SwipeAxis)
    func update(progress: Double)
    func end(progress: Double, velocity: Double)
    func cancel()
}

/// Placeholder until the real Dock swipe poster exists (Task 6).
final class LoggingGesturePoster: GesturePosting {
    func begin(axis: SwipeAxis) { print("gesture begin \(axis)") }
    func update(progress: Double) { print("gesture update \(progress)") }
    func end(progress: Double, velocity: Double) { print("gesture end \(progress) v=\(velocity)") }
    func cancel() { print("gesture cancel") }
}
