# Swiper

Swipe between macOS desktops with an ordinary mouse. Hold the left and right buttons together and move the mouse: the desktops follow, like the three-finger swipe on a trackpad. Move up for Mission Control.

> Status: early development. The horizontal swipe works on macOS 27.0 (see `docs/adr/0004-synthesized-dock-swipe.md`).

## Build

Needs only the Xcode Command Line Tools (Swift 6).

```
scripts/test.sh      # unit tests
scripts/bundle.sh    # builds build/Swiper.app
```

The app is unsigned. On first launch, right-click it and choose Open, then grant the Accessibility permission when asked.

## Tested macOS versions

macOS 27.0 (verified by the author on a real swipe). Other versions are untested.

## Docs

`docs/superpowers/specs/` design, `docs/superpowers/plans/` plan, `docs/srs/` requirements and use cases, `docs/diagrams/`, `docs/adr/` decisions.

## Reporting defects

Open a GitHub issue with the `defect` label and one of `low`, `medium`, `high`, `critical`.
