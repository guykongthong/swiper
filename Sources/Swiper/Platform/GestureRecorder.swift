import CoreGraphics
import Foundation

/// Debug aid: logs the real Dock swipes your trackpad sends, so our fake ones can be compared.
/// Off unless `defaults write io.github.guykongthong.swiper debugRecord -bool true` is set.
final class GestureRecorder {
    static let ownMarker: Int64 = 0x53574950
    private var tap: CFMachPort?
    private var source: CFRunLoopSource?

    static let isEnabled: Bool = UserDefaults.standard.bool(forKey: "debugRecord")

    func start() {
        guard tap == nil, Self.isEnabled else { return }
        let mask = (CGEventMask(1) << 29) | (CGEventMask(1) << 30)
        let callback: CGEventTapCallBack = { _, type, event, _ in
            if event.getIntegerValueField(.eventSourceUserData) != GestureRecorder.ownMarker,
               let text = PrivateSystem.shared?.describe(event) {
                gestureLog.notice("REAL cgType=\(type.rawValue) \(text, privacy: .public)")
            }
            return Unmanaged.passUnretained(event)
        }
        guard let tap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .listenOnly,
                                          eventsOfInterest: mask, callback: callback, userInfo: nil) else {
            gestureLog.notice("recorder: could not create tap")
            return
        }
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        self.tap = tap
        self.source = source
        gestureLog.notice("recorder: listening for real trackpad Dock swipes")
    }
}
