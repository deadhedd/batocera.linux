# 0001. Ship of Harkinian on Batocera rationale

## Context

Shipwright 9.2.3 builds the `soh.elf` game and the `soh.o2r` runtime archive through separate CMake targets. The archive target invokes Python and ZAPD. A Batocera cross build must not execute the target ZAPD binary on the build host, and the archive must match the game binary's source revision.

The upstream configure and build graph also contains source downloads. Batocera needs each source and the controller database available through Buildroot before CMake configures. The shipped runtime tree must stay read only, while SoH creates its extracted game archive and all writable state under one selected home directory.

## Options considered

### Option 1: Use the target CMake graph for both tools and game

This keeps one configure and one build invocation. Under the Batocera cross compiler, however, the `ZAPD` executable is a target binary. `GenerateSohOtr` would then try to run that target binary on the build host (basis: Shipwright's `GenerateSohOtr` target depends on `ZAPD`).

**Pros**:

* Uses the upstream target graph with few package changes.

**Cons**:

* Crosses the host and target boundary incorrectly and cannot produce the archive reliably.

### Option 2: Build host and target variants through one Buildroot package

The package uses one full Shipwright commit and enables Buildroot's Git submodule fetch support. Its host CMake variant builds `GenerateSohOtr` with native tools. Its target CMake variant builds `soh` with the cross compiler and consumes the versioned host output (basis: Buildroot supports host and target variants of a package and target dependencies on `host-foo`).

**Pros**:

* Buildroot owns the source download, host tool, target binary, and dependency ordering.
* The host and target variants share the same package version and source closure.
* Upstream keeps ZAPD and its library graph together, reducing custom tool behavior.

**Cons**:

* The host variant configures the full root project and may require additional host libraries.
* It builds some source for both host and target.

### Option 3: Make a dedicated host ZAPD package and custom archive script

This builds ZAPD from the ZAPDTR source and runs OTRExporter as a separate host package step. The target package remains a conventional cross build (basis: Shipwright's ZAPD, OTRExporter, and libultraship source graph).

**Pros**:

* The host build may configure fewer parts of Shipwright.
* Host tool installation can be kept small.

**Cons**:

* The package must reproduce upstream asset copying, shader staging, Python flags, and artifact placement.
* A second source recipe must keep ZAPDTR and OTRExporter pins aligned with the Shipwright source.

## Rationale

Option 2 puts the host and target boundary in Buildroot's package graph, where the host compiler, cross compiler, and dependency order are explicit. It also reuses Shipwright's own `GenerateSohOtr` command, which copies the libultraship shader inputs and passes the same project version used by `soh.elf` (basis: Shipwright 9.2.3 CMake targets and the existing Buildroot host package infrastructure).

The full host configure is the main cost, so the first build spike must prove its host dependencies. If the selected architecture cannot configure and build `GenerateSohOtr` correctly, stop and return to an architecture decision before changing the split. Option 3 is recorded as an alternative for that decision, not as an approved fallback. Any revised design must preserve pinned source identity and must never run target ZAPD on the host (basis: Buildroot host package dependency rules and Shipwright's ZAPD and OTRExporter source graph).

For sources, use Buildroot's Git submodule support for Shipwright's own gitlinks. Pin other FetchContent archives and directly downloaded files as package extra downloads with hashes, stage them before configure, and pass local paths to CMake. The x86_64 target uses Shipwright's Linux SDL2 and OpenGL path with Batocera SDL2 and Mesa/OpenGL. Existing Batocera libraries may satisfy its other `find_package` calls only when their version and API match the pinned source; otherwise use Buildroot to stage the exact revision declared by Shipwright. Keep host dependencies separate from target libraries. `FETCHCONTENT_FULLY_DISCONNECTED=ON` covers FetchContent only; direct downloads need local-input patches, and configure plus compile must be verified with network blocked for all subprocesses (basis: local Buildroot package patterns and the configure calls audited at the 9.2.3 source revision).

## Source audit

### `soh.o2r` source closure

At commit `cb71e22a79bc5d1f688fa881795bbd93094895fc`, the `GenerateSohOtr` target invokes the ZAPD executable target and host Python. The exporter uses `--norom`, the custom asset directory, and `--port-ver 9.2.3`. It does not require the runtime `assets/extractor` or `assets/xml` tree. It does require the Shipwright custom assets, OTRExporter script and linked code, ZAPDTR, libultraship code, and libultraship fast shader assets.

At runtime, `soh.elf` links ZAPDLib and uses it for ROM extraction, which writes `oot.o2r` or `oot-mq.o2r` under `SHIP_HOME`. This is why the installed tree needs extractor assets and XML but does not need the standalone `ZAPD.out` executable.

### Configure and build network calls

The audited CMake graph fetches ImGui `v1.91.9b-docking`, StormLib `v9.25`, libgfxd, BS thread pool `v4.1.0`, prism, and dr_libs through FetchContent. It directly downloads `stb_image.h`, and it downloads `gamecontrollerdb.txt` from mutable `master`. The gamecontroller database pin in this spec is a release era snapshot, not a revision proven to have been used by upstream release CI.

The Buildroot package should stage the exact selected inputs and use `FETCHCONTENT_SOURCE_DIR_*` overrides with fully disconnected FetchContent. A narrow patch supplies the STB header and controller database paths. CPack must not run, so its linuxdeploy download is outside the package build path.

### Chosen controller database snapshot

Use SDL_GameControllerDB commit `e6f9f10b2616badca4849e2d8ac1fa175114d854`, the latest commit before the Shipwright 9.2.3 commit timestamp. Its `gamecontrollerdb.txt` SHA256 is `f857275fe139ddf724ede6500b7dc05af20cddb88eb1136a5a1218b33151c07c`. Record both in the Buildroot package metadata so the normal configure step never downloads the mutable upstream file (basis: official SDL_GameControllerDB commit and its file hash).

## References

**Project sources**:

* Batocera `package/batocera/ports/opengoal/opengoal.mk` and `package/batocera/ports/jazz2-native/jazz2-native.mk` for native port package patterns.
* Batocera `python-src/batocera-launch/batocera_launch/emulators/opengoal.py` and `python-src/batocera-launch/batocera_launch/emulator.py` for SDL mapping and hotkey mechanisms.
* Buildroot generic and CMake package infrastructure in `buildroot/package/pkg-generic.mk`, `buildroot/package/pkg-download.mk`, and `buildroot/docs/manual/adding-packages-directory.adoc`.

**Practices & standards**:

* Use separate host and target tools in a cross build. Never execute a target binary on the build host.
* Pin build inputs and fail closed when an offline CMake source is missing.

**Links**:

* Shipwright 9.2.3 root CMake target graph: https://github.com/HarbourMasters/Shipwright/blob/cb71e22a7/CMakeLists.txt
* Shipwright Linux executable target: https://github.com/HarbourMasters/Shipwright/blob/cb71e22a7/soh/CMakeLists.txt
* OTRExporter extraction script at its pinned commit: https://github.com/HarbourMasters/OTRExporter/blob/32e088e28c8cdd055d4bb8f3f219d33ad37963f3/extract_assets.py
* ZAPD CMake graph at its pinned commit: https://github.com/HarbourMasters/ZAPDTR/blob/ee3397a365c5f350a60538c88f0643f155944836/ZAPD/CMakeLists.txt
* Buildroot package reference: https://buildroot.org/downloads/manual/manual.html#_generic_package_reference
* Selected controller database revision: https://github.com/mdqinc/SDL_GameControllerDB/commit/e6f9f10b2616badca4849e2d8ac1fa175114d854
