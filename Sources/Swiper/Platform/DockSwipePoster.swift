import CoreGraphics
import Foundation
import SwiperCore

/// Fakes the trackpad's three-finger Dock swipe so desktops follow the mouse.
///
/// WARNING: UNVERIFIED. These event fields are undocumented. The values below come from how
/// open-source tools are known to do this, written from memory, and have not been confirmed on
/// this Mac. Task 6 of the plan is a spike: run it, watch whether the desktop slides, and fix the
/// constants in `Fields`. Nothing outside this file knows about them.
final class DockSwipePoster: GesturePosting {
    private enum Fields {
        static let eventType: CGEventField = CGEventField(rawValue: 55)!      // 29 or 30
        static let hidEventType: CGEventField = CGEventField(rawValue: 110)!  // 23 = Dock swipe
        static let motion: CGEventField = CGEventField(rawValue: 123)!        // 1 horizontal, 2 vertical
        static let originOffset: CGEventField = CGEventField(rawValue: 124)!  // progress
        static let phaseA: CGEventField = CGEventField(rawValue: 132)!
        static let phaseB: CGEventField = CGEventField(rawValue: 134)!
        static let exitSpeedA: CGEventField = CGEventField(rawValue: 129)!
        static let exitSpeedB: CGEventField = CGEventField(rawValue: 130)!
    }
    private enum Phase: Int64 { case began = 1, changed = 2, ended = 4, cancelled = 8 }

    private var axis: SwipeAxis = .horizontal

    func begin(axis: SwipeAxis) {
        self.axis = axis
        post(phase: .began, offset: 0, speed: 0)
    }

    func update(progress: Double) {
        post(phase: .changed, offset: progress, speed: 0)
    }

    func end(progress: Double, velocity: Double) {
        post(phase: .ended, offset: progress, speed: velocity)
    }

    func cancel() {
        post(phase: .cancelled, offset: 0, speed: 0)
    }

    private func post(phase: Phase, offset: Double, speed: Double) {
        // Two events per step: a plain gesture marker (29) and the Dock swipe itself (30).
        for type in [29, 30] as [Int64] {
            guard let event = CGEvent(source: nil) else { return }
            event.setIntegerValueField(Fields.eventType, value: type)
            if type == 30 {
                event.setIntegerValueField(Fields.hidEventType, value: 23)
                event.setIntegerValueField(Fields.motion, value: axis == .horizontal ? 1 : 2)
                event.setDoubleValueField(Fields.originOffset, value: offset)
                event.setIntegerValueField(Fields.phaseA, value: phase.rawValue)
                event.setIntegerValueField(Fields.phaseB, value: phase.rawValue)
                event.setDoubleValueField(Fields.exitSpeedA, value: speed)
                event.setDoubleValueField(Fields.exitSpeedB, value: speed)
            }
            event.post(tap: .cgSessionEventTap)
        }
    }
}
