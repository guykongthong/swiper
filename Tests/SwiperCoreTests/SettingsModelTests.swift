import Testing
@testable import SwiperCore

@Test func defaultsMatchTheSpec() {
    let d = SettingsModel.defaults
    #expect(d.enabled)
    #expect(d.sensitivity == 3)
    #expect(d.clickDelayMs == 40)
    #expect(!d.launchAtLogin)
}

@Test func clampedForcesRanges() {
    var s = SettingsModel.defaults
    s.sensitivity = 99
    s.clickDelayMs = 5
    let c = s.clamped()
    #expect(c.sensitivity == 5)
    #expect(c.clickDelayMs == 30)
    s.sensitivity = -1
    s.clickDelayMs = 500
    #expect(s.clamped().sensitivity == 1)
    #expect(s.clamped().clickDelayMs == 50)
}

@Test func lowDelayWarningBelowForty() {
    var s = SettingsModel.defaults
    s.clickDelayMs = 39
    #expect(s.isClickDelayLow)
    s.clickDelayMs = 40
    #expect(!s.isClickDelayLow)
}

@Test func sensitivityLabelsRunSlowerToFaster() {
    #expect(SettingsModel.sensitivityLabel(1) == "Slower")
    #expect(SettingsModel.sensitivityLabel(3) == "Default")
    #expect(SettingsModel.sensitivityLabel(5) == "Faster")
}
