# 0001. Ship of Harkinian on Batocera

**Date**: 2026-09-27
**Status**: In Progress — the full x86_64 image build and final-filesystem inspection pass. AC-1 through AC-4 and the packaged-permissions portion of AC-10 are proven; AC-9 remains proven without repetition. The remaining acceptance work is interactive runtime verification of AC-5 through AC-8 and the write-boundary portion of AC-10.

## Summary

This spec adds Ship of Harkinian as an x86_64 Batocera port. Buildroot will create the game archive with host tools from the same pinned Shipwright source as the target game binary, then install both with the runtime assets. The launcher will pass a ROM only for the first extraction and use Batocera controller and exit handling.

## Requirements

**User stories**:

* As a Batocera player, I want to launch my supported Ocarina of Time ROM from EmulationStation so that Ship of Harkinian can extract and run it.
* As a Batocera player, I want later launches to reuse SoH's generated game archive, controller mapping, saves, and settings.

**Acceptance criteria**:

* **AC-1**: Buildroot builds Ship of Harkinian 9.2.3 for x86_64 only.
* **AC-2**: Buildroot generates the matching `soh.o2r` with a host native ZAPD tool. The host tool and target `soh.elf` use the same Shipwright source revision. The build never executes a target binary on the host.
* **AC-3**: The final image contains a complete read only runtime tree with `/usr/lib/soh/soh.elf`, `/usr/lib/soh/soh.o2r`, `/usr/lib/soh/gamecontrollerdb.txt`, `/usr/lib/soh/assets/extractor`, and `/usr/lib/soh/assets/xml`. It does not need the standalone installed `ZAPD.out`.
* **AC-4**: EmulationStation exposes a Ship of Harkinian system that accepts lowercase `.z64`, `.v64`, and `.n64` ROM extensions.
* **AC-5**: When neither generated game archive exists, launch runs `soh.elf /absolute/path/to/game.z64` with `SHIP_HOME=/userdata/saves/soh` and Batocera SDL controller configuration.
* **AC-6**: When `oot.o2r` or `oot-mq.o2r` exists under `SHIP_HOME`, launch runs `soh.elf` with no ROM argument.
* **AC-7**: Controller input works through Batocera's standard SDL controller configuration mechanism.
* **AC-8**: The Batocera exit hotkey exits SoH gracefully through `hotkeygen_context`.
* **AC-9**: All sources and `gamecontrollerdb.txt` are pinned Buildroot inputs. Configure and compile complete without network access, and the package does not invoke CPack.
* **AC-10**: The installed `/usr/lib/soh` runtime tree is read only. Configuration, saves, generated archives, mods, logs, and other writable SoH state stay under `/userdata/saves/soh`.

## Decision

**Chosen option**: Option 2: Build the host archive and target game from one pinned Buildroot package source (basis: Shipwright 9.2.3 CMake target graph and Buildroot host package infrastructure).

Use one Shipwright commit and one submodule closure for both Buildroot package variants. The host variant builds `GenerateSohOtr` and installs its `soh.o2r` into a versioned host path. The target variant builds only `soh`, then installs that host artifact beside `soh.elf` and the runtime assets. Stage FetchContent sources, STB, and the controller database before CMake runs, and make CMake reject any attempt to fetch during configure.

## Feature design

**Package and dependency structure**:

