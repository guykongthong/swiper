# Swiper Implementation Plan

> **Note:** the owner later asked the assistant to implement this plan. Steps still give signatures and test intentions.

**Goal:** a menu bar macOS app that turns "hold left + right mouse buttons and move" into the trackpad's three-finger desktop swipe and Mission Control swipe.

**Architecture:** all decision logic (chord detection, axis lock, movement to gesture progress, settings, compatibility) lives in a pure Swift package, `SwiperCore`, so it can be unit tested without a mouse. A thin app layer owns everything that touches the system: the event tap, posting gesture events, permission, health checks and SwiftUI screens. The gesture posting code sits behind one protocol so it can be patched when macOS changes.

**Tech Stack:** Swift, SwiftUI (`MenuBarExtra`), CoreGraphics event taps, Swift Testing or XCTest, Xcode project plus a local Swift package.

**Spec:** `docs/superpowers/specs/2026-11-05-swiper-design.md`. Mockups: `docs/design/`.

## Global Constraints

- Chord hold-back window is tunable, 30 to 50 ms, default 40 ms.
- Swipe sensitivity is a 5-step setting (1 to 5), labelled Slower to Faster.
- Needs the Accessibility permission; the app must work if it is granted while the app is running.
- No Mac App Store build. Distribution is a downloadable build on GitHub Releases, unsigned for now.
- First release is validated on the owner's current macOS version only, and the README says so.
- A broken gesture must be reported in the UI, never fail silently. Plain clicks must never be lost or stuck.
- Never move the system trackpad settings or touch three-finger drag.
- UI font is Inter. Palette: `#1e3354` dark blue, `#f8f6f0` pastel white, amber and soft red for warnings only.
- Defect log: GitHub issues, `defect` label plus one of `low`, `medium`, `high`, `critical`.
- Docs are plain Markdown in the repo.

## Review Focus

Failure modes the spec implies that are most likely to bite, most likely first. Each has a test in the task that owns it.

1. Permission granted after launch: the tap must start without a relaunch. (Task 2)
2. The system disables the event tap (timeout or user input): the app must re-enable it and must not leave buttons swallowed or the cursor frozen. (Task 4)
3. The app is paused, quits or loses permission mid-swipe: cursor is unfrozen and the gesture is ended cleanly. (Task 4)
4. One button released before the other: exactly one gesture end, and no stray click when the second is released. (Task 3)
5. Other mouse buttons, scrolling and a plain drag must pass through untouched. (Task 3)

## File Structure

```
swiper/
  Swiper.xcodeproj
  Swiper/                      app target (system-facing code and UI)
    SwiperApp.swift            entry point, MenuBarExtra, windows
    Platform/
      PermissionMonitor.swift
      EventTapController.swift
      GesturePoster.swift      protocol + Dock swipe implementation
      HealthMonitor.swift
      SystemInfo.swift         natural scrolling, macOS version
    UI/
      PopoverView.swift
      SettingsView.swift
      Theme.swift
    Resources/Inter/
  SwiperCore/                  local Swift package (pure logic, unit tested)
    Package.swift
    Sources/SwiperCore/
      MouseInput.swift
      ChordDetector.swift
      AxisLock.swift
      GestureMapper.swift
      SettingsModel.swift
      Compatibility.swift
      AppStatus.swift
    Tests/SwiperCoreTests/
  docs/
    adr/  srs/  diagrams/  design/  superpowers/
```

---

### Task 1: Project skeleton and repo hygiene

**Files:**
- Create: Xcode app target `Swiper`, local package `SwiperCore`, `.gitignore`, `docs/adr/0000-template.md`
- Modify: `README.md`

**Interfaces:**
- Produces: a menu bar app with an icon and a Quit item that launches and shows no Dock icon; `SwiperCore` importable from the app.

