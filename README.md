![Banner](preview/portfolio/hero.png)

# Space 8 (PICO-8)

<p align="center">
    <img src="preview/cart.png" alt="Cartridge Art">
</p>

<p align="center">
    <a href="https://www.lexaloffle.com/bbs/?tid=151575"><img src="https://img.shields.io/badge/Play%20on-Lexaloffle%20BBS-ff004d?style=for-the-badge&logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyMDAiIGhlaWdodD0iMjAwIiB2aWV3Qm94PSIwIDAgNTEyIDUxMiIgZmlsbD0iI2ZmZmZmZiI+PHBhdGggZmlsbD0iI2ZmZmZmZiIgZD0iTTIwNC4yODcgMHYxMDEuODgzbC0xMDIuMTQyLjI2MmwtLjI2MiAxMDIuMTQySDB2MTAzLjQyNmgxMDEuODg5VjQxMC4xMWgxMDIuMzk4VjUxMmgxMDMuNDI2VjQxMC4xMTFINDEwLjExVjMwNy43MTNINTEyVjIwNC4yODdINDEwLjExMVYxMDEuODlIMzA3LjcxM1YwSDIwNC4yODd6bTEuMDI2IDEwMi45MTJoMTAxLjM3NXYxMDIuNGgxMDIuNHYxMDEuMzcybC0xMDIuMTQ1LjI2bC0uMjYgMTAyLjE0NGgtMTAxLjM3di0xMDIuNGgtMTAyLjRWMjA1LjMxM2gxMDIuNHYtMTAyLjR6Ii8+PC9zdmc+" alt="Play on Lexaloffle BBS"></a>
    <a href="https://ianskelskey.itch.io/space-8"><img src="https://img.shields.io/badge/Play%20on-itch.io-fa5c5c?style=for-the-badge&logo=itch.io&logoColor=white" alt="Play on itch.io"></a>
</p>

**Space 8** is a compact arcade survival game for the PICO-8 fantasy console. Pilot a small ship through escalating debris fields, collect credits during each mission, and dock at the Station between rounds to buy upgrades for the next launch.

Click one of the buttons above to play online, or search for "Space 8" in Splore.

