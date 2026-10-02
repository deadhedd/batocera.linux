# Scope: Ship of Harkinian on Batocera

Ship of Harkinian lets Batocera players run a supported Ocarina of Time ROM. This first slice targets x86_64 and proves the package, extraction, and repeat launch path.

**Build approach:** Tracer Bullet (prove the host and target build boundary and the first launch path end to end).
**Workflow:** Beta (run `/check verify`, then `/test` after `/develop`).

## At a glance

| # | Feature | Phase | Status |
|---|---------|-------|--------|
| 1 | Ship of Harkinian integration | Slice 1 | in-progress |

## Slice 1: Ship of Harkinian integration

### 1. Ship of Harkinian integration · in-progress
Add Ship of Harkinian 9.2.3 as an x86_64 Batocera port, with a pinned offline build and a launcher that extracts once and reuses the generated game archive.
**Done when:** the x86_64 image contains the matching read only runtime, EmulationStation accepts `.z64`, `.v64`, and `.n64` ROMs, first launch extracts into `SHIP_HOME`, later launches reuse the archive, and controller input plus the Batocera exit hotkey work.
- [x] Design it (spec): `/architect Ship of Harkinian integration`
- [ ] Build it: `/develop Ship of Harkinian integration`
   - [x] Pin and stage source inputs; both CMake variants use staged sources and disconnected FetchContent (AC-1, partial AC-9)
   - [x] Prove host and target configure/compile with network access blocked (AC-9; preserved without repeating it)
   - [x] Complete and inspect the full x86_64 image (2026-10-02: warm build exited 0; runtime assets, matching archive, read only permissions, and generated system metadata verified)
   - [x] Build host `GenerateSohOtr` and cross-built target `soh`; verify matching archive, complete final-image runtime assets, read only image modes, and no `ZAPD.out` (AC-1, AC-2, AC-3, packaged-permissions portion of AC-10)
   - [x] Register x86_64 package selection and EmulationStation metadata (AC-1, AC-4; final image registers emulator/default core `soh` and exactly `.n64 .v64 .z64`)
   - [x] Implement first extraction and archive reuse paths with SDL mapping and exit binding (AC-5, AC-6, AC-7, AC-8; runtime behavior remains untested)
   - [ ] Prove first-launch extraction, archive reuse, controller input, hotkey exit, and SHIP_HOME/write-boundary behavior in the x86_64 runtime (AC-5 through AC-8 and the runtime portion of AC-10; remaining acceptance work is purely interactive)
- [ ] Verify it: `/check verify Ship of Harkinian integration`
- [ ] Test it: `/test Ship of Harkinian integration`
Spec [0001](../specs/0001-ship-of-harkinian/index.md)

## Deferred

No additional work is queued for this slice.

## Legend

The first unticked box is the next step. Detailed build tasks and acceptance criteria stay in the linked spec.
