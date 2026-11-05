# Swiper: Design

Date: 2026-11-05
Status: draft, awaiting owner approval

## Intent

The owner uses a MacBook on a stand with a second monitor and a regular wireless mouse. The MacBook's trackpad is out of reach, so the three-finger swipe that switches desktops and full-screen apps is unavailable. The only alternatives today are Control + arrow keys or reaching for the trackpad, and both defeat the point of using a mouse.

Swiper is a small macOS menu bar app that lets any ordinary mouse perform the trackpad's three-finger swipe. The desktops should follow the mouse as they follow fingers on a trackpad, with the same smooth animation.

This is also a learning project. The owner wants to apply material from year 3 courses (requirements analysis, software design and architecture, software metrics) to a real product, and wants to release it so other people can use it. The documentation is part of the deliverable, not an afterthought.

## Goals

- The owner no longer reaches for the trackpad to switch desktops or open Mission Control.
- A stranger can download the app from GitHub, grant the needed permission and have it working in a few minutes without help.
- The motion feels like the trackpad: desktops track the hand and settle when the button is released.
- Works with any mouse that has a left and a right button.
- The project leaves behind a credible documentation trail (see Documentation).

## Non-goals

- Other trackpad gestures: pinch, rotate, four-finger swipes, App Exposé.
- Remapping other mouse buttons or acting as a general mouse customization tool.
- Windows or Linux.
- A Mac App Store version (the sandbox blocks what the app needs; see Technical decisions).

## Anti-goals

These count as failure even if the feature technically works.

- Plain left or right clicks feel laggy or get lost.
- The app breaks silently after a macOS update.
- The app interferes with the user's trackpad settings, including three-finger drag.

## Behavior

### Trigger

The user presses left and right mouse buttons together and holds them. This activates swipe mode. It needs no configuration on a standard two-button mouse.

Because a finger landing on one button cannot be told apart from the start of a chord, the app holds back each single button press for a short window (target 30 to 50 ms, owner agreed to this cost). If the second button arrives inside the window, the pair is treated as a chord and neither click is delivered. If not, the held click is released to the system as normal. The window length should be tunable, since it trades click latency against chord reliability.

### While swipe mode is active

