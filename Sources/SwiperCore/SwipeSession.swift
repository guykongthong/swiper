import Foundation

/// The system-facing actions a swipe needs. The app implements these; tests use a fake.
public protocol SwipeEffects: AnyObject {
    func replayHeldPress(_ button: MouseButton)
    func replayRelease(_ button: MouseButton)
    func setCursorFrozen(_ frozen: Bool)
    func beginGesture(axis: SwipeAxis)
    func updateGesture(progress: Double)
    func endGesture(progress: Double, velocity: Double)
    func cancelGesture()
}

public struct SwipeResult: Equatable, Sendable {
    /// True if the event tap should drop the current event.
    public var swallow: Bool
    /// If set, call `handle(.tick(...))` after this many seconds.
    public var scheduleTickAfter: TimeInterval?
}

/// Glue between the chord detector, axis lock, mapper and the system effects.
/// All behavior that matters is here, so it can be tested without a mouse.
public final class SwipeSession {
    private let effects: SwipeEffects
    private let naturalScrolling: () -> Bool
    private var clickDelayMs: Int
    private var sensitivity: Int
    private var detector: ChordDetector
    private var axisLock = AxisLock(lockDistance: 8)
    private var mapper: GestureMapper
    private var axis: SwipeAxis?
    private var progress = 0.0
    private var lastSample: (time: TimeInterval, progress: Double)?
    private var previousSample: (time: TimeInterval, progress: Double)?

    public init(effects: SwipeEffects, clickDelayMs: Int, sensitivity: Int, naturalScrolling: @escaping () -> Bool) {
        self.effects = effects
        self.clickDelayMs = clickDelayMs
        self.sensitivity = sensitivity
        self.naturalScrolling = naturalScrolling
        detector = ChordDetector(windowMs: clickDelayMs)
        mapper = GestureMapper(sensitivity: sensitivity, naturalScrolling: naturalScrolling())
    }

    public func updateSettings(clickDelayMs: Int, sensitivity: Int) {
        guard clickDelayMs != self.clickDelayMs || sensitivity != self.sensitivity else { return }
        abandon()
        self.clickDelayMs = clickDelayMs
        self.sensitivity = sensitivity
        detector = ChordDetector(windowMs: clickDelayMs)
    }

    public func handle(_ input: MouseInput) -> SwipeResult {
        apply(detector.handle(input), at: input.time)
    }

    /// Abandons whatever is in progress: pause, quit, lost permission, or the system disabling the tap.
    /// Leaves no held press, no frozen cursor and no half-finished gesture.
    public func abandon() {
        let outputs = detector.reset()
        for output in outputs {
            switch output {
            case .releaseHeldPress(let b): effects.replayHeldPress(b)
            case .chordEnded:
                if axis != nil { effects.cancelGesture() }
                effects.setCursorFrozen(false)
                clearChordState()
            default: break
            }
        }
    }

    private func apply(_ outputs: [ChordOutput], at time: TimeInterval) -> SwipeResult {
        var result = SwipeResult(swallow: false, scheduleTickAfter: nil)
        for output in outputs {
            switch output {
            case .swallow:
                result.swallow = true
            case .holdPress:
                result.swallow = true
                result.scheduleTickAfter = Double(clickDelayMs) / 1000 + 0.002
            case .releaseHeldPress(let b):
                effects.replayHeldPress(b)
            case .replayRelease(let b):
                effects.replayRelease(b)
            case .chordBegan:
                clearChordState()
                mapper = GestureMapper(sensitivity: sensitivity, naturalScrolling: naturalScrolling())
                effects.setCursorFrozen(true)
            case .chordMoved(let dx, let dy):
                chordMoved(dx: dx, dy: dy, at: time)
            case .chordEnded:
                if let _ = axis {
                    let velocity = currentVelocity()
                    effects.endGesture(progress: progress, velocity: velocity)
                }
                effects.setCursorFrozen(false)
                clearChordState()
            }
        }
        return result
    }

    private func chordMoved(dx: Double, dy: Double, at time: TimeInterval) {
        if axis == nil {
            guard let locked = axisLock.feed(dx: dx, dy: dy) else { return }
            axis = locked
            effects.beginGesture(axis: locked)
        }
        guard let axis else { return }
        progress = mapper.progress(axis: axis, dx: dx, dy: dy)
        previousSample = lastSample
        lastSample = (time, progress)
        effects.updateGesture(progress: progress)
    }

    private func currentVelocity() -> Double {
        guard let last = lastSample, let prev = previousSample, last.time > prev.time else { return 0 }
        return (last.progress - prev.progress) / (last.time - prev.time)
    }

    private func clearChordState() {
        axisLock.reset()
        axis = nil
        progress = 0
        lastSample = nil
        previousSample = nil
    }
}
