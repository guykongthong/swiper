import Foundation

public enum MouseButton: Hashable, Sendable {
    case left, right
}

public enum MouseInput: Equatable, Sendable {
    case down(MouseButton, at: TimeInterval)
    case up(MouseButton, at: TimeInterval)
    case moved(dx: Double, dy: Double, at: TimeInterval)
    /// A clock tick, so the detector can expire its hold-back window without a mouse event.
    case tick(at: TimeInterval)

    public var time: TimeInterval {
        switch self {
        case .down(_, let t), .up(_, let t), .moved(_, _, let t), .tick(let t): return t
        }
    }
}

/// What the event tap should do. An empty list means: pass the event through unchanged.
public enum ChordOutput: Equatable, Sendable {
    /// Drop the current event.
    case swallow
    /// Drop the current press and remember it; it may become a chord.
    case holdPress(MouseButton)
    /// Re-post a press that was held back.
    case releaseHeldPress(MouseButton)
    /// Re-post the release of a button whose press was just replayed.
    case replayRelease(MouseButton)
    case chordBegan
    case chordMoved(dx: Double, dy: Double)
    case chordEnded
}