- [ ] **Step 1:** Create the Xcode project (macOS App, SwiftUI) in the repo root. Set `LSUIElement` to YES so there is no Dock icon.
- [ ] **Step 2:** Add `SwiperCore` as a local package and add one trivial test in it to prove the test target runs. Run the package tests: expected PASS.
- [ ] **Step 3:** In `SwiperApp.swift`, use `MenuBarExtra` with a placeholder system symbol and a Quit button. Run the app: the icon appears in the menu bar, there is no Dock icon, Quit works.
- [ ] **Step 4:** Add a macOS `.gitignore`. In GitHub, create labels `defect`, `low`, `medium`, `high`, `critical`. Add `docs/adr/0000-template.md` (status, context, decision, consequences).
- [ ] **Step 5:** Write ADR 0001 "Native Swift menu bar app, not App Store". Commit when you choose.

### Task 2: Permission monitor

**Files:**
- Create: `Swiper/Platform/PermissionMonitor.swift`, `SwiperCore/Sources/SwiperCore/AppStatus.swift`
- Test: `SwiperCore/Tests/SwiperCoreTests/AppStatusTests.swift`

**Interfaces:**
- Produces in core: `enum AppStatus { case active, paused, needsPermission, gestureNotWorking }` and `func resolveStatus(enabled: Bool, permissionGranted: Bool, gestureHealthy: Bool) -> AppStatus`
- Produces in app: `final class PermissionMonitor: ObservableObject { @Published var isGranted: Bool; func promptIfNeeded(); func start() }`

- [ ] **Step 1:** Write tests for `resolveStatus`: no permission wins over everything (`needsPermission`); permission but unhealthy gesture gives `gestureNotWorking`; disabled gives `paused`; otherwise `active`. Run: FAIL.
- [ ] **Step 2:** Implement `resolveStatus`. Run: PASS.
- [ ] **Step 3:** Implement `PermissionMonitor`. Hint: check trust with the Accessibility API, prompt once with the prompt option, then poll about once a second while not granted and publish changes. Stop polling once granted.
- [ ] **Step 4:** Review Focus 1: manually launch with permission off, then grant it in System Settings while the app runs. The published value flips to true without a relaunch. Write down the result in your dev notes.

### Task 3: Chord detector (pure logic)

**Files:**
- Create: `SwiperCore/Sources/SwiperCore/MouseInput.swift`, `ChordDetector.swift`
- Test: `SwiperCore/Tests/SwiperCoreTests/ChordDetectorTests.swift`

**Interfaces:**
- Produces:
  - `enum MouseButton { case left, right }`
  - `enum MouseInput { case down(MouseButton, at: TimeInterval), up(MouseButton, at: TimeInterval), moved(dx: Double, dy: Double, at: TimeInterval), tick(at: TimeInterval) }`
  - `enum ChordOutput { case swallow, holdPress(MouseButton), releaseHeldPress(MouseButton), chordBegan, chordMoved(dx: Double, dy: Double), chordEnded }`
  - `struct ChordDetector { init(windowMs: Int); mutating func handle(_ input: MouseInput) -> [ChordOutput]; mutating func reset() -> [ChordOutput] }`
- Rules from the spec: a first press is held; if the other button arrives inside the window it is a chord and neither click is delivered; if movement or the window expiry comes first, the held press is released as a normal click or drag; a second button after that does not start a chord.

- [ ] **Step 1:** Write these tests, using plain timestamps (no real clock):
  - `singleLeftClickIsReleasedAfterWindow`: down(left, 0), tick(41) with a 40 ms window outputs `releaseHeldPress(.left)`.
  - `bothButtonsInsideWindowBeginChord`: down(left, 0), down(right, 20) outputs `chordBegan` and never releases either press.
  - `movementBeforeSecondButtonReleasesHeldPress`: down(left, 0), moved(…, 10) releases the left press (drag-select keeps working).
  - `secondButtonAfterWindowIsNotAChord`: down(left, 0), tick(41), down(right, 60) does not output `chordBegan`.
  - `chordEndsOnceWhenFirstButtonReleases` (Review Focus 4): during a chord, up(left) outputs `chordEnded`; then up(right) outputs nothing but `swallow`, with no click released.
  - `chordMovesAreForwarded`: during a chord, moved outputs `chordMoved` with the same dx, dy.
  - `windowIsConfigurable`: same sequence with windowMs 30 and 50 changes where the boundary falls.
  - `resetDuringChordEndsIt` (Review Focus 3): `reset()` while in a chord outputs `chordEnded`.
