# Swiper: Use cases

## UC1. Switch desktop
- Actor: user. Precondition: permission granted, swiping on.
- Main flow: 1) User holds left and right buttons. 2) User moves the mouse sideways. 3) Desktops follow the mouse. 4) User releases the buttons. 5) macOS settles on a desktop.
- Alternate: movement too small, nothing switches. Cursor stays frozen while the buttons are held.

## UC2. Open Mission Control
- Actor: user. Precondition: as UC1.
- Main flow: 1) User holds both buttons. 2) User moves the mouse up. 3) Mission Control opens. 4) User releases the buttons.

## UC3. First-run permission setup
- Actor: user. Precondition: app launched without Accessibility permission.
- Main flow: 1) Menu shows "Needs permission". 2) User clicks Open System Settings. 3) User switches Swiper on. 4) Status turns Active without a relaunch.
- Alternate: user never grants it; swiping stays unavailable and normal clicks are unaffected.

## UC4. Pause or resume swiping
- Actor: user. Main flow: user toggles Swiping in the menu. Paused: mouse works as normal. Resume: swiping works again. If paused mid-swipe, the gesture is cancelled and the cursor is released.

## UC5. Handle a broken gesture
- Actor: system. Precondition: swipes complete but the desktop does not change several times in a row.
- Main flow: 1) Health check counts misses. 2) After three, status shows "Gesture not working". 3) Compatibility panel shows the macOS version and whether it was tested. 4) Clicks keep working normally.
