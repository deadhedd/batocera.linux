# Ship of Harkinian runtime acceptance — 2026-10-02

**Result: blocked before runtime testing.** No runtime criterion passed or failed in this attempt. The spec and scope acceptance status remains unchanged.

Requested image: `output/x86_64/images/batocera/images/x86_64/batocera-x86_64-44-20261002.img.gz`. The file is present. No rebuild, boot, ROM launch, save-directory cleanup, or runtime modification was performed.

## Environment evidence

The available shell is in `/home/deadhedd/src/batocera.linux` on WSL2. `uname -a` reported:

```text
Linux DESKTOP-1JVK0DL 6.18.33.2-microsoft-standard-WSL2 #1 SMP PREEMPT_DYNAMIC Thu Jun 18 21:54:43 UTC 2026 x86_64 x86_64 x86_64 GNU/Linux
```

`/userdata`, `/usr/lib/soh`, `/dev/input`, and `/dev/kvm` are absent. `command -v qemu-system-x86_64` returned no executable. No SoH, EmulationStation, or QEMU process was found by `ps -eo comm | rg 'qemu|soh|emulationstation'`. `/usr/bin/ssh` is available, but no target host or access details were supplied. The user's `$test` skill was not found among the available skills or local skill files.

These observations describe the build host only; they provide no evidence about behavior of the booted image. Access details for a booted Batocera machine, a supported ROM there, and a real-controller operator were requested.

## Runtime results

| Check | Result | Acceptance criterion |
|---|---|---|
| ROM format | Not selected or observed | — |
| Clean first launch from EmulationStation, absolute ROM argv, extraction, usable game | Not run | AC-5 |
| Clean exit and relaunch, archive detection, no ROM argv or repeated extraction | Not run | AC-6 |
| Real-controller SDL mapping and menu/gameplay input | Not run | AC-7 |
| Real-controller hotkey + exit, Alt+F4, graceful return to EmulationStation | Not run | AC-8 |
| Live SHIP_HOME, generated state location, unchanged/protected packaged runtime | Not run | Runtime portion of AC-10 |

No runtime defect was observed, and there are no SoH runtime logs or state from this attempt to preserve. Existing build and static-inspection evidence was not repeated or altered. Previously proven AC-1 through AC-4, AC-9, and the packaged-permissions portion of AC-10 retain their recorded status. No additional acceptance criteria are proven.

The integration is not ready for final acceptance review: interactive runtime evidence is still required. The spec's separate companion-Buildroot reconciliation requirement also remains unchanged.