* Add `package/batocera/ports/soh/Config.in`, `soh.mk`, `soh.emulator.yml`, and a hash file. Register the port from root `Config.in` and select it from `package/batocera/core/batocera-system/Config.in` only for x86_64.
* Set the target package source to the full Shipwright commit `cb71e22a79bc5d1f688fa881795bbd93094895fc`, with `SOH_SITE_METHOD = git` and `SOH_GIT_SUBMODULES = YES`. Buildroot's source download phase then fetches the recorded pins for OTRExporter `32e088e28c8cdd055d4bb8f3f219d33ad37963f3`, ZAPDTR `ee3397a365c5f350a60538c88f0643f155944836`, and libultraship `fdcaf6336776d24a6408d016b0a52243f108f250`. No configure or compile step initializes submodules.
* Define host and target CMake variants from the same `soh.mk` and version variables. Add `host-soh` as a target dependency. The host build uses the host compiler and builds only `GenerateSohOtr`; the target build uses the cross compiler and builds only `soh`.
* Configure the x86_64 Linux SDL2 and OpenGL path, using Batocera's SDL2 and Mesa/OpenGL packages. Add target dependencies for PNG, Ogg, Vorbis, Opus, OpusFile, libzip, nlohmann-json, tinyxml2, and spdlog, plus the platform audio and graphics libraries required by that path. Use an existing Batocera package only when its version and API satisfy the pinned Shipwright configure and build. Otherwise, stage the exact source revision declared by pinned Shipwright through Buildroot. The host variant uses host dependencies and tools only; it must not link target libraries.
* Pin and hash each required FetchContent archive as a Buildroot extra download. Extract these sources into the package build tree and pass their local paths through `FETCHCONTENT_SOURCE_DIR_*`. Set `FETCHCONTENT_FULLY_DISCONNECTED=ON` for host and target configure. This only disables FetchContent downloads; it does not block the direct STB or controller database downloads, so patch both direct download sites to consume staged files.
* Add the direct STB header and controller database to Buildroot extra downloads with hashes. Patch the direct STB download to consume a staged `stb_image.h` from the revision declared at the pinned Shipwright source. Patch the controller database download to copy a staged file. Pin that file to SDL_GameControllerDB commit `e6f9f10b2616badca4849e2d8ac1fa175114d854` with SHA256 `f857275fe139ddf724ede6500b7dc05af20cddb88eb1136a5a1218b33151c07c`.
* Enumerate every configure/build network call found in the pinned source graph and patch it to use a staged input or fail if the input is absent. The offline build proof must block network access for CMake and its subprocesses during both configure and compile.
* Add only narrow CMake changes for these local inputs and the network guard. Do not invoke CPack, disable SDL HIDAPI, or replace unrelated upstream build behavior.

**Host artifact boundary**:

`GenerateSohOtr` is a CMake target separate from the Linux `soh` executable. It builds and runs the host `ZAPD` executable, copies the pinned libultraship fast shader assets into the custom asset tree, and runs the pinned OTRExporter `extract_assets.py` with `--norom`, `--custom-otr-file soh.o2r`, the custom asset path, and project version `9.2.3`. Its required source inputs are:

* Shipwright source at the pinned 9.2.3 commit, including `soh/assets/custom`.
* OTRExporter at the recorded submodule commit, including `extract_assets.py` and exporter code linked into ZAPD.
* ZAPDTR at the recorded submodule commit.
* libultraship at the recorded submodule commit, including `src/fast/shaders` and code needed by ZAPD.
* Buildroot host Python and the native libraries required by the host CMake graph.

`soh/assets/extractor` and `soh/assets/xml` are required at runtime for ROM extraction. They are not inputs to `GenerateSohOtr --norom`. Shipwright's target post-build step also places the extractor files directly under `assets`, so the package retains those flat runtime entries and the source `extractor` subtree. Install the host output at `$(HOST_DIR)/share/soh/$(SOH_PROJECT_VERSION)/soh.o2r`. The target package must verify that exact file exists and copy it into the final runtime tree. The shared commit, the project version passed to OTRExporter, and the versioned output path prevent stale host output from being paired with a different target build.

**Installed filesystem layout**:

* Read only executable and assets: `/usr/lib/soh/soh.elf`, `/usr/lib/soh/soh.o2r`, `/usr/lib/soh/gamecontrollerdb.txt`, `/usr/lib/soh/assets/extractor`, and `/usr/lib/soh/assets/xml`. Preserve these upstream relative paths beside the executable because SoH locates runtime assets relative to itself.
* Writable SoH state: `/userdata/saves/soh`, set through `SHIP_HOME`. Keep configuration, saves, generated `oot.o2r` and `oot-mq.o2r`, mods, logs, and other writable files together there.
* Do not install `ZAPD.out` for normal runtime ROM extraction. SoH links target `ZAPDLib` and performs runtime extraction internally.
* Apply final read only modes through `SOH_ROOTFS_PRE_CMD_HOOKS` under fakeroot. Keep the real Buildroot target tree owner-writable so temporary filesystem-tree cleanup can succeed.

