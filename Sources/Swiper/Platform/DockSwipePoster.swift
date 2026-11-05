import CoreGraphics
import Foundation
import os
import SwiperCore

let gestureLog = Logger(subsystem: "io.github.guykongthong.swiper", category: "gesture")

/// Fakes the trackpad's three-finger Dock swipe so desktops follow the mouse.
///
/// This uses undocumented system behavior, so it can break in any macOS update.
/// - macOS 27 and later: the Dock reads an internal HID event (type DockSwipe) attached to a type 30 CGEvent.
///   The CGEvent value fields are ignored there.
/// - Earlier macOS: the Dock reads value fields on a pair of CGEvents (types 29 and 30).
/// Field numbers and constants were learned from how open-source tools (Mac Mouse Fix, yabai) work,
/// plus Apple's open-source IOKit headers. Nothing outside this file knows about them.
final class DockSwipePoster: GesturePosting {
    enum Phase: UInt32 { case began = 1, changed = 2, ended = 4, cancelled = 8 }

    private static let minVerticalCommit = 0.25
    private static let minVerticalExitSpeed = 6.0

    private var axis: SwipeAxis = .horizontal
    private var origin = 0.0
    private var lastDelta = 0.0
    private var lastProgress = 0.0
    private var maskSent = false
    private var started = false

    func begin(axis: SwipeAxis) {
        // The began event is posted with the first real movement (see update), like a trackpad does.
        self.axis = axis
        origin = 0
        lastDelta = 0
        lastProgress = 0
        maskSent = false
        started = false
    }

    func update(progress: Double) {
        lastDelta = progress - lastProgress
        lastProgress = progress
        // Real trackpad events carry a direction mask: on the first event for horizontal swipes,
        // on the first changed event for vertical ones.
        let mask: Int
        switch axis {
        case .vertical: mask = progress > 0 ? 1 : 2   // up : down
        case .horizontal: mask = progress > 0 ? 8 : 4 // right : left
        }
        if !started {
            started = true
            // A began event that already carries the first bit of movement.
            post(phase: .began, progress: progress, exitSpeed: 0, mask: axis == .horizontal ? mask : 0)
            post(phase: .changed, progress: progress, exitSpeed: 0, mask: axis == .vertical ? mask : 0)
        } else {
            post(phase: .changed, progress: progress, exitSpeed: 0)
        }
    }

    func end(progress: Double, velocity: Double) {
        guard started else { return }
        // If the hand moved back against the swipe, cancel instead of finishing it.
        let finishing = lastDelta == 0 || (lastDelta > 0) == (progress > 0)
        var exitSpeed = lastDelta * 100
        // A real trackpad lifts off mid-flick, so Mission Control sees a fast exit (about 9 in the logs).
        // A mouse usually slows down before release, which the Dock reads as "didn't mean it".
        // For a vertical swipe that went far enough, report at least a flick-sized exit speed.
        if axis == .vertical && finishing && abs(progress) >= Self.minVerticalCommit {
            let direction: Double = progress >= 0 ? 1 : -1
            exitSpeed = direction * max(abs(exitSpeed), Self.minVerticalExitSpeed)
        }
        post(phase: finishing ? .ended : .cancelled, progress: progress, exitSpeed: exitSpeed)
    }

    func cancel() {
        guard started else { return }
        post(phase: .cancelled, progress: lastProgress, exitSpeed: 0)
    }

    // MARK: building events

