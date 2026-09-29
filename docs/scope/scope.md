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
   - [ ] Pin and stage every source input, then prove configure and compile work offline (AC-1, AC-9)
   - [ ] Generate matching `soh.o2r` with host tools and install the target runtime tree (AC-1, AC-2, AC-3, AC-10)
   - [ ] Register x86_64 package selection and the EmulationStation system (AC-1, AC-4)
   - [ ] Implement the first extraction and archive reuse launcher paths with SDL mapping and exit binding (AC-5, AC-6, AC-7, AC-8)
   - [ ] Prove extraction, later launch, controller, and exit behavior in the x86_64 runtime (AC-1 through AC-10)
- [ ] Verify it: `/check verify Ship of Harkinian integration`
- [ ] Test it: `/test Ship of Harkinian integration`
Spec [0001](../specs/0001-ship-of-harkinian/index.md)

## Deferred

No additional work is queued for this slice.

## Legend

The first unticked box is the next step. Detailed build tasks and acceptance criteria stay in the linked spec.