- [ ] **Step 2:** Run: FAIL (types missing).
- [ ] **Step 3:** Implement `ChordDetector` as a small state machine: idle, holdingOne(button, since), chord(firstUp: Bool). Keep time as input, never read the clock inside it.
- [ ] **Step 4:** Run: all PASS.
- [ ] **Step 5:** Add the pass-through case (Review Focus 5) as a test at the next layer: the detector is only fed left and right buttons, so Task 4 owns the check that other buttons never reach it. Write ADR 0002 "Chord hold-back instead of delayed replay".

### Task 4: Event tap controller

**Files:**
- Create: `Swiper/Platform/EventTapController.swift`
- Modify: `SwiperApp.swift`

**Interfaces:**
- Consumes: `ChordDetector`, `PermissionMonitor`
- Produces: `final class EventTapController { init(detector: ChordDetector, poster: GesturePosting); func start() throws; func stop(); var isRunning: Bool }`, where `GesturePosting` is defined in Task 6. Until then, use a stub that prints.

- [ ] **Step 1:** Create a session-level event tap for left and right mouse down, up, dragged and mouse moved. Run the callback on the main run loop. Hint: use the tap's raw delta fields for movement, because the cursor will be frozen.
- [ ] **Step 2:** Map `ChordOutput` to actions: `swallow` and `holdPress` drop the event (return nil); `releaseHeldPress` re-posts the held button event, tagged with a marker in its user data field so the tap ignores its own events; `chordBegan` freezes the cursor (disassociate mouse and cursor); `chordEnded` unfreezes it.
- [ ] **Step 3:** Pass every other event type untouched (Review Focus 5). Manual test: middle click, side buttons, scroll wheel and a plain left-drag text selection all behave normally with the app on.
- [ ] **Step 4:** Handle the tap being disabled by timeout or by user input (Review Focus 2): re-enable it and call `detector.reset()` so nothing stays held or frozen. Manual test: hard to trigger, so at minimum unit-test the handler function by calling it with the disabled event type and checking `reset` was called.
- [ ] **Step 5:** `stop()` and permission loss must call `reset()` and unfreeze the cursor (Review Focus 3). Manual test: start a chord, then pause from the menu; the cursor moves again immediately.
- [ ] **Step 6:** Start the tap only when `PermissionMonitor.isGranted` is true and restart on change. Write a defect entry for anything odd you find. Commit when you choose.

### Task 5: Axis lock and gesture mapper (pure logic)

**Files:**
- Create: `SwiperCore/Sources/SwiperCore/AxisLock.swift`, `GestureMapper.swift`
- Test: `SwiperCore/Tests/SwiperCoreTests/AxisLockTests.swift`, `GestureMapperTests.swift`

**Interfaces:**
- Produces:
  - `enum SwipeAxis { case horizontal, vertical }`
  - `struct AxisLock { init(lockDistance: Double); mutating func feed(dx: Double, dy: Double) -> SwipeAxis?; mutating func reset() }`
  - `struct GestureMapper { init(sensitivity: Int, naturalScrolling: Bool); mutating func progress(axis: SwipeAxis, dx: Double, dy: Double) -> Double }`

- [ ] **Step 1:** Write tests:
  - `lockStaysNilUntilDistanceReached`.
  - `lockPicksDominantAxis` (for example dx 10, dy 2 gives horizontal).
  - `lockDoesNotChangeAfterLocking` (a crooked swipe never switches axis).
  - `sensitivityScalesProgress`: same movement gives larger progress at sensitivity 5 than at 1.
  - `naturalScrollingFlipsSign`: same movement gives opposite sign with the flag off.
  - `progressAccumulatesAcrossCalls`.
  - `verticalUpGivesPositiveMissionControlProgress`.
- [ ] **Step 2:** Run: FAIL. Implement. Hint: pick `lockDistance` and the sensitivity curve yourself; write the values you chose into ADR 0003 once you have tried them on screen. Run: PASS.