- Mouse movement is turned into the same stream of gesture events a three-finger trackpad swipe produces, so macOS animates the desktop change itself.
- Horizontal movement drags between desktops and full-screen apps.
- Upward movement opens Mission Control.
- Direction lock: the app picks horizontal or vertical from the first few pixels of movement and keeps that axis until release, so a slightly crooked swipe does not trigger both.
- Direction follows the system's natural scrolling setting, so the desktops move the way fingers would on the trackpad.
- Releasing the buttons ends the gesture. macOS finishes the slide on its own, as it does on a trackpad.
- The cursor stays where it was while swipe mode is active (assistant's call, see Calls made after review).

### Menu bar app

- A menu bar icon with: on/off, launch at login, open settings, quit.
- First run guides the user through granting the required permission, and shows a clear status when permission is missing.
- Settings expose at least: swipe sensitivity, and the chord window length. Further settings are the builder's call.
- If the gesture mechanism stops working (for example after a macOS update), the app says so plainly in the menu and does nothing else surprising. It must not fail silently.

## Visual design

Owner-approved mockups are in `docs/design/` (`Swiper.dc.html` for the menu bar popover and settings window, `Swiper Icons.dc.html` for the icon options).

- Palette: dark blue `#1e3354` for main surfaces and key controls, warm pastel white `#f8f6f0` for the rest, amber and soft red only for warnings and errors.
- UI typeface: Inter, as in the mockups (owner chose to keep this over Lora). Lora is used only in the logo.
- Popover states: active, paused, needs permission, gesture not working.
- Settings window: permission status, swipe sensitivity, click delay (30 to 50 ms, with a warning and "Reset to 40 ms" when set low), swipe direction note, launch at login, compatibility (tested versions and the user's version), version and GitHub link. Gesture settings are greyed out until permission is granted.
- The icon direction is not chosen yet.

## Technical decisions

Decisions marked **Owner** were made by the owner. Decisions marked **Assistant** are the assistant's proposals and have not been agreed.

| Decision | Choice | By |
|---|---|---|
| Platform and language | Native macOS app in Swift, menu bar app | Assistant |
| Swipe mechanism | Synthesize the trackpad's Dock swipe gesture events so desktops follow the hand | Owner |
| Distribution | Downloadable build through GitHub Releases, unsigned for now (user right-clicks and chooses Open once). Revisit signing and notarization (Apple Developer Program) if people use it | Owner |
| Mac App Store | Not supported | Follows from the swipe mechanism and global event listening, which the sandbox blocks |
| Mouse event capture | Global event tap for mouse buttons and movement, which needs the Accessibility permission | Assistant |

### Known risk

Synthesizing Dock swipe events depends on undocumented system behavior. Apple can change it in any macOS update. The owner chose this approach knowingly because the shortcut-based alternative (sending Control + arrow) cannot make desktops follow the hand. Consequences for the design:

- The gesture code is isolated behind a single interface so it can be replaced or patched without touching trigger detection.
- Failure to produce a working gesture is detected and reported to the user (see Anti-goals).
- The decision and its risk are recorded as an ADR.
- A fallback to the Control + arrow shortcut (one-flick, fixed animation) is a possible later addition. It is not in scope now. The owner has not asked for it.

## Documentation (part of the deliverable)

Proportionate to a small app. It lives in the repo as plain Markdown so it stays current.

- **Requirements (from Software Requirement Analysis):** a short SRS of about one page and roughly five use cases (for example: switch desktop, open Mission Control, first-run permission setup, toggle the app, handle a missing permission or a broken gesture).
- **Design (from Software Design and Architecture):** three or four diagrams, at least a component diagram (mouse input to gesture output) and a sequence diagram of one swipe. Short ADRs for the main decisions, starting with the swipe mechanism, the chord hold-back, and the language and platform choice.
- **Defects (from Software Metrics):** a defect log kept while building. Proposed as GitHub issues with a defect label and a severity label. The owner has not confirmed this format.
- Should read as a record of real decisions, not paperwork.

## Working approach

- The assistant writes the code and the owner reviews it (changed from the earlier plan where the owner wrote it).
- Design comes first. Nothing is built until the owner approves this document.
- Repo: https://github.com/guykongthong/swiper, cloned at `~/dev/personal/swiper`.

## Calls made after review

These were settled by the assistant after a builder review, not by the owner. The owner should check them.

- **Drags and the chord window:** a single press is held back only while nothing else happens. If the mouse moves, or the window ends, before a second button arrives, the held press is released immediately and it is a normal click or drag. A second button pressed after that does not start a chord. So drag-selecting text works, and the cost is that a chord only works if both buttons land within the window.
- **Cursor:** frozen in place during swipe mode, so it does not drift across the screen while swiping.
- **Mission Control:** uses the same gesture mechanism as the horizontal swipe, and tracks the hand the same way. If that proves too hard, a simple threshold trigger is an acceptable first step.
- **Detecting a broken gesture:** a list of macOS versions the app has been tested on, plus a check that the active desktop actually changed after a completed horizontal swipe. If the check fails repeatedly, the menu shows the warning.
- **macOS versions:** the first release is validated on the owner's current macOS version only, and the README says so plainly. Supporting a range is a later goal.
- **Plan format:** the plan is a guide for the owner to implement, broken into steps with pseudocode and hints, not code for the assistant to write.
- **Defect severity:** four levels (low, medium, high, critical), applied as GitHub labels alongside a `defect` label. Set the labels up before the first bug is logged.

## Left to the builder

- Exact mapping from mouse distance to gesture progress, and the sensitivity defaults.
- Direction lock threshold.
- Minimum supported macOS version (first release targets the owner's current one).
- Settings screen design and the exact onboarding flow.
- Which permissions beyond Accessibility are needed in practice (for example Input Monitoring).
- Testing approach, including how to test event handling without a physical mouse.
- Project structure, build tooling and how releases are packaged.
