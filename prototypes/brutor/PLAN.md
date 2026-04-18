# Refactoring Plan

Three refactors worth doing before adding more upgrades.

## 1. Button abstraction

Each button (`REROLL`, `INSTANT`, `MAGIC`, `REPAIR`, `REINFORCE`, `BACK`) currently
repeats the same triple:

- layout enums on `GameState` (`*_X`, `*_Y`, `*_W`, `*_H`)
- `hitTest` branch in `handleClick`
- `drawButtonRect` call in `drawDice` / `drawUpgradeScreen`

Adding one upgrade = editing three places. A `Button { rect, label, enabled }`
struct with `draw()` + `clicked()` collapses a new upgrade to a single
declaration.

## 2. Split `game.d` (currently 1196 lines)

Peel rendering off `GameState` into a `render.d` module:

- `draw*` methods
- `drawPips`, `drawButtonRect`, `centerTextInRect`
- coordinate helpers (`cellSizePx`, `virtualScale`, `viewportOffset`,
  `windowToVirtual`, `virtualToConsole`, `consoleToVirtual`)

`GameState` should stay focused on state + rules. UI layout constants and
drawing don't need to live on it.

## 3. P1/P2 label duplication

The active/inactive branches in `drawText` only differ in box width and label
text. One helper `drawPlayerLabel(con, col, active, label)` collapses ~30 lines
to ~8.

## Order

Start with **#1** — it compounds as upgrades grow. #2 and #3 are nice-to-haves
that can follow.