### Task 6: Gesture poster (the risky part, spike first)

**Files:**
- Create: `Swiper/Platform/GesturePoster.swift`
- Docs: ADR 0004 "Synthesized Dock swipe events", plus a short notes file `docs/adr/0004-notes.md` with what you found

**Interfaces:**
- Produces: `protocol GesturePosting { func begin(axis: SwipeAxis); func update(progress: Double); func end(progress: Double, velocity: Double); func cancel() }` and `final class DockSwipePoster: GesturePosting`
- Consumes: `SwipeAxis` from Task 5

- [ ] **Step 1 (spike, throwaway):** In a scratch command line target, try to post a begin, changed and ended gesture sequence that makes the desktop slide. Research how existing open-source tools do it (event type, subtype and Dock swipe fields are undocumented). Record the field values that work on your macOS version in `0004-notes.md`.
- [ ] **Step 2:** Find out what `end` needs so macOS finishes the slide in the right direction: probably the final progress and a velocity sign. Test with a fast flick and a slow release halfway.
- [ ] **Step 3:** Repeat for upward Mission Control. If continuous tracking proves too hard, fall back to a threshold trigger as the spec allows, and record that in the ADR.
- [ ] **Step 4:** Move the working code into `DockSwipePoster` behind `GesturePosting`. Nothing outside this file knows about the private fields.
- [ ] **Step 5:** Wire it into `EventTapController`: `chordBegan` calls `begin` after the axis locks, `chordMoved` goes through `AxisLock` and `GestureMapper` to `update`, `chordEnded` calls `end`. Manual test: hold both buttons and swipe; desktops follow the hand.
- [ ] **Step 6:** Write the sequence diagram of one swipe in `docs/diagrams/` now, while it is fresh.

### Task 7: Health monitor and compatibility

**Files:**
- Create: `SwiperCore/Sources/SwiperCore/Compatibility.swift`, `Swiper/Platform/HealthMonitor.swift`, `Swiper/Platform/SystemInfo.swift`
- Test: `SwiperCore/Tests/SwiperCoreTests/CompatibilityTests.swift`

**Interfaces:**
- Produces:
  - `struct OSVersion: Equatable { major: Int; minor: Int }`
  - `func compatibility(current: OSVersion, tested: [OSVersion]) -> CompatibilityResult` where `enum CompatibilityResult { case tested, untested }`
  - `final class HealthMonitor: ObservableObject { @Published var isHealthy: Bool; func swipeCompleted(expectedChange: Bool) }`
  - `SystemInfo.naturalScrollingEnabled() -> Bool`, `SystemInfo.currentVersion() -> OSVersion`

- [ ] **Step 1:** Tests: a version in the tested list gives `.tested`; one not in it gives `.untested`; matching ignores the patch number.
- [ ] **Step 2:** Implement `compatibility`. The tested list is data, and for the first release contains only your current version (spec decision). The mockup's three-version list is placeholder text, so update the settings screen to read from this list.
- [ ] **Step 3:** Implement `HealthMonitor`. Hint: observe the active space change notification after a completed horizontal swipe; if a swipe that should have changed desktops did not, count a miss; after several misses in a row set `isHealthy` false. A successful change resets the count. Mark untested versions as unhealthy-by-warning, not blocked.
- [ ] **Step 4:** `SystemInfo.naturalScrollingEnabled` reads the global natural scrolling preference. Feed it to `GestureMapper` on each chord begin so changing the setting works without restarting.
- [ ] **Step 5:** Manual test: simulate failure by making `DockSwipePoster` post nothing; after a few swipes the status becomes `gestureNotWorking`.

### Task 8: Settings store and launch at login

**Files:**
- Create: `SwiperCore/Sources/SwiperCore/SettingsModel.swift`
- Test: `SwiperCore/Tests/SwiperCoreTests/SettingsModelTests.swift`

