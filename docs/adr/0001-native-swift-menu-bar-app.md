# 0001. Native Swift menu bar app, not App Store

Status: accepted
Date: 2026-11-05

## Context
Swiper has to listen to global mouse events and post system gesture events. The Mac App Store sandbox blocks both. The owner wants anyone to be able to download and use it.

## Decision
Build a native Swift menu bar app (SwiftUI `MenuBarExtra`), distributed as a downloadable build on GitHub Releases, unsigned for now. Build tooling is Swift Package Manager plus a script that assembles the .app, because only the Command Line Tools are installed (no Xcode).

## Consequences
- No App Store listing.
- Users right-click and choose Open on first launch until the app is signed and notarized.
- No asset catalog; the icon is shipped as an .icns file.
