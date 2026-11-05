public struct OSVersion: Equatable, Hashable, Sendable {
    public var major: Int
    public var minor: Int
    public init(major: Int, minor: Int) {
        self.major = major
        self.minor = minor
    }
}

public enum CompatibilityResult: Equatable, Sendable {
    case tested, untested
}

/// Matches on major and minor; patch releases are ignored.
public func compatibility(current: OSVersion, tested: [OSVersion]) -> CompatibilityResult {
    tested.contains(current) ? .tested : .untested
}
