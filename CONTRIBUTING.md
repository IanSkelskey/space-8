# Tinkering with Space 8

This file is named `CONTRIBUTING.md` for GitHub convention, but Space 8 is not looking for outside feature development. The repo is public so people can read the source, learn from the structure, fork it locally, and experiment with their own changes.

If you use Space 8 as a reference or starting point, please make the result clearly distinct, credit the original project, and do not present a modified build as the official game or as your own original release.

## Project Layout

- `ui.p8`: menus, difficulty selection, station, shop, high scores, help, and game over screens
- `space_8.p8`: gameplay cart with the action loop and in-mission entities
- `src/ui/`: UI-side Lua modules used by the menu/station cart
- `src/entities/`: gameplay entity logic for the ship, asteroids, comets, black holes, popcorn enemies, and bombs
- `src/util/sound.lua`: shared sound helpers and playback routing
- `src/starfield.lua`, `src/particles.lua`, `src/levels.lua`: reusable visual and gameplay support modules
- `CARTDATA.md`: the slot-by-slot memory map shared by the two carts
- `preview/`: screenshots, entity previews, cartridge art, and README images

## Running the Game

1. Open PICO-8.
2. Load the UI cart first:

   ```p8
   load ui.p8
   run
   ```

3. Choose a difficulty and launch a mission. The UI cart loads `space_8.p8` automatically and passes run state through `cartdata`.
4. When a mission ends or the player dies, the gameplay cart saves back to `cartdata` and returns to `ui.p8`.

## Exporting

The project uses a two-cart setup, so export from the UI cart and include the gameplay cart in the bundle. In PICO-8:

```p8
export space_8.html ui.p8
```

PICO-8 will include the gameplay cart loaded by the UI cart.

## Cart Handoff

Both carts share a single 64-slot `cartdata("sp8")` block to save progress and shuttle run state across the handoff. That includes difficulty, round, money, payout values, score totals, upgrade levels, shield unlock, current hull, mission flags, per-difficulty high scores, and lifetime money.

The full memory map is documented in [CARTDATA.md](CARTDATA.md).

## Tinkering Ideas

- Change spawn pacing, round pressure, or scoring values in `src/levels.lua`.
- Study movement, collision, and draw behavior in `src/entities/`.
- Adjust the starfield in `src/starfield.lua` or particle feedback in `src/particles.lua`.
- Explore the Station, shop, help, and high score screens in `src/ui/`.
- Inspect sound routing in `src/util/sound.lua` before adding or moving effects.

## Before Sharing a Fork

- Rename the project and make the game clearly distinct from Space 8.
- Do not use the Space 8 name, logo, cartridge label, or store presentation in a way that implies an official release.
- Credit Space 8 and link back to the original project.
- Replace or substantially rework content if you are publishing a derivative game, especially branding, title art, copy, progression, and presentation.
- Respect the project license once a formal license is added.

## Contribution Scope

Personal forks, experiments, and study notes are welcome. I am not actively seeking feature PRs, design changes, balance passes, or new content for the main game.

Small documentation fixes or clear bug reports are fine, but the main value of this repo is as a playable game and educational PICO-8 reference.
