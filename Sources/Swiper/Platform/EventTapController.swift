import CoreGraphics
import Foundation
import SwiperCore

enum EventTapError: Error { case couldNotCreateTap }

/// Listens to the mouse globally, feeds `SwipeSession`, and carries out its effects.
/// Needs the Accessibility permission to create the tap.
final class EventTapController: SwipeEffects {
    private static let marker: Int64 = 0x53574950  // "SWIP": tags events we re-post so we ignore them

    private let poster: GesturePosting
    private var session: SwipeSession!
    private var tap: CFMachPort?
    private var source: CFRunLoopSource?
    private var heldDown: [MouseButton: CGEvent] = [:]
    private var currentEvent: CGEvent?
    /// Buttons whose replayed press we posted but have not yet seen come back through the tap.
    private var pendingReplayDown: Set<MouseButton> = []

    var isRunning: Bool { tap != nil }

    init(poster: GesturePosting, clickDelayMs: Int, sensitivity: Int) {
        self.poster = poster
        session = SwipeSession(
            effects: self,
            clickDelayMs: clickDelayMs,
            sensitivity: sensitivity,
            naturalScrolling: { SystemInfo.naturalScrollingEnabled() }
        )
    }

    func updateSettings(clickDelayMs: Int, sensitivity: Int) {
        session.updateSettings(clickDelayMs: clickDelayMs, sensitivity: sensitivity)
    }

    // MARK: start / stop

    func start() throws {
        guard tap == nil else { return }
        let types: [CGEventType] = [
            .leftMouseDown, .leftMouseUp, .rightMouseDown, .rightMouseUp,
            .mouseMoved, .leftMouseDragged, .rightMouseDragged
        ]
        let mask = types.reduce(CGEventMask(0)) { $0 | (CGEventMask(1) << $1.rawValue) }
        let callback: CGEventTapCallBack = { _, type, event, userInfo in
            guard let userInfo else { return Unmanaged.passUnretained(event) }
            let controller = Unmanaged<EventTapController>.fromOpaque(userInfo).takeUnretainedValue()
            return controller.handle(type: type, event: event)
        }
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap,
            eventsOfInterest: mask, callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else { throw EventTapError.couldNotCreateTap }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        self.tap = tap
        self.source = source
    }

    func stop() {
        session.abandon()
        if let tap { CGEvent.tapEnable(tap: tap, enable: false) }
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        tap = nil
        source = nil
        heldDown.removeAll()
        pendingReplayDown.removeAll()
    }

    // MARK: event handling

    private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            handleTapDisabled()
            return Unmanaged.passUnretained(event)
        }
        if event.getIntegerValueField(.eventSourceUserData) == Self.marker {
            if type == .leftMouseDown { pendingReplayDown.remove(.left) }
            if type == .rightMouseDown { pendingReplayDown.remove(.right) }
            return Unmanaged.passUnretained(event)
        }
        guard let input = mouseInput(type: type, event: event) else {
            return Unmanaged.passUnretained(event)
        }

        currentEvent = event
        let result = session.handle(input)
        currentEvent = nil

        if case .down(let button, _) = input, result.swallow {
            heldDown[button] = event.copy()
        }
        // A posted press can arrive late. If the real release passed straight through now, it
        // would overtake the press and the app would see up, then down (a stuck button).
        // Queue the release behind the press instead; posted events keep their order.
        if case .up(let button, _) = input, !result.swallow, pendingReplayDown.contains(button) {
            post(event.copy() ?? event)
            return nil
        }
        if let delay = result.scheduleTickAfter {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self else { return }
                _ = self.session.handle(.tick(at: ProcessInfo.processInfo.systemUptime))
            }
        }
        return result.swallow ? nil : Unmanaged.passUnretained(event)
    }

    /// The system turned the tap off (it was too slow, or user input). Never leave buttons or the cursor stuck.
    func handleTapDisabled() {
        session.abandon()
        if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
    }

    private func mouseInput(type: CGEventType, event: CGEvent) -> MouseInput? {
        let now = ProcessInfo.processInfo.systemUptime
        switch type {
        case .leftMouseDown: return .down(.left, at: now)
        case .rightMouseDown: return .down(.right, at: now)
        case .leftMouseUp: return .up(.left, at: now)
        case .rightMouseUp: return .up(.right, at: now)
        case .mouseMoved, .leftMouseDragged, .rightMouseDragged:
            return .moved(
                dx: event.getDoubleValueField(.mouseEventDeltaX),
                dy: event.getDoubleValueField(.mouseEventDeltaY),
                at: now
            )
        default: return nil
        }
    }

    // MARK: SwipeEffects

    func replayHeldPress(_ button: MouseButton) {
        guard let event = heldDown.removeValue(forKey: button) else { return }
        pendingReplayDown.insert(button)
        post(event)
    }

    func replayRelease(_ button: MouseButton) {
        guard let event = currentEvent?.copy() else { return }
        post(event)
    }

    func setCursorFrozen(_ frozen: Bool) {
        CGAssociateMouseAndMouseCursorPosition(frozen ? 0 : 1)
    }

    func beginGesture(axis: SwipeAxis) { poster.begin(axis: axis) }
    func updateGesture(progress: Double) { poster.update(progress: progress) }
    func endGesture(progress: Double, velocity: Double) { poster.end(progress: progress, velocity: velocity) }
    func cancelGesture() { poster.cancel() }

    private func post(_ event: CGEvent) {
        event.setIntegerValueField(.eventSourceUserData, value: Self.marker)
        event.post(tap: .cgSessionEventTap)
    }
}