    private func post(phase: Phase, progress: Double, exitSpeed: Double, mask: Int = 0) {
        let events: [CGEvent?]
        if #available(macOS 27.0, *) {
            events = [Self.makeModernEvent(axis: axis, phase: phase, progress: progress, exitSpeed: exitSpeed, mask: mask)]
        } else {
            events = Self.makeLegacyEvents(axis: axis, phase: phase, progress: progress, exitSpeed: exitSpeed)
        }
        if GestureRecorder.isEnabled { gestureLog.notice("POST axis=\(self.axis == .horizontal ? "h" : "v", privacy: .public) phase=\(phase.rawValue) progress=\(progress) exit=\(exitSpeed) mask=\(mask)") }
        for event in events {
            event?.setIntegerValueField(.eventSourceUserData, value: GestureRecorder.ownMarker)
            event?.post(tap: .cgSessionEventTap)
        }
    }

    /// Exposed (not private) so a dry run can build events without posting them.
    static func makeModernEvent(axis: SwipeAxis, phase: UInt32, progress: Double, exitSpeed: Double, mask: Int = 0) -> CGEvent? {
        guard let hid = PrivateSystem.shared, let event = CGEvent(source: nil) else { return nil }
        let hidEvent = hid.createEvent(type: Constants.hidTypeDockSwipe, options: phase << 24)
        guard let hidEvent else { return nil }
        defer { hid.release(hidEvent) }

        hid.setInteger(hidEvent, field: Constants.dockSwipeMotion, value: axis == .horizontal ? 1 : 2)
        hid.setInteger(hidEvent, field: Constants.dockSwipeFlavor, value: Constants.flavorDockPrimary)
        if mask != 0 { hid.setInteger(hidEvent, field: Constants.dockSwipeMask, value: mask) }
        hid.setDouble(hidEvent, field: Constants.dockSwipeProgress, value: progress)

        if phase == Phase.ended.rawValue || phase == Phase.cancelled.rawValue {
            if let child = hid.createEvent(type: Constants.hidTypeVelocity, options: 0) {
                hid.setDouble(child, field: Constants.velocityX, value: exitSpeed)
                hid.setDouble(child, field: Constants.velocityY, value: exitSpeed)
                hid.setDouble(child, field: Constants.velocityZ, value: 0)
                hid.append(hidEvent, child: child)
                hid.release(child)
            }
        }
        event.type = CGEventType(rawValue: 30) ?? event.type
        hid.attach(hidEvent, to: event)
        return event
    }

    static func makeModernEvent(axis: SwipeAxis, phase: Phase, progress: Double, exitSpeed: Double, mask: Int = 0) -> CGEvent? {
        makeModernEvent(axis: axis, phase: phase.rawValue, progress: progress, exitSpeed: exitSpeed, mask: mask)
    }

    private static func makeLegacyEvents(axis: SwipeAxis, phase: Phase, progress: Double, exitSpeed: Double) -> [CGEvent?] {
        func field(_ n: UInt32) -> CGEventField { CGEventField(rawValue: n)! }
        let magic41 = 33231.0

        let e29 = CGEvent(source: nil)
        e29?.setDoubleValueField(field(55), value: 29)
        e29?.setDoubleValueField(field(41), value: magic41)

        let e30 = CGEvent(source: nil)
        guard let e30 else { return [e29] }
        let motion = axis == .horizontal ? 1.0 : 2.0
        e30.setDoubleValueField(field(55), value: 30)
        e30.setDoubleValueField(field(110), value: 23)
        e30.setDoubleValueField(field(132), value: Double(phase.rawValue))
        e30.setDoubleValueField(field(134), value: Double(phase.rawValue))
        e30.setDoubleValueField(field(124), value: progress)
        // The progress again, as the bits of a 32-bit float stored in a 64-bit integer.
        let bits = Int64(Float32(progress).bitPattern)
        e30.setIntegerValueField(field(135), value: bits)
        e30.setDoubleValueField(field(41), value: magic41)
        // Motion encoded as a tiny float (1 = horizontal, 2 = vertical), plus plain motion values.
        let tiny = axis == .horizontal ? 1.401298464324817e-45 : 2.802596928649634e-45
        e30.setDoubleValueField(field(119), value: tiny)
        e30.setDoubleValueField(field(139), value: tiny)
        e30.setDoubleValueField(field(123), value: motion)
        e30.setDoubleValueField(field(165), value: motion)
        e30.setIntegerValueField(field(136), value: 0)
        if phase == .ended || phase == .cancelled {
            e30.setDoubleValueField(field(129), value: exitSpeed)
            e30.setDoubleValueField(field(130), value: exitSpeed)
        }
        return [e30, e29]
    }

    private enum Constants {
        static let hidTypeVelocity: UInt32 = 9
        static let hidTypeDockSwipe: UInt32 = 23
        // IOHIDEventFieldBase(type) is the type shifted left by 16 bits.
        static let dockSwipeBase: UInt32 = 23 << 16
        static let dockSwipeMask = dockSwipeBase | 0
        static let dockSwipeMotion = dockSwipeBase | 1
        static let dockSwipeProgress = dockSwipeBase | 2
        static let dockSwipeFlavor = dockSwipeBase | 5
        static let flavorDockPrimary = 3
        static let velocityBase: UInt32 = 9 << 16
        static let velocityX = velocityBase | 0
        static let velocityY = velocityBase | 1
        static let velocityZ = velocityBase | 2
    }
}

/// Looks up the private IOKit and SkyLight functions at runtime, so a missing one fails softly
/// (returns nil) instead of crashing the app at launch.
final class PrivateSystem {
    typealias HIDEventRef = UnsafeMutableRawPointer
    private typealias CreateFn = @convention(c) (CFAllocator?, UInt32, UInt64, UInt32) -> HIDEventRef?
    private typealias SetIntFn = @convention(c) (HIDEventRef, UInt32, Int32) -> Void
    private typealias SetDoubleFn = @convention(c) (HIDEventRef, UInt32, Double) -> Void
    private typealias AppendFn = @convention(c) (HIDEventRef, HIDEventRef, UInt32) -> Void
    private typealias AttachFn = @convention(c) (UnsafeMutableRawPointer, HIDEventRef) -> Void