**Interfaces:**
- Produces: `struct SettingsModel: Equatable { var enabled: Bool; var sensitivity: Int; var clickDelayMs: Int; var launchAtLogin: Bool; static let defaults: SettingsModel; func clamped() -> SettingsModel; var isClickDelayLow: Bool }` and a thin app-side `SettingsStore` that saves it to `UserDefaults`.

- [ ] **Step 1:** Tests: defaults are enabled true, sensitivity 3, clickDelayMs 40; `clamped()` forces sensitivity into 1 to 5 and delay into 30 to 50; `isClickDelayLow` is true below 40 (matches the mockup's warning that offers "Reset to 40 ms").
- [ ] **Step 2:** Implement. Run: PASS. Then implement `SettingsStore` with `UserDefaults` and publish changes.
- [ ] **Step 3:** Apply settings live: changing delay rebuilds the `ChordDetector`; changing sensitivity rebuilds the `GestureMapper`.
- [ ] **Step 4:** Launch at login with `SMAppService.mainApp` register and unregister, and read its real state on open so the toggle matches the system.

### Task 9: UI from the mockups

**Files:**
- Create: `Swiper/UI/PopoverView.swift`, `SettingsView.swift`, `Theme.swift`, `Swiper/Resources/Inter/*`

**Interfaces:**
- Consumes: `AppStatus`, `SettingsModel`, `PermissionMonitor`, `HealthMonitor`, `compatibility`

- [ ] **Step 1:** `Theme.swift`: colors and Inter font helpers from the Global Constraints. Bundle Inter and register it in the target (including the app's Info.plist font list).
- [ ] **Step 2:** `PopoverView`: header with status dot, Swiping toggle, Launch at login toggle, help line, Settings, Quit. All four states from `docs/design/Swiper.dc.html` (active, paused, needs permission, gesture not working). The permission banner opens the Accessibility pane.
- [ ] **Step 3:** `SettingsView`: Permission row, Gesture card (sensitivity, click delay with low-delay warning and reset button, direction note), Launch at login, Compatibility card, version and GitHub link. Gesture controls are disabled while permission is missing.
- [ ] **Step 4:** Compare each state against the mockup side by side and note differences in the dev notes.
- [ ] **Step 5:** Menu bar icon: use a placeholder template image until the icon direction is chosen (Task 11).

### Task 10: Requirements and design documents

**Files:**
- Create: `docs/srs/SRS.md`, `docs/srs/use-cases.md`, `docs/diagrams/component.*`, remaining ADRs

- [ ] **Step 1:** SRS (about one page): purpose, users, functional and non-functional requirements taken from the spec.
- [ ] **Step 2:** Use cases (about five): switch desktop, open Mission Control, first-run permission, pause or resume, handle broken gesture. Use your course template.
- [ ] **Step 3:** Component diagram: mouse input to gesture output, showing the package/app split.
- [ ] **Step 4:** Finish ADRs 0002 to 0004 if not done. Reference defect issue numbers where they changed a decision.

### Task 11: Icon and release

**Files:**
- Create: asset catalog entries, `README.md` install section, GitHub release

- [ ] **Step 1:** Choose an icon direction from `docs/design/Swiper Icons.dc.html`. Export the 1024 px app icon and the template menu bar icon (transparent PNG or PDF, black shape) into the asset catalog.
- [ ] **Step 2:** Build a release archive, zip the `.app`, and test on a clean user account or another Mac: first run, permission flow, a swipe.
- [ ] **Step 3:** README: what it does, install (right-click, Open, because it is unsigned), tested macOS versions (yours only), known risk, how to report a defect.
- [ ] **Step 4:** Create the GitHub release with the zip. Revisit signing later if people use it.

---

## Self-review notes

- Spec coverage: trigger and hold-back (3, 4), axis lock and natural scrolling (5, 7), gesture mechanism and Mission Control (6), menu bar and settings (8, 9), failure reporting (7, 9), permissions (2), documentation (1, 3, 6, 10), distribution (11).
- One conflict found and resolved: the mockup lists three tested macOS versions, but the spec says first release is validated on the owner's current version only. The plan follows the spec (Task 7).
- Task 6 deliberately has no signatures for the private event fields, because they cannot be known before the spike.
