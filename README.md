![Banner](preview/banner.gif)

# Space 8 (PICO-8)

<p align="center">
    <img src="preview/cart-preview.png" alt="Cartridge Art" width="160">
</p>

<p align="center">
    <a href="https://www.lexaloffle.com/bbs/?tid=151575"><img src="https://img.shields.io/badge/Play%20on-Lexaloffle%20BBS-ff004d?style=for-the-badge&logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyMDAiIGhlaWdodD0iMjAwIiB2aWV3Qm94PSIwIDAgNTEyIDUxMiIgZmlsbD0iI2ZmZmZmZiI+PHBhdGggZmlsbD0iI2ZmZmZmZiIgZD0iTTIwNC4yODcgMHYxMDEuODgzbC0xMDIuMTQyLjI2MmwtLjI2MiAxMDIuMTQySDB2MTAzLjQyNmgxMDEuODg5VjQxMC4xMWgxMDIuMzk4VjUxMmgxMDMuNDI2VjQxMC4xMTFINDEwLjExVjMwNy43MTNINTEyVjIwNC4yODdINDEwLjExMVYxMDEuODlIMzA3LjcxM1YwSDIwNC4yODd6bTEuMDI2IDEwMi45MTJoMTAxLjM3NXYxMDIuNGgxMDIuNHYxMDEuMzcybC0xMDIuMTQ1LjI2bC0uMjYgMTAyLjE0NGgtMTAxLjM3di0xMDIuNGgtMTAyLjRWMjA1LjMxM2gxMDIuNHYtMTAyLjR6Ii8+PC9zdmc+" alt="Play on Lexaloffle BBS"></a>
    <a href="https://ianskelskey.itch.io/space-8"><img src="https://img.shields.io/badge/Play%20on-itch.io-fa5c5c?style=for-the-badge&logo=itch.io&logoColor=white" alt="Play on itch.io"></a>
</p>

**Space 8** is a retro-inspired arcade game for the PICO-8 fantasy console. Blast asteroids, dodge comets, and survive as long as you can! Click one of the buttons above to play it online, or you can search for "Space 8" in Splore.



## Features
- Classic arcade-style gameplay
- Power-ups, scores, and upgrades
- Custom music and sound effects
- Optimized for web export and PICO-8

## How to Play
- Arrow keys: Move your ship
- Z/C/N: Shoot
- X/V/M: Use your shield
- Avoid obstacles and collect power-ups to survive longer

## Screenshots

<img src="preview/screenshots/title.png" alt="Title Screen" width="256" height="256"> <img src="preview/screenshots/shop.png" alt="Shop Page 1" width="256" height="256"> <img src="preview/screenshots/shop_2.png" alt="Shop Page 2" width="256" height="256"> <img src="preview/screenshots/highscores.png" alt="High Scores" width="256" height="256"> <img src="preview/screenshots/difficulty.png" alt="Difficulty Selection" width="256" height="256"> <img src="preview/screenshots/early_gameplay.png" alt="Early Gameplay" width="256" height="256"> <img src="preview/screenshots/mid_gameplay.png" alt="Mid Gameplay" width="256" height="256"> <img src="preview/screenshots/help_1.png" alt="Help Screen 1" width="256" height="256"> <img src="preview/screenshots/station.png" alt="Station" width="256" height="256"> <img src="preview/screenshots/gameover.png" alt="Game Over" width="256" height="256">

## Obstacles

| Sprite                                                                                                                      | Name       | Description                                                                                                 |
| --------------------------------------------------------------------------------------------------------------------------- | ---------- | ----------------------------------------------------------------------------------------------------------- |
| ![Medium](preview/entities/asteroid-md.png) ![Large](preview/entities/asteroid-lg.png)                                                                        | Asteroid   | Large space rock that moves slowly. Can be destroyed with multiple hits. Breaks into chunks when destroyed. Chance to drop money. |
| ![Orange Comet](preview/entities/comet-orange.png) ![Green Comet](preview/entities/comet-green.png) ![Blue Comet](preview/entities/comet-blue.png) ![Red Comet](preview/entities/comet-red.png) ![Pink Comet](preview/entities/comet-pink.png) | Comet      | Fast-moving space debris that cannot be destroyed. Must be avoided to prevent damage. Chance to drop powerups                       |
| ![Black Hole](preview/entities/black-hole.gif)                                                                                               | Black Hole | A dangerous space anomaly that pulls the player in. Avoid getting too close or you'll be sucked in!         |

## Upgrades

Purchasables available at the Station shop.

