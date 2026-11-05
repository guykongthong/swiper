import Foundation
import SwiperCore

enum SystemInfo {
    /// The "Natural scrolling" switch in System Settings. Defaults to on if the key was never set.
    static func naturalScrollingEnabled() -> Bool {
        UserDefaults.standard.object(forKey: "com.apple.swipescrolldirection") as? Bool ?? true
    }

    static func currentVersion() -> OSVersion {
        let v = ProcessInfo.processInfo.operatingSystemVersion
        return OSVersion(major: v.majorVersion, minor: v.minorVersion)
    }
}