**Batocera integration surface**:

* Add the SoH package choice and x86_64 system selection.
* Register the `soh` emulator entry point in `python-src/batocera-launch/pyproject.toml` and package selection in `batocera-launch.mk`.
* Add the minimal `soh` defaults in `python-src/batocera-launch/resources/defaults/config.yml` and implement `python-src/batocera-launch/batocera_launch/emulators/soh.py`.
* Add SoH package metadata in `soh.emulator.yml` and a Ship of Harkinian system entry in `package/batocera/emulationstation/batocera-es-system/es_systems.yml`. Use `soh` for the system and emulator identifiers, select `soh` as the default emulator, and use `/userdata/roms/soh` as the ROM directory. Expose only lowercase `.z64`, `.v64`, and `.n64`; add no graphical SoH settings.

**Launcher lifecycle**:

1. Create `/userdata/saves/soh` if needed. If creation fails, report the failure through Batocera's normal launch error path and stop. Set it as the working directory and set `SHIP_HOME` to `/userdata/saves/soh`. Resolve the selected ROM to an absolute path.
2. If neither `SHIP_HOME/oot.o2r` nor `SHIP_HOME/oot-mq.o2r` is a regular file, invoke the absolute installed executable with the absolute ROM path as one argument.
3. If either archive exists, invoke the executable with no ROM argument. Passing the ROM again would make SoH offer extraction again.
4. Set `needs_sdl_game_controller_config = True` so the base `Emulator` supplies Batocera's SDL mapping. Use an exit binding named `soh` with `KEY_LEFTALT` plus `KEY_F4` in `hotkeygen_context`, matching the existing OpenGOAL convention. Verify that this binding reaches SoH's graceful quit path in the x86_64 runtime spike.

Pass process arguments as an argv list. Do not build a shell command from the ROM path. Do not add an OpenGOAL style build marker, squashfs management, or desktop toolbox actions.

EmulationStation owns extension filtering. The standard Batocera launch path reports process start or exit failures, and SoH reports invalid ROM and extraction errors through its normal logs. Do not add a separate error UI. Package verification owns checking that all required runtime files and directories are installed. If a failed extraction leaves an unusable `oot.o2r` or `oot-mq.o2r`, recovery is to remove that generated archive from `/userdata/saves/soh` and relaunch the original ROM; the launcher never deletes generated files automatically.

**Data model sketch**: None. Persistent state is the SoH filesystem tree under `SHIP_HOME`. The launcher derives readiness from the generated archive files and stores no separate marker.

**State transitions**:

`No generated archive` → launch with ROM path → SoH extraction → `oot.o2r` or `oot-mq.o2r` exists → launch without ROM path.

**API surface**:

| Action | Method | Key inputs | Key outputs | Auth | Key errors |
|---|---|---|---|---|---|
| Launch SoH | Local process execution | selected ROM absolute path; Batocera config | argv, `SHIP_HOME`, SDL config, hotkey context | Local Batocera session | SoH home creation failure, missing executable or runtime assets, process failure |

**Value sourcing**:

| Action | Value produced or displayed | Source |
|---|---|---|
| Package launch | executable path and runtime asset paths | Installed tree under `/usr/lib/soh`, from `soh.mk` |
| First launch | ROM argument | EmulationStation selected ROM, resolved to an absolute path by `batocera-launch` |
| First or later launch | archive readiness | Regular files `SHIP_HOME/oot.o2r` and `SHIP_HOME/oot-mq.o2r` |
| Every launch | writable state path | Fixed contract `SHIP_HOME=/userdata/saves/soh` |
| Every launch | SDL controller mapping | Base `Emulator` mapping enabled by `needs_sdl_game_controller_config` |
| Every launch | exit action | SoH `hotkeygen_context` exit binding; graceful quit mechanism proven by runtime spike |
| EmulationStation system | accepted file extensions | `soh.emulator.yml` and the `soh` system entry |