Space 8 originally began as a way to prepare for the [PVGD PICOJam 2025](https://pvgd.org/picojam2025/), a Western Massachusetts PICO-8 jam organized by the Pioneer Valley Game Developers.

## What to Expect

- Score-chasing arcade missions where the pressure never stops climbing — the ramp keeps going long after your ship is fully upgraded, so every run eventually ends
- Asteroids, color-coded comets, black holes, and alien gunners
- Credits collected mid-flight and spent at the Station shop
- Persistent upgrades for fire rate, shields, spread, hull, thrusters, and shield shock
- Custom PICO-8 pixel art, music, and sound effects

## How to Play

- Arrow keys: move your ship
- Z/C/N: shoot
- X/V/M: use your shield
- Avoid hazards, grab power-ups, collect credits, and survive long enough to reach the Station

## Screenshots

<img src="preview/screenshots/title.png" alt="Title Screen" width="256" height="256"> <img src="preview/screenshots/difficulty.png" alt="Difficulty Selection" width="256" height="256"> <img src="preview/screenshots/station.png" alt="Station" width="256" height="256"> <img src="preview/screenshots/shop.png" alt="Shop" width="256" height="256"> <img src="preview/screenshots/early_gameplay.png" alt="Early Gameplay" width="256" height="256"> <img src="preview/screenshots/mid_gameplay.png" alt="Mid Gameplay" width="256" height="256"> <img src="preview/screenshots/summary.png" alt="Round Clear" width="256" height="256"> <img src="preview/screenshots/gameover.png" alt="Game Over" width="256" height="256"> <img src="preview/screenshots/highscores.png" alt="High Scores" width="256" height="256"> <img src="preview/screenshots/guide.png" alt="Guide" width="256" height="256">

## Obstacles

| Sprite                                                                                                                      | Name       | Description                                                                                                 |
| --------------------------------------------------------------------------------------------------------------------------- | ---------- | ----------------------------------------------------------------------------------------------------------- |
| ![Medium](preview/entities/asteroid-md.png) ![Large](preview/entities/asteroid-lg.png)                                                                        | Asteroid   | Slow-moving space rock. Takes multiple hits and splits into smaller chunks when destroyed. Chance to drop money. |
| ![Yellow Comet](preview/entities/comet-yellow.png) ![Green Comet](preview/entities/comet-green.png) ![Blue Comet](preview/entities/comet-blue.png) ![Red Comet](preview/entities/comet-red.png) ![Pink Comet](preview/entities/comet-pink.png) | Comet      | Fast movers that arrive from round 3. Takes two hits to destroy, and each colour drops a different power-up — or just dodge them. |
| ![Black Hole](preview/entities/black-hole.gif)                                                                                               | Black Hole | A space anomaly that appears from round 5 and pulls your ship inward. Death on contact — your shield won't save you, so thrust away early. |
| ![Popcorn](preview/entities/popcorn.gif)                                                                                                     | Popcorn    | A little alien gunner that weaves down from round 2, winds up, and spits a shot tracked toward you. Takes two hits to pop and usually drops money. |

## Upgrades

Purchasables available at the Station shop.

| Icon | Name | Description |
| ---- | ---- | ----------- |
| ![Fire Rate](preview/entities/upgrade-fire-rate.png) | Fire Rate | +20% fire rate per level (max 3). |
| ![Shield](preview/entities/upgrade-shield.png) | Shield | Unlocks shield, then strengthens it per level (max 3). |
| ![Spread](preview/entities/upgrade-spread.png) | Phaser Spread | Adds side beams per level (max 2). |
| ![Hull](preview/entities/upgrade-hull.png) | Hull | +1 hull segment per level (max 2). Grants +1 HP when purchased. |
| ![Thrusters](preview/entities/upgrade-thrusters.png) | Thrusters | Higher top speed per level (max 3). |
| ![Shock](preview/entities/upgrade-shock.png) | Shield Shock | Emits a damaging pulse on hit (max 2). Requires Shield. |
| ![Repair](preview/entities/upgrade-repair.png) | Repair Hull | Restores 1 hull, up to current max. Cost scales with round. |

## Power-ups

Dropped by comets during missions. Effects are temporary and reset at the end of each round.

| Icon | Name | Description |
| ---- | ---- | ----------- |
| ![Hull +1](preview/entities/powerup-hull.gif) | Hull | +1 HP if you have room; dropped by green comets. |
| ![Charge](preview/entities/powerup-charge.gif) | Charge | Fully recharges your shield and grants a stretch of free shield time; dropped by blue comets. |
| ![Rapid Fire](preview/entities/powerup-rapid.gif) | Rapid | A ~3 second burst of faster fire; dropped by yellow comets. |
| ![Magnet](preview/entities/powerup-magnet.gif) | Magnet | Pulls nearby loot and pickups toward you; dropped by pink comets. |
| ![Bomb](preview/entities/powerup-bomb.gif) | Bomb | Detonates an expanding shockwave that vaporises every obstacle it sweeps over; dropped (rarely) by red comets. |

## Credits

Coins dropped by destroyed asteroids and enemies. Scoop them up mid-mission to fund upgrades at the Station — they come in three tiers (rarer coins are worth more).

| Coin | Tier | Value |
| ---- | ---- | ----- |
| ![Bronze](preview/entities/coin-bronze.gif) | Bronze | 2 credits (common) |
| ![Silver](preview/entities/coin-silver.gif) | Silver | 4 credits |
| ![Gold](preview/entities/coin-gold.gif) | Gold | 8 credits (rare) |

## Free Assets

Want to make your own shmup? The tilesheet and assets from this game are available for free download on itch.io:

<p align="center">
    <a href="https://ianskelskey.itch.io/space-8-pico-8-tilesheet-free"><img src="https://images-wixmp-ed30a86b8c4ca887773594c2.wixmp.com/f/28bd0b5e-96a8-43df-a260-4b48798361d5/dkzqyhf-135f5c69-c58a-40a5-a8cb-ea34625f9eae.gif?token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1cm46YXBwOjdlMGQxODg5ODIyNjQzNzNhNWYwZDQxNWVhMGQyNmUwIiwiaXNzIjoidXJuOmFwcDo3ZTBkMTg4OTgyMjY0MzczYTVmMGQ0MTVlYTBkMjZlMCIsIm9iaiI6W1t7InBhdGgiOiIvZi8yOGJkMGI1ZS05NmE4LTQzZGYtYTI2MC00YjQ4Nzk4MzYxZDUvZGt6cXloZi0xMzVmNWM2OS1jNThhLTQwYTUtYThjYi1lYTM0NjI1ZjllYWUuZ2lmIn1dXSwiYXVkIjpbInVybjpzZXJ2aWNlOmZpbGUuZG93bmxvYWQiXX0.iFfhD5i080J0Ty0rxyi4M9Cv_qAlNrWSobGGB4G26CM" alt="Space 8 Tilesheet Preview" width="512"></a>
</p>

<p align="center">
    <a href="https://ianskelskey.deviantart.com"><img src="https://img.shields.io/badge/More%20Art%20on-DeviantArt-05cc47?style=for-the-badge&logo=deviantart&logoColor=white" alt="More Art on DeviantArt"></a>
    <a href="https://ianskelskey.itch.io/"><img src="https://img.shields.io/badge/More%20Assets%20on-itch.io-fa5c5c?style=for-the-badge&logo=itch.io&logoColor=white" alt="More Assets on itch.io"></a>
</p>

## Tinkering

This repository is public so people can study a finished PICO-8 project, fork it locally, and experiment with how the carts, entities, UI, art, and audio fit together. It is not an open call for outside development, but it is meant to be useful as an educational reference.

See [CONTRIBUTING.md](CONTRIBUTING.md) for local running, export, cart handoff, and tinkering notes.

## License

A formal project license has not been added yet. Until one is chosen, treat Space 8, its name, shipped carts, source, art, music, sound effects, and documentation as shared for play, study, and personal tinkering only. Please do not redistribute Space 8 or lightly modified builds as your own.

## Hardware

I really wanted to try my game on actual hardware, so I picked up an Anbernic RG40XXH handheld console that supports PICO-8. Super satisfying to see it running on real hardware!

![Space 8 Running on a Anbernic RG40XXH](preview/hardware.png)
