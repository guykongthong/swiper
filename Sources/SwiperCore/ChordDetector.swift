import Foundation

/// Decides whether left + right pressed together form a swipe chord.
/// Pure logic: time comes in as input, so it can be tested without a clock.
public struct ChordDetector: Sendable {
    private enum State {
        case idle
        case holding(MouseButton, since: TimeInterval)
        case chord(down: Set<MouseButton>)
        case draining(down: Set<MouseButton>)   // chord already ended, swallow until all up
        case delivered(down: Set<MouseButton>)  // normal clicks already sent on
    }

    private var state: State = .idle
    private let window: TimeInterval

    public init(windowMs: Int) {
        window = Double(windowMs) / 1000
    }

    public var isInChord: Bool {
        if case .chord = state { return true }
        return false
    }

    public mutating func handle(_ input: MouseInput) -> [ChordOutput] {
        var out: [ChordOutput] = []

        if case .holding(let b, let since) = state, input.time - since >= window {
            out.append(.releaseHeldPress(b))
            state = .delivered(down: [b])
        }

        switch state {
        case .idle:
            if case .down(let b, let t) = input {
                state = .holding(b, since: t)
                out.append(.holdPress(b))
            }

        case .holding(let held, _):
            switch input {
            case .down(let b, _) where b != held:
                state = .chord(down: [held, b])
                out += [.swallow, .chordBegan]
            case .up(let b, _) where b == held:
                state = .idle
                out += [.releaseHeldPress(b), .replayRelease(b), .swallow]
            case .moved:
                out.append(.releaseHeldPress(held))
                state = .delivered(down: [held])
            default:
                break
            }

        case .chord(var down):
            switch input {
            case .moved(let dx, let dy, _):
                out += [.swallow, .chordMoved(dx: dx, dy: dy)]
            case .up(let b, _):
                down.remove(b)
                state = down.isEmpty ? .idle : .draining(down: down)
                out += [.swallow, .chordEnded]
            case .down(let b, _):
                down.insert(b)
                state = .chord(down: down)
                out.append(.swallow)
            case .tick:
                break
            }

        case .draining(var down):
            switch input {
            case .down(let b, _):
                down.insert(b); state = .draining(down: down); out.append(.swallow)
            case .up(let b, _):
                down.remove(b)
                state = down.isEmpty ? .idle : .draining(down: down)
                out.append(.swallow)
            default:
                break
            }

        case .delivered(var down):
            switch input {
            case .down(let b, _): down.insert(b); state = .delivered(down: down)
            case .up(let b, _):
                down.remove(b)
                state = down.isEmpty ? .idle : .delivered(down: down)
            default: break
            }
        }
        return out
    }

    /// Abandons whatever is in progress (pause, quit, permission loss, tap disabled).
    public mutating func reset() -> [ChordOutput] {
        defer { state = .idle }
        switch state {
        case .holding(let b, _): return [.releaseHeldPress(b)]
        case .chord: return [.chordEnded]
        default: return []
        }
    }
}
