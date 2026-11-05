# 0004. Synthesized Dock swipe events

Status: accepted (mechanism chosen by the owner), implementation UNVERIFIED
Date: 2026-11-05

## Context
The owner wants desktops to follow the mouse the way they follow fingers on a trackpad. Sending Control + arrow gives a fixed animation that does not track the hand.

## Decision
Post synthesized Dock swipe gesture events (begin, changed, ended) from `DockSwipePoster`. This relies on undocumented system behavior that Apple can change in any macOS update. All of it sits behind the `GesturePosting` protocol in one file. A health check reports when swipes stop changing the desktop.

## Consequences
- A macOS update can silently break the gesture. The app detects this and says so in the menu.
- Not allowed in the Mac App Store.
- A fallback to Control + arrow (one flick, fixed animation) is possible later and is not in scope.

## Status of the implementation
`DockSwipePoster` was written without being able to run it against a real desktop. The field numbers and values are best recollection of how open-source tools do it and are unconfirmed. Next step for the owner: hold both buttons and swipe on the real Mac, then correct the constants in the `Fields` enum until the desktop slides. Record what worked here.
