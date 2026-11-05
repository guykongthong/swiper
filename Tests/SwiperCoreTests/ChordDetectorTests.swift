import Testing
@testable import SwiperCore

private func ms(_ v: Double) -> Double { v / 1000 }

@Test func singleLeftClickIsReleasedAfterWindow() {
    var d = ChordDetector(windowMs: 40)
    #expect(d.handle(.down(.left, at: ms(0))) == [.holdPress(.left)])
    #expect(d.handle(.tick(at: ms(41))) == [.releaseHeldPress(.left)])
}

@Test func tickInsideWindowDoesNothing() {
    var d = ChordDetector(windowMs: 40)
    _ = d.handle(.down(.left, at: ms(0)))
    #expect(d.handle(.tick(at: ms(20))) == [])
}

@Test func quickClickReplaysPressAndRelease() {
    var d = ChordDetector(windowMs: 40)
    _ = d.handle(.down(.left, at: ms(0)))
    #expect(d.handle(.up(.left, at: ms(15))) == [.releaseHeldPress(.left), .replayRelease(.left), .swallow])
}

@Test func bothButtonsInsideWindowBeginChord() {
    var d = ChordDetector(windowMs: 40)
    _ = d.handle(.down(.left, at: ms(0)))
    let out = d.handle(.down(.right, at: ms(20)))
    #expect(out == [.swallow, .chordBegan])
    #expect(!out.contains(.releaseHeldPress(.left)))
}

@Test func movementBeforeSecondButtonReleasesHeldPress() {
    var d = ChordDetector(windowMs: 40)
    _ = d.handle(.down(.left, at: ms(0)))
    #expect(d.handle(.moved(dx: 3, dy: 0, at: ms(10))) == [.releaseHeldPress(.left)])
}

@Test func secondButtonAfterWindowIsNotAChord() {
    var d = ChordDetector(windowMs: 40)
    _ = d.handle(.down(.left, at: ms(0)))
    _ = d.handle(.tick(at: ms(41)))
    let out = d.handle(.down(.right, at: ms(60)))
    #expect(!out.contains(.chordBegan))
    #expect(out == [])
}

@Test func secondButtonArrivingLateWithoutTickIsNotAChord() {
    var d = ChordDetector(windowMs: 40)
    _ = d.handle(.down(.left, at: ms(0)))
    let out = d.handle(.down(.right, at: ms(60)))
    #expect(out == [.releaseHeldPress(.left)])
}

@Test func chordEndsOnceWhenFirstButtonReleases() {
    var d = ChordDetector(windowMs: 40)
    _ = d.handle(.down(.left, at: ms(0)))
    _ = d.handle(.down(.right, at: ms(10)))
    #expect(d.handle(.up(.left, at: ms(300))) == [.swallow, .chordEnded])
    let second = d.handle(.up(.right, at: ms(320)))
    #expect(second == [.swallow])
    #expect(!second.contains(.releaseHeldPress(.right)))
}

@Test func chordMovesAreForwarded() {
    var d = ChordDetector(windowMs: 40)
    _ = d.handle(.down(.left, at: ms(0)))
    _ = d.handle(.down(.right, at: ms(10)))
    #expect(d.handle(.moved(dx: 4, dy: -2, at: ms(50))) == [.swallow, .chordMoved(dx: 4, dy: -2)])
}

@Test func windowIsConfigurable() {
    var short = ChordDetector(windowMs: 30)
    _ = short.handle(.down(.left, at: ms(0)))
    #expect(short.handle(.tick(at: ms(35))) == [.releaseHeldPress(.left)])

    var long = ChordDetector(windowMs: 50)
    _ = long.handle(.down(.left, at: ms(0)))
    #expect(long.handle(.tick(at: ms(35))) == [])
    #expect(long.handle(.tick(at: ms(51))) == [.releaseHeldPress(.left)])
}

@Test func resetDuringChordEndsIt() {
    var d = ChordDetector(windowMs: 40)
    _ = d.handle(.down(.left, at: ms(0)))
    _ = d.handle(.down(.right, at: ms(10)))
    #expect(d.reset() == [.chordEnded])
    #expect(d.handle(.moved(dx: 1, dy: 1, at: ms(100))) == [])
}

@Test func resetWhileHoldingReleasesThePress() {
    var d = ChordDetector(windowMs: 40)
    _ = d.handle(.down(.left, at: ms(0)))
    #expect(d.reset() == [.releaseHeldPress(.left)])
}

@Test func plainMovementAndIdleEventsPassThrough() {
    var d = ChordDetector(windowMs: 40)
    #expect(d.handle(.moved(dx: 5, dy: 5, at: ms(0))) == [])
    #expect(d.handle(.up(.left, at: ms(1))) == [])
    #expect(d.handle(.tick(at: ms(2))) == [])
}

@Test func deliveredLeftThenRightPassesBothThrough() {
    var d = ChordDetector(windowMs: 40)
    _ = d.handle(.down(.left, at: ms(0)))
    _ = d.handle(.tick(at: ms(41)))
    #expect(d.handle(.down(.right, at: ms(80))) == [])
    #expect(d.handle(.up(.right, at: ms(120))) == [])
    #expect(d.handle(.up(.left, at: ms(150))) == [])
    // back to idle: a fresh press is held again
    #expect(d.handle(.down(.left, at: ms(500))) == [.holdPress(.left)])
}

@Test func buttonPressedAgainDuringDrainIsSwallowed() {
    var d = ChordDetector(windowMs: 40)
    _ = d.handle(.down(.left, at: ms(0)))
    _ = d.handle(.down(.right, at: ms(10)))
    _ = d.handle(.up(.left, at: ms(100)))
    #expect(d.handle(.down(.left, at: ms(120))) == [.swallow])
    #expect(d.handle(.up(.left, at: ms(130))) == [.swallow])
    #expect(d.handle(.up(.right, at: ms(140))) == [.swallow])
    #expect(d.handle(.down(.left, at: ms(500))) == [.holdPress(.left)])
}
