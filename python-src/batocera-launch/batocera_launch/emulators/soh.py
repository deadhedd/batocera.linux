from __future__ import annotations

from pathlib import Path
from typing import Final

from batocera_common.dataclasses import cached_dataclass, cached_property
from batocera_launch import BatoceraException, Command, Emulator, HotkeysContext

_EXECUTABLE: Final = Path('/usr/lib/soh/soh.elf')
_SHIP_HOME: Final = Path('/userdata/saves/soh')


@cached_dataclass
class Soh(Emulator):
    needs_sdl_game_controller_config = True

    @cached_property
    def hotkeygen_context(self) -> HotkeysContext:
        return {
            'name': 'soh',
            'keys': {'exit': ['KEY_LEFTALT', 'KEY_F4']},
        }

    @property
    def execution_path(self) -> Path:
        try:
            _SHIP_HOME.mkdir(parents=True, exist_ok=True)
        except OSError as e:
            raise BatoceraException(f'Could not create the SoH save directory: {_SHIP_HOME}') from e

        return _SHIP_HOME

    async def configure(self) -> Command:
        args: list[str | Path] = [_EXECUTABLE]
        if not (_SHIP_HOME / 'oot.o2r').is_file() and not (_SHIP_HOME / 'oot-mq.o2r').is_file():
            args.append(self.rom.resolve())

        return Command(args, env={'SHIP_HOME': _SHIP_HOME})