| Icon | Name | Description |
| ---- | ---- | ----------- |
| ![Fire Rate](preview/entities/upgrade-fire-rate.png) | Fire Rate | +20% fire rate per level (max 3). |
| ![Shield](preview/entities/upgrade-shield.png) | Shield | Unlocks shield, then strengthens it per level (max 3). |
| ![Spread](preview/entities/upgrade-spread.png) | Phaser Spread | Adds side beams per level (max 2). |
| ![Hull](preview/entities/upgrade-hull.png) | Hull | +1 hull segment per level (max 2). Grants +1 HP when purchased. |
| ![Thrusters](preview/entities/upgrade-thrusters.png) | Thrusters | Faster acceleration per level (max 3). |
| ![Shock](preview/entities/upgrade-shock.png) | Shield Shock | Emits a damaging pulse on hit (max 2). Requires Shield. |
| ![Repair](preview/entities/upgrade-repair.png) | Repair Hull | Restores 1 hull, up to current max. Cost scales with round. |

## Power-ups

Dropped by comets during missions. Temporary or immediate effects.

| Icon | Name | Description |
| ---- | ---- | ----------- |
| ![Hull +1](preview/entities/upgrade-hull.png) | Hull | +1 HP if you have room; dropped from green comets. |
| ![Shield](preview/entities/upgrade-shield.png) | Shield Refill | Fully recharges shield; gives free shield time; dropped from blue comets. |
| ![Rapid Fire](preview/entities/upgrade-fire-rate.png) | Rapid | Temporary burst of faster fire; dropped from yellow comets. |
| ![Magnet](preview/entities/powerup-magnet.png) | Magnet | Attracts nearby loot and pickups; dropped by pink comets. |

## Free Assets

Want to make your own shmup? The tilesheet and assets from this game are available for free download on itch.io:

<p align="center">
    <a href="https://ianskelskey.itch.io/space-8-pico-8-tilesheet-free"><img src="https://images-wixmp-ed30a86b8c4ca887773594c2.wixmp.com/f/28bd0b5e-96a8-43df-a260-4b48798361d5/dkzqyhf-135f5c69-c58a-40a5-a8cb-ea34625f9eae.gif?token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1cm46YXBwOjdlMGQxODg5ODIyNjQzNzNhNWYwZDQxNWVhMGQyNmUwIiwiaXNzIjoidXJuOmFwcDo3ZTBkMTg4OTgyMjY0MzczYTVmMGQ0MTVlYTBkMjZlMCIsIm9iaiI6W1t7InBhdGgiOiIvZi8yOGJkMGI1ZS05NmE4LTQzZGYtYTI2MC00YjQ4Nzk4MzYxZDUvZGt6cXloZi0xMzVmNWM2OS1jNThhLTQwYTUtYThjYi1lYTM0NjI1ZjllYWUuZ2lmIn1dXSwiYXVkIjpbInVybjpzZXJ2aWNlOmZpbGUuZG93bmxvYWQiXX0.iFfhD5i080J0Ty0rxyi4M9Cv_qAlNrWSobGGB4G26CM" alt="Space 8 Tilesheet Preview" width="512"></a>
</p>

<p align="center">
    <a href="https://ianskelskey.deviantart.com"><img src="https://img.shields.io/badge/More%20Art%20on-DeviantArt-05cc47?style=for-the-badge&logo=deviantart&logoColor=white" alt="More Art on DeviantArt"></a>
    <a href="https://ianskelskey.itch.io/"><img src="https://img.shields.io/badge/More%20Assets%20on-itch.io-fa5c5c?style=for-the-badge&logo=itch.io&logoColor=white" alt="More Assets on itch.io"></a>
</p>

## Development
- All source code is in Lua, designed for PICO-8
- Music and sound created with PICO-8 tools
- Web export available in the `build/` folder

## Running the Game
1. Open PICO-8
2. This project now uses a multi-cart setup:
    - `ui.p8` : menus, station, shop, game over
    - `space_8.p8` : gameplay (action loop + entities)
3. Launch the UI cart first: `load ui.p8` then `run`
4. Selecting a difficulty / launch mission loads `space_8.p8` automatically (state passed via `cartdata`)
5. When a mission ends or you die, the gameplay cart saves back to `cartdata` and loads `ui.p8` to show station or game over
6. To export for web you must export both carts (PICO-8 will bundle dependencies if you chain from the UI cart). Example:
    - `export space_8.html ui.p8` (PICO-8 will include the gameplay cart it loads)

### Persisted Values Between Carts
The following values are serialized with `dset/dget` (indices documented in `src/persist.lua`): difficulty, round, visible round, money, last payout + bonus, score totals (ts,tsh), upgrade levels (fire, shield, spread, hull, thruster), shield unlocked, current hull, payout-ready flag, and a start flag instructing gameplay cart to begin a mission immediately.

## Hardware

I really wanted to try my game on actual hardware, so I picked up an Anbernic RG40XXH handheld console that supports PICO-8. Super satisfying to see it running on real hardware!

![Space 8 Running on a Anbernic RG40XXH](preview/hardware.png)