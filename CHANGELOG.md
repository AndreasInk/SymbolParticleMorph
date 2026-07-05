# Changelog

## 0.1.0

- Initial private Swift package extraction.
- Added `SymbolParticleMorph`, `ParticleMorphConfiguration`, `ParticleMorphQuality`, and `SymbolParticleMorphCache`.
- Added Swift Testing coverage for configuration defaults, sampling clamps, particle caps, inset mapping, cache keys, and morph retargeting.

## 0.1.1

- Added raster padding and particle-edge margin so SF Symbol particles do not clip at tight frame bounds.

## 0.1.2

- Render the initial particle field at full opacity so SwiftUI previews and first-frame snapshots are not blank.