    private typealias CopyFn = @convention(c) (UnsafeMutableRawPointer) -> HIDEventRef?
    private typealias TypeFn = @convention(c) (HIDEventRef) -> UInt32
    private typealias GetDFn = @convention(c) (HIDEventRef, UInt32) -> Double
    private typealias GetIFn = @convention(c) (HIDEventRef, UInt32) -> Int
    private typealias PhaseFn = @convention(c) (HIDEventRef) -> UInt32
    private typealias ChildrenFn = @convention(c) (HIDEventRef) -> Unmanaged<CFArray>?
    private let phaseFn: PhaseFn?
    private let childrenFn: ChildrenFn?
    private let copyFn: CopyFn
    private let typeFn: TypeFn
    private let getDFn: GetDFn
    private let getIFn: GetIFn
    private let create: CreateFn
    private let setInt: SetIntFn
    private let setDouble: SetDoubleFn
    private let appendFn: AppendFn
    private let attachFn: AttachFn

    static let shared: PrivateSystem? = PrivateSystem()

    private init?() {
        _ = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_NOW)
        _ = dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight", RTLD_NOW)
        let handle = UnsafeMutableRawPointer(bitPattern: -2)  // RTLD_DEFAULT
        guard let c = dlsym(handle, "IOHIDEventCreate"),
              let i = dlsym(handle, "IOHIDEventSetIntegerValue"),
              let d = dlsym(handle, "IOHIDEventSetDoubleValue"),
              let a = dlsym(handle, "IOHIDEventAppendEvent"),
              let s = dlsym(handle, "SLEventSetIOHIDEvent"),
              let cp = dlsym(handle, "CGEventCopyIOHIDEvent"),
              let ty = dlsym(handle, "IOHIDEventGetType"),
              let gd = dlsym(handle, "IOHIDEventGetDoubleValue"),
              let gi = dlsym(handle, "IOHIDEventGetIntegerValue") else { return nil }
        copyFn = unsafeBitCast(cp, to: CopyFn.self)
        typeFn = unsafeBitCast(ty, to: TypeFn.self)
        getDFn = unsafeBitCast(gd, to: GetDFn.self)
        getIFn = unsafeBitCast(gi, to: GetIFn.self)
        phaseFn = dlsym(handle, "IOHIDEventGetPhase").map { unsafeBitCast($0, to: PhaseFn.self) }
        childrenFn = dlsym(handle, "IOHIDEventGetChildren").map { unsafeBitCast($0, to: ChildrenFn.self) }
        create = unsafeBitCast(c, to: CreateFn.self)
        setInt = unsafeBitCast(i, to: SetIntFn.self)
        setDouble = unsafeBitCast(d, to: SetDoubleFn.self)
        appendFn = unsafeBitCast(a, to: AppendFn.self)
        attachFn = unsafeBitCast(s, to: AttachFn.self)
    }

    func createEvent(type: UInt32, options: UInt32) -> HIDEventRef? { create(kCFAllocatorDefault, type, 0, options) }
    func setInteger(_ e: HIDEventRef, field: UInt32, value: Int) { setInt(e, field, Int32(value)) }
    func setDouble(_ e: HIDEventRef, field: UInt32, value: Double) { setDouble(e, field, value) }
    func append(_ e: HIDEventRef, child: HIDEventRef) { appendFn(e, child, 0) }
    func attach(_ e: HIDEventRef, to cgEvent: CGEvent) { attachFn(Unmanaged.passUnretained(cgEvent).toOpaque(), e) }
    /// Describes the HID event attached to a CGEvent, for debugging. Nil if none.
    func describe(_ cgEvent: CGEvent) -> String? {
        guard let hid = copyFn(Unmanaged.passUnretained(cgEvent).toOpaque()) else { return nil }
        defer { release(hid) }
        let type = typeFn(hid)
        guard type == 23 else { return "hidType=\(type)" }
        let base = UInt32(23) << 16
        var text = "hidType=23 motion=\(getIFn(hid, base | 1)) flavor=\(getIFn(hid, base | 5)) progress=\(getDFn(hid, base | 2)) mask=\(getIFn(hid, base | 0))"
        if let phaseFn { text += " phase=\(phaseFn(hid))" }
        if let kids = childrenFn?(hid)?.takeUnretainedValue() as? [AnyObject] {
            for kid in kids {
                let ref = Unmanaged.passUnretained(kid).toOpaque()
                let kidType = typeFn(ref)
                text += " child(type=\(kidType) vx=\(getDFn(ref, UInt32(kidType) << 16 | 0)) vy=\(getDFn(ref, UInt32(kidType) << 16 | 1)))"
            }
        }
        return text
    }

    func release(_ e: HIDEventRef) { Unmanaged<AnyObject>.fromOpaque(e).release() }
}
