# 0004. Synthesized Dock swipe events

Status: accepted (mechanism chosen by the owner), verified on macOS 27.0
Date: 2026-11-05

## Context
The owner wants desktops to follow the mouse the way they follow fingers on a trackpad. Sending Control + arrow gives a fixed animation that does not track the hand.

## Decision
Post synthesized Dock swipe gesture events (begin, changed, ended) from `DockSwipePoster`. This relies on undocumented system behavior that Apple can change in any macOS update. All of it sits behind the `GesturePosting` protocol in one file. A health check reports when swipes stop changing the desktop.

## Consequences
- A macOS update can silently break the gesture. The app detects this and says so in the menu.
- Not allowed in the Mac App Store.
- A fallback to Control + arrow (one flick, fixed animation) is possible later and is not in scope.

## What we found
- On macOS 27 the Dock ignores CGEvent value fields. It reads an internal HID event (type DockSwipe, with motion, flavor and progress fields) attached to a type 30 CGEvent. A velocity child event carries the exit speed on end.
- The event is built through private IOKit and SkyLight functions looked up at runtime, so a missing function disables the gesture softly instead of crashing.
- Before macOS 27 the Dock read value fields on a pair of CGEvents (types 29 and 30). That path is kept but untested.
- Verified by the owner on macOS 27.0: the desktops follow the mouse and settle on release.
- Reference points: open-source Mac Mouse Fix and yabai for the approach, Apple's open-source IOKit headers for field numbers.