**Key invariants**:

* Host and target builds use the same full Shipwright commit and gitlink revisions.
* The target install copies `soh.o2r` only from the matching versioned host output.
* No target executable runs on the build host.
* No network access occurs during CMake configure or compile.
* SoH writable data stays under `/userdata/saves/soh` for this slice.
* A recognized generated archive suppresses the ROM argument on later launches.
* The installed runtime tree is read only, and SoH writes its generated state under `SHIP_HOME`.

**Security model**: No account or network API is involved. The executable and bundled runtime assets are image owned and read only. SoH writes only to its `SHIP_HOME`. The launcher passes the ROM path as a process argument, not through shell evaluation.

**Configuration required**:

* `SHIP_HOME`: set by the launcher to `/userdata/saves/soh`; users do not configure this path in the graphical settings.

**Critical test scenarios**:

* Launcher unit tests stub the process boundary and check home creation, absolute argv and environment values, SDL mapping, and exit context. Exercise the no archive case and each archive name separately; also confirm home creation failure follows the normal launch error path. This verifies **AC-5**, **AC-6**, **AC-7**, and the launcher portion of **AC-8**.
* System and runtime input: only the three lowercase extensions are exposed, the SDL mapping is present, and the exit binding works, verifies **AC-4**, **AC-7**, and **AC-8**.
* Package proof: x86_64 image has the complete runtime tree, matching archive and executable, no installed `ZAPD.out`, and configure and compile succeed without network, verifies **AC-1**, **AC-2**, **AC-3**, and **AC-9**.
* Runtime write boundary: with the installed runtime tree read only, first extraction and a later launch both work and all generated writable state appears under `SHIP_HOME`, verifies **AC-10**.

## Build plan

The requested tracer bullet starts with the highest risk seam, then joins it to EmulationStation and the launcher, and finally proves the real controller and exit paths on x86_64.

1. Pin Shipwright, its three submodules, the FetchContent sources, STB, and the controller database in Buildroot. Add local source staging and patches for every network call. Verify that the source phase supplies every input and both CMake configure steps work with network blocked. This satisfies **AC-1** and **AC-9**.
2. Add the host and target package variants. Build `GenerateSohOtr` with the host toolchain, build only target `soh` with the cross toolchain, then install the matching `soh.o2r` and full relative runtime tree. Verify version matching and absence of a target ZAPD execution or installed `ZAPD.out`. This satisfies **AC-1**, **AC-2**, and **AC-3**.
3. Register package selection, the emulator metadata, and the EmulationStation system with the three lowercase ROM extensions. Verify the package is selected only for x86_64 and the system is visible. This satisfies **AC-1** and **AC-4**.
4. Add the launcher entry point, defaults, and SoH emulator class. Implement the archive check, argv behavior, fixed `SHIP_HOME`, SDL mapping, and exit context. Add focused launch tests. This satisfies **AC-5**, **AC-6**, **AC-7**, and **AC-8**.
5. After the isolated package proof passes, build a normal x86_64 image. Inspect its packaged SoH runtime and EmulationStation metadata, then use EmulationStation to extract a ROM with `/usr/lib/soh` read only, confirm the generated archive under `SHIP_HOME`, relaunch without a ROM argument, test controller input, and confirm the exit hotkey exits gracefully. This satisfies **AC-1** through **AC-10**.

## Package-stage evidence

This integration depends on the companion Buildroot fork at `https://github.com/deadhedd/buildroot.git`, pinned here at `6b9418e58315601c880c0d3392435b2b50933949`. That commit includes the SDL2 CMake-prefix correction required by this integration. Before merge readiness, the companion Buildroot changes must still be reconciled with canonical Buildroot.

On 2026-09-29, `make x86_64-pkg PKG=soh` completed successfully. The target CMake cache selects Buildroot's `x86_64-buildroot-linux-gnu` toolchain, and the linked `soh.elf` is an ELF64 x86-64 executable. The host CMake cache selects native `/usr/bin/gcc` and `/usr/bin/g++` with `SOH_ASSET_GENERATOR_ONLY=ON`.

