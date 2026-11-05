# 0002. Chord hold-back instead of delayed replay

Status: accepted
Date: 2026-11-05

## Context
The trigger is left + right pressed together. When the first button goes down, the app cannot yet tell a click from the start of a chord.

## Decision
Hold back the first press for a short, tunable window (30 to 50 ms, default 40 ms). If the other button joins inside the window, it is a chord and neither click is delivered. If the window ends, or the mouse moves, or the button is released first, the held press is re-posted as a normal click or drag. A second button after the window is not a chord. The decision logic is a pure state machine (`ChordDetector`) with time passed in as input.

## Consequences
- Every plain click is delayed by up to the window length.
- Drag-selecting text works because movement releases the held press immediately.
- Both buttons must land within the window for a swipe to start.
- The state machine is fully unit tested without a mouse.
