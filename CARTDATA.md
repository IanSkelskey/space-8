# Cartdata Memory Map (`cartdata("sp8")`)

Space_8 uses a single 64-slot persistent cartdata block (`cartdata("sp8")`) to save
progress **and** to shuttle run state between the two carts (`ui.p8` ↔ `space_8.p8`),
since each cart is reloaded fresh and shares no RAM.

- **Slots:** 64 total, indices `0`–`63`.
- **Per slot:** one PICO-8 number, stored as 32-bit **16.16 fixed point** (so fractional
  values persist fine; integer magnitudes up to 32767).
- **Authoritative index map:** [`src/persist.lua`](src/persist.lua) (full, UI cart).
  [`src/persist_game.lua`](src/persist_game.lua) is a trimmed copy for the gameplay cart:
  it drives the shuttle slots `0`–`17` and also writes the round-summary scratch slots
  `33`/`47` (raw `dset`, read back by [`src/ui/summary.lua`](src/ui/summary.lua)). Those
  two scratch slots are the only cartdata not declared as `I_*` constants in `persist.lua`.

## Slot map

| Slot(s) | Constant | Written by | Read by | Meaning |
|--------:|----------|------------|---------|---------|
| `0`  | `I_UI_STATE`      | both | UI boot | Which UI screen to open on load: `0`=menu, `1`=station, `2`=gameover. **Cleared to `0` on every UI boot** ([`boot.lua`](src/ui/boot.lua) `dset(0,0)`), so it fires once per handoff. |
| `1`  | `I_DF`            | both | both | Difficulty: `1`=easy, `2`=normal, `3`=veteran. |
| `2`  | `I_ROUND`         | both | both | `round_number` (internal, difficulty-scaled start round). |
| `3`  | `I_MONEY`         | both | both | `money_total` (current funds). |
| `4`  | `I_LAST_PAY`      | both | both | Base payout from the last completed mission. |
| `5`  | `I_LAST_BONUS`    | both | both | Credits (shards) collected during the last run. |
| `6`  | `I_VR`            | both | both | Visible round counter (always starts at `1`). |
| `7`  | `I_FIRE`          | both | both | `ship.fire_rate_level`. |
| `8`  | `I_SHIELD`        | both | both | **Packed**: `shield_level` (low, `%8`) + `shield_pulse_level*8`. |
| `9`  | `I_SPREAD`        | both | both | `ship.spread_level`. |
| `10` | `I_HULL_L`        | both | both | `ship.hull_level`. |
| `11` | `I_THRUST`        | both | both | `ship.thruster_level`. |
| `12` | `I_SHIELD_UNL`    | both | both | Shield unlocked (`0`/`1`). |
| `13` | `I_HULL`          | both | both | Current hull points. |
| `14` | `I_TS`            | both | both | Total score, low part (`0`–`999`). |
| `15` | `I_TSH`           | both | both | Total score, thousands. |
| `16` | `I_PAYOUT_READY`  | both | both | `last_payout_ready` (`0`/`1`) — station shows the payout panel. |
| `17` | `I_START_FLAG`    | both | gameplay boot | `1` = gameplay cart should immediately start a mission. |
| `18` | `I_LAST_RUN_LO`   | **gameplay** (`ship_kill`, raw `dset(18)`) | UI | Last run final score, low part. |
| `19` | `I_LAST_RUN_HI`   | **gameplay** (`ship_kill`, raw `dset(19)`) | UI | Last run final score, thousands. |
| `20` | `I_HS1_COUNT`     | UI only | UI only | Easy highscore: entry count. |
| `21`–`32` | `I_HS1_BASE` | UI only | UI only | Easy: 4 entries × 3 slots each → `(hi, lo, name_code)`. |
| `33` | (`last_kills`) | **gameplay** (`persist_game` raw `dset(33)`) | UI summary | Round-clear obstacle-kill tally (`obk`), shown on the round-summary screen. Reuses the easy-highscore block's stride-padding slot (the HS logic never touches it). |
| `34` | `I_HS2_COUNT`     | UI only | UI only | Normal highscore: entry count. |
| `35`–`46` | `I_HS2_BASE` | UI only | UI only | Normal: 4 entries × `(hi, lo, name_code)`. |
| `47` | (`last_score`) | **gameplay** (`persist_game` raw `dset(47)`) | UI summary | Round-clear score (`scoreh*1000 + score`) for the round-summary screen. Reuses the normal-highscore block's stride-padding slot. |
| `48` | `I_HS3_COUNT`     | UI only | UI only | Veteran highscore: entry count. |
| `49`–`60` | `I_HS3_BASE` | UI only | UI only | Veteran: 4 entries × `(hi, lo, name_code)`. |
| `61` | — | — | — | **spare**. |
| `62` | `I_LIFE_LO`       | UI only | UI only | Lifetime money, low part (`0`–`999`). |
| `63` | `I_LIFE_HI`       | UI only | UI only | Lifetime money, thousands. |

