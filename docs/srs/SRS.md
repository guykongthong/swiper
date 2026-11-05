# Swiper: Software Requirements Specification

## 1. Purpose
Swiper is a macOS menu bar app that lets an ordinary two-button mouse perform the trackpad's three-finger swipe between desktops and full-screen apps, and the swipe up for Mission Control.

## 2. Users
Mac users who work with a mouse and an external display and cannot easily reach the MacBook trackpad.

## 3. Functional requirements
- FR1. Holding the left and right mouse buttons together and moving the mouse horizontally switches desktops, with the desktops following the mouse.
- FR2. The same trigger with upward movement opens Mission Control.
- FR3. Direction follows the system's natural scrolling setting.
- FR4. A single click or drag-select that is not part of a chord works normally. Plain clicks are held back for at most the chosen delay (30 to 50 ms, default 40 ms).
- FR5. The cursor stays in place while swiping.
- FR6. The user can turn swiping on or off, set sensitivity (1 to 5), set the click delay, and turn launch at login on or off.
- FR7. The app shows a clear status: active, paused, needs permission, or gesture not working.
- FR8. If the Accessibility permission is missing, the app explains how to grant it and starts working once it is granted, without a relaunch.
- FR9. If swipes stop changing desktops, the app says so.

## 4. Non-functional requirements
- NFR1. Plain clicks must never be lost or left stuck, including when the app is paused, quits or loses permission mid-swipe.
- NFR2. The app does not change the user's trackpad settings, including three-finger drag.
- NFR3. Works with any mouse that has left and right buttons.
- NFR4. Distributed as a downloadable build through GitHub Releases. Not available in the Mac App Store.
- NFR5. First release is validated on the author's macOS version only and says so.
- NFR6. UI font is Inter; palette is dark blue and pastel white.

## 5. Constraints and risks
- The gesture relies on undocumented system behavior (see ADR 0004) and may break in a macOS update.
- The app needs the Accessibility permission.