The host-generated archive, its versioned host install, and the target package-stage copy have the same SHA-256: `b19d79165b71cca38dbabaf542791a1a9fc27d2eb54c7d650761da83c258dc1e`. The target build log contains `Built target ZAPDLib` and `Built target soh`; no target `ZAPD` executable was produced or run. The package-stage `/usr/lib/soh` tree includes `soh.elf`, `soh.o2r`, `gamecontrollerdb.txt`, `assets/extractor`, and `assets/xml`; the files and directories have no write bits, and no `ZAPD.out` is installed.

Both CMake variants set `FETCHCONTENT_FULLY_DISCONNECTED=ON` and point at the six staged FetchContent sources. STB and the controller database are staged Buildroot downloads, and the direct CMake download sites use those staged files.

### Offline configure and compile proof (AC-9)

On 2026-09-29, the host and target SoH CMake build directories were removed so configure and compile could not reuse their previous generated build trees. No other `output/x86_64` contents were removed. The extracted Shipwright sources, Buildroot download cache, dependency build directories, and shared ccache were preserved. The two package builds ran with `CCACHE_DISABLE=1`, so the compilers rebuilt their objects while leaving the shared ccache intact.

The Batocera wrapper in `docker/docker.mk` inserts `DOCKER_OPTS` into its `docker run` invocation. The exact setting `DOCKER_OPTS=--network=none` gave the build container Docker's isolated `none` network namespace for the preflight, host configure/compile, and target configure/compile/link/install. In that same container immediately before both package targets, `/proc/net/dev` listed only `lo`, `/proc/net/route` had no routes, and `curl --silent --show-error --connect-timeout 2 --max-time 3 http://1.1.1.1/ --output /dev/null` failed with curl exit 7 (`Could not connect to server`). This tests actual connectivity in the namespace used by both builds; `FETCHCONTENT_FULLY_DISCONNECTED=ON` is only an additional CMake guard.

The build command was:

```sh
make x86_64-shell CMD="bash -lc 'echo NETWORK_INTERFACES; cat /proc/net/dev; echo NETWORK_ROUTES; cat /proc/net/route; if curl --silent --show-error --connect-timeout 2 --max-time 3 http://1.1.1.1/ --output /dev/null; then echo NETWORK_CANARY_UNEXPECTED_SUCCESS; exit 1; else echo NETWORK_CANARY_BLOCKED; fi; export CCACHE_DISABLE=1; echo CCACHE_BYPASS_ENABLED; make -j8 O=/x86_64 BR2_EXTERNAL=/build BR2_DL_DIR=/build/buildroot/dl BR2_CCACHE_DIR=/home/batocera/.buildroot-ccache -C /build/buildroot host-soh-reconfigure; make -j8 O=/x86_64 BR2_EXTERNAL=/build BR2_DL_DIR=/build/buildroot/dl BR2_CCACHE_DIR=/home/batocera/.buildroot-ccache -C /build/buildroot soh-reconfigure'" DOCKER_OPTS=--network=none
```

The host CMake run selected `/usr/bin/gcc` and `/usr/bin/g++`, configured with `SOH_ASSET_GENERATOR_ONLY=ON`, compiled fresh objects, built `GenerateSohOtr`, generated `soh.o2r`, and installed the versioned host artifact. The target CMake run selected Buildroot's x86_64 toolchain, compiled fresh target objects, linked `soh.elf`, built target `soh`, and installed the package-stage runtime. The host-generated archive, its versioned host install, and the target package-stage copy have matching SHA-256 `b19d79165b71cca38dbabaf542791a1a9fc27d2eb54c7d650761da83c258dc1e`. The target package-stage tree remains read only and contains no `ZAPD.out`. Neither package target invokes CPack. These results prove **AC-9** and reconfirm the package-stage portions of **AC-2**, **AC-3**, and **AC-10**.