"Both" = written/read by both carts through their respective persist files
(`persist_save_for_game` / `persist_save_from_game` / the shared `lg()` loader).

## Highscore entry encoding

Each highscore table (easy/normal/veteran) stores up to `MAX_HS=4` entries, 3 slots each
(see [`src/ui/highscores.lua`](src/ui/highscores.lua)):

- `hi` — score thousands.
- `lo` — score low part (`0`–`999`). Full score = `hi*1000 + lo`.
- `name_code` — 3 initials packed into one number: `a*676 + b*26 + c`, where each letter
  is `0`–`25` (base-26). Decoded back via `dec_name`.

Layout per block: `[count][e1.hi e1.lo e1.nc][e2…][e3…][e4…]` = 1 + 4×3 = **13 slots used**,
with a **14-slot stride** between block starts (`20`, `34`, `48`), leaving one padding slot
each (`33`, `47`, `61`). The first two of those are reused as round-summary scratch (see the
slot map), so only `61` is genuinely free.

## Cross-cart ownership notes

- **Shuttle state (`0`–`17`)** is the contract for launching/returning a mission. The
  gameplay cart writes it on exit (`persist_save_from_game`), the UI writes it before
  launch (`persist_save_for_game`); both load it via `lg()`.
- **Last-run score (`18`–`19`)** is written directly by the gameplay cart inside
  `ship_kill` (raw `dset`), because by the time game.lua's death block runs, `game_state`
  is already `"dying"`. The UI reads it for gameover + highscore qualification.
- **Round-summary scratch (`33`, `47`)** carries the just-cleared round's obstacle-kill
  tally and score from the gameplay cart to the UI's round-summary screen. The gameplay
  cart writes them raw on exit (`persist_save_from_game`); [`summary.lua`](src/ui/summary.lua)
  reads them. They live in highscore-block padding slots that the HS code never writes, so
  there's no collision.
- **The highscore tables (blocks at `20`/`34`/`48`) and lifetime money (`62`–`63`)** are
  owned entirely by the UI cart — except for the `33`/`47` padding slots noted above, which
  the gameplay cart borrows. As of the 2026-06-07 refactor, the gameplay cart no longer
  touches lifetime money;
  the UI folds each run's earnings in at the handoff
  (`add_life(st==1 and last_pay+last_bonus or last_bonus)` in `persist_load_ui_state`).

## Free space

Genuinely free: **`61`** only. The other two highscore-padding slots (`33`, `47`) are now
occupied by round-summary scratch (see slot map), so they're no longer available. With a
single spare slot there is nowhere near contiguous room for a large new block — in
particular **not enough to persist the ~10 difficulty-scaling floats** that `sl()`
([`src/levels.lua`](src/levels.lua)) computes, which is why that function can't be offloaded
from the gameplay cart to the UI cart without first reclaiming highscore space (e.g. packing
`hi`+`lo` into one slot, or dropping to 3 highscore entries per difficulty).
