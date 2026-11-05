# 0003. Gesture tuning values

Status: proposed (starting values, not yet tried on a real desktop)
Date: 2026-11-05

## Context
Mouse movement has to become gesture progress, and a crooked swipe must not trigger both axes.

## Decision
- Axis lock distance: 8 pixels of accumulated movement, then the dominant axis wins until release.
- Progress: 600 pixels of movement equals 1.0 at the default sensitivity.
- Sensitivity steps 1 to 5 scale that by 0.5, 0.75, 1.0, 1.5, 2.0.
- With natural scrolling on, moving the mouse right gives positive progress; with it off the sign flips. Moving up gives positive progress for Mission Control.

## Consequences
These are guesses. Change them after feeling a real swipe, and record the values that felt right here. The sign convention may also need flipping once the real gesture direction is known.