### Full-image build attempt (2026-09-29)

After AC-9 passed, `make x86_64-build` was run with the warm `output/x86_64` tree and normal local parallelism. The captured retry command was `set -o pipefail; make x86_64-build 2>&1 | tee /tmp/soh-x86_64-build.log`; it exited 2 during Buildroot's package download phase, before root-filesystem or image assembly. Several selected Kodi 21 language archives returned HTTP 404, including `de_de`, `es_es`, `it_it`, `pt_br`, and `sv_se`; for example, `https://sources.buildroot.net/kodi21-resource-language-pt_br/resource.language.pt_br-11.0.104.zip` returned `404 Not Found`. No final image was produced by this run or inspected. This unrelated image dependency failure blocks final-image inspection; first extraction, repeat launch, controller input, graceful exit, final-image metadata, and the runtime write boundary remain unverified.

### Full-image acceptance (2026-10-02)

The warm full-image build completed successfully with the requested PTY capture:

```sh
script -q -e -c 'make x86_64-build' /tmp/soh-x86_64-build-final.log
```

The durable log starts at `2026-10-02 10:28:51-07:00` and ends at `10:51:45-07:00` with `COMMAND_EXIT_CODE="0"`; the tool also reports exit 0. Make completed normally. No output cleaning, targeted SoH rebuild, source changes, or repeat of AC-9 occurred in this acceptance pass. The earlier full-image blockers above are historical and no longer block this pass.

The release artifacts are under `output/x86_64/images/batocera/images/x86_64/`:

| Artifact | Bytes | Verification |
|---|---:|---|
| `batocera-x86_64-44-20261002.img.gz` | 4,600,329,078 | Decompressed successfully; GPT boot and userdata partitions inspected; embedded SquashFS matches the inspected root filesystem |
| `boot.tar.xz` | 4,494,908,868 | Extracted `boot/batocera.update` payload matches the inspected root filesystem |
| `batocera-x86_64-44-20261002.img.gz.md5` | 33 | Matches independently computed image MD5 |
| `batocera-x86_64-44-20261002.img.gz.sha256` | 65 | Matches independently computed image SHA-256 |
| `boot.tar.xz.md5` | 33 | Matches independently computed archive MD5 |
| `boot.tar.xz.sha256` | 65 | Matches independently computed archive SHA-256 |
| `batocera.version` | 35 | `44-dev-f1ae831d8c 2026/10/01 18:01` |

The image SHA-256 is `25eef37c36677509ab90fd3c4f1000efd1eb727dd6d9b7b008bd6498471e85f7`; the boot archive SHA-256 is `1205289930109753413d344c5fa30bd544661db491aa087bf00ef0c47146c1fa`. Aggregate `MD5SUMS`, `SHA256SUMS`, and a version copy are in `output/x86_64/images/batocera/`. This development image intentionally produces no torrent.

The filesystem outputs are `output/x86_64/images/rootfs.squashfs` (3,601,080,320 bytes) and `rufomaculata` (981,209,088 bytes). Supporting outputs include `bzImage`, `initrd`, `initrd.gz`, `uInitrd`, `batocera-boot.conf`, EFI/syslinux loaders, tools, and the assembled `batocera/boot_x86_64/` tree. `/tmp/soh-final-artifact-inventory.json` inventories all 188 files present under the images directory after this pass, including reused intermediates and staged boot files.

The independently extracted SquashFS from the final disk image, the boot archive payload, the staged boot payload, and `rootfs.squashfs` all have SHA-256 `306a251cbd6f89aaa00b16917e6b213c0e4e97d8124db68c90169c5ae704bc0b`. This establishes that the inspected filesystem is the one shipped in both release artifacts.

Final-filesystem inspection proves:

* `/usr/lib/soh/soh.elf` is a stripped ELF64 x86-64 executable and is installed beside `soh.o2r` and `gamecontrollerdb.txt`.
* The final-image `soh.o2r`, the versioned host install, and the previously verified host-generated archive share SHA-256 `b19d79165b71cca38dbabaf542791a1a9fc27d2eb54c7d650761da83c258dc1e` (**AC-2**).
* `gamecontrollerdb.txt` matches the pinned SHA-256 `f857275fe139ddf724ede6500b7dc05af20cddb88eb1136a5a1218b33151c07c`. The extractor subtree contains 24 files and the XML subtree 7,680 files; both file-path sets exactly match the pinned package source. No `ZAPD.out` exists anywhere in the final filesystem (**AC-3**).
* All 206 SoH directories have mode 0555, `soh.elf` has mode 0555, and all 7,730 data files have mode 0444. All 7,937 entries are root:root with zero write bits. The final permissions run through `SOH_ROOTFS_PRE_CMD_HOOKS` under fakeroot. The real TARGET_DIR remains owner-writable for all 7,937 SoH entries, and the temporary SquashFS target tree was removed successfully (**AC-3** and the packaged-permissions portion of **AC-10**).
* `/usr/share/emulationstation/es_systems.cfg` contains exactly one `soh` system, named Ship of Harkinian, with `/userdata/roms/soh`, emulator `soh`, default core `soh`, and exactly `.n64 .v64 .z64`. `/usr/share/batocera/launch/defaults/config.yml` also selects emulator/core `soh`. The final image contains the launcher module, its `soh = batocera_launch.emulators.soh:Soh` entry point, and the ROM-directory initialization metadata (**AC-4**).

These results complete **AC-1 through AC-4** using the earlier source/toolchain evidence plus final-image evidence. **AC-9** remains proven and was not repeated. They do not prove a booted EmulationStation session or SoH behavior. **AC-5 through AC-8**, and the runtime portion of **AC-10**, remain open: first extraction, reuse of either generated archive, controller behavior, graceful hotkey exit, and writable state staying under `SHIP_HOME=/userdata/saves/soh`. Remaining acceptance work is now purely interactive runtime testing. The separate companion-Buildroot reconciliation requirement above still applies before merge readiness.

Detailed local evidence is in `/tmp/soh-acceptance-final-report.md`, `/tmp/soh-final-rootfs-checks.json`, `/tmp/soh-final-rootfs-metadata.txt`, `/tmp/soh-final-rootfs-all-metadata.txt`, `/tmp/soh-final-es_systems.cfg`, `/tmp/soh-final-launch-defaults.yml`, and `/tmp/soh-final-disk-partitions.json`, alongside the durable build log.

## Consequences

**Positive**:

* Host and target artifacts share a pinned source identity.
* Buildroot owns the required source inputs, and configure and compile can run offline.
* The first runtime stays simple, with all writable SoH state in one directory.

**Negative / tradeoffs**:

* Buildroot needs a host CMake build of the Shipwright graph, which may need a larger host dependency set than the target package.
* Pinned upstream CMake downloads need a small adapter and hash maintenance when Shipwright changes.
* The system starts on x86_64 only.

**Neutral**:

* The main repository uses its exact submodule gitlinks. Buildroot fetches them during its source download phase, not during configure or compile.
* User supplied ROM files remain outside the read only runtime tree.

## Follow-up

* [x] Prove that the host CMake graph can build `GenerateSohOtr` with Buildroot host dependencies. The host-native CMake cache and matching installed archive prove this on x86_64.
* [x] Prove that building only target `soh` does not build or run target `ZAPD`. The narrow build produced `ZAPDLib` and `soh`, with no target `ZAPD` executable.
* [x] Confirm the archive readiness rule for multiple accepted ROM files: either generated archive is sufficient for the shared SoH home. Runtime launch behavior remains untested.
* [x] Prove AC-9 with host and target configure/compile running in the Docker wrapper's `--network=none` network namespace; the network canary failed, and fresh host/target builds completed with ccache bypassed.
* [ ] Verify the exact graceful exit action in the SoH runtime and record the `hotkeygen_context` binding that triggers it.
* [ ] Verify the selected SDL_GameControllerDB snapshot works with the shipped SDL controller setup.

## Rationale

Reasoning, alternatives, source audit, and links are in [rationale.md](rationale.md).
