import Testing
@testable import SwiperCore

@Test func versionInTestedListIsTested() {
    let tested = [OSVersion(major: 26, minor: 0), OSVersion(major: 27, minor: 0)]
    #expect(compatibility(current: OSVersion(major: 27, minor: 0), tested: tested) == .tested)
}

@Test func versionNotInListIsUntested() {
    #expect(compatibility(current: OSVersion(major: 28, minor: 0), tested: [OSVersion(major: 27, minor: 0)]) == .untested)
}

@Test func emptyListIsUntested() {
    #expect(compatibility(current: OSVersion(major: 27, minor: 0), tested: []) == .untested)
}
