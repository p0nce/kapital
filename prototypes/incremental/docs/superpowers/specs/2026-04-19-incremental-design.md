# Incremental — Design v1

**Date**: 2026-04-19
**Stack**: Love2D (Lua)
**Reference**: Gnorp Apologue (worker assignment, 2D physics, side-scrolling world)
**Language**: docs and in-game UI in English

---

## 1. Concept

A pixel-art "worker assignment" incremental. The player starts with **zero workers** and does everything by hand at the mouse: clicking a tree chops wood, clicking a rock mines stone. As they accumulate Points, they buy **dormitory floors** that produce workers (+2 per floor). They **assign these workers** to buildings via a popup menu, which automates the corresponding actions.

The end goal of the production chain is to feed **Tiles** to a **Minesweeper grid** that the player must solve themselves (at least initially). Solving a Minesweeper grid yields **SP** (Special Points) and **Bombs**, from which **Metal** is later extracted to fund major upgrades.

Aesthetics: **Chroma Noir 8x8** by VEXED (already in `Tilesets/`). Dense monochrome pixel art, with a documented UI tileset (frames, icons).

---

## 2. Gameplay loop

### Clicker phase (early game)

```
click Tree  → +1 Wood + 1 Point   (Wood goes into log pile)
click Rock  → +1 Stone + 1 Point  (Stone goes into stone pile)
```

The piles have a finite capacity. When full, the action no longer yields material (but may still yield points — see §11 open questions).

### Automation phase (mid-game)

The player:
1. Buys the first dormitory floor → 2 idle workers
2. Assigns 1 worker to the Tree (= Lumberjack) → automatic chopping
3. Assigns 1 worker to the Rock (= Miner) → automatic mining
4. Builds the Compactor, Assembler, Loading Dock, Play Zone
5. Hires the corresponding haulers and operators

Each new building costs **Wood + Points**. Construction instant but the building appear in an 5s animation before being active (MVP: alpha-blending).

### Production phase (mid-late)

Full flow:

```
Tree ──[Lumberjack]──▶ log pile ──▶ Lumberyard (upgradeable cap)
                                          │
                                          └──▶ construction / upgrades

Rock ──[Miner]──▶ stone pile ──[Compactor Hauler]──▶ Compactor
                                                          │
                                                    Stone Blocks
                                                          │
                                                  [Assembler Hauler]
                                                          ▼
                                          Assembler (4 Blocks → 1 Tile)
                                                          │
                                                        Tiles
                                                          │
                                                  [Truck Driver]
                                                          ▼
                                                     Play Zone
                                                          │
                                                  [Crane Operator] places
                                                          ▼
                                          Minesweeper ──[player]──▶ SP + Bombs

Bombs ──[Metal Extractor, post-MVP]──▶ Metal ──▶ major upgrades
```

### End-game phase (post-MVP)

The player can **automate the Minesweeper itself** (a dedicated worker, or an auto-solver upgrade), turning the game fully idle. The Minesweeper grid with upgrades over time (2x2 → 3x2 → 3x3...), increasing yield and difficulty.

---

## 3. World layout

- **World is mostly 1D horizontal**, with some vertical scroll (to see the upper floors of the dormitory).
- **Camera**: arrow keys to scroll horizontally, edge-scroll when the mouse hugs a window edge. Mouse wheel zooms in/out.
- **Buildings have a fixed order** (the player does not choose their position).

### Building order, left to right

```
[Lumberyard] [log pile] 🌳 [stone pile] 🪨 [Dormitory] [Compactor] [Assembler] [Loading Dock] [Play Zone]
   building     adj.    Tree    adj.     Rock    multi-floor                                   (crane + Minesweeper)
   (unlock)    (start)  (start) (start)  (start)
```

- **Adjacent piles** (log pile, stone pile): no menu, purely visual indicator of local stock pending transport.
- **Lumberyard (building)**: has a menu, upgradeable capacity. Not present at start.
- **Dormitory**: grows vertically as floors are added.

### State at game start

Present: `log pile | Tree | stone pile | Rock`. Everything else is locked / unbuilt. The empty area to the right hints that more is to come.

---

## 4. Buildings — reference

| # | Building | Associated job | Built with | Menu |
|---|---|---|---|---|
| 1 | Lumberyard | (none, capacity only) | Wood + Points | capacity upgrades |
| 2 | Log pile | — | (free, exists at start) | (no menu) |
| 3 | Tree | Lumberjack | (exists at start) | hire, upgrades |
| 4 | Stone pile | — | (free, exists at start) | (no menu) |
| 5 | Rock | Miner | (exists at start) | hire, upgrades |
| 6 | Dormitory | (none, houses idle workers) | Wood + Points (per floor, exp.) | buy floor, view population |
| 7 | Compactor | Compactor Hauler (carries Stones from pile) | Wood + Points | hire, upgrades |
| 8 | Assembler | Assembler Hauler (carries Blocks from Compactor) | Wood + Points | hire, upgrades |
| 9 | Loading Dock | Truck Driver | Wood + Points | hire, upgrades |
| 10 | Play Zone | Crane Operator | Wood + Points | hire, upgrades, **Minesweeper** |

### Building menu (popup)

```
┌──────────────────────────┐
│ Compactor             [x]│
├──────────────────────────┤
│ ▾ Staff                  │
│   Compactor Hauler ◀ 2 ▶ │  ← assign / unassign
│                          │
│ ▾ Upgrades               │
│   Processing speed       │
│     Lvl 1 → 2 : 50 pts   │
│   Buffer capacity        │
│     Lvl 0 → 1 : 30 wood  │
└──────────────────────────┘
```

The `◀ ▶` arrows draw from / return to the dormitory's idle pool. If no idle worker is available, the `▶` arrow is greyed out.
Note that we should see workers moving from a building door to another, and carrying stuff if it's their job.
---

## 5. Resources

| Resource | Source | Used for | Initial cap |
|---|---|---|---|
| **Points** | tap (click or worker) on Tree/Rock | Dormitory (exp.), construction, upgrades | unlimited |
| **Wood** | Tree | building construction, quantitative upgrades | log pile cap (~10), then upgradeable Lumberyard cap |
| **Stones** | Rock | Compactor input | stone pile cap (~10) |
| **Stone Blocks** | Compactor (1 Stone → 1 Block, or some ratio TBD) | Assembler input | Compactor buffer |
| **Tiles** | Assembler (4 Blocks → 1 Tile) | Minesweeper input (via Truck) | Assembler buffer |
| **SP** (Special Points) | Minesweeper win | premium upgrades | unlimited |
| **Bombs** | Minesweeper (always, qty = bombs revealed) | Metal extraction (post-MVP) | unlimited |
| **Metal** | Bomb extraction (post-MVP) | major upgrades | unlimited |

---

## 6. Workers

- **Source**: 0 at start. Each Dormitory floor purchase adds 2.
- **Floor cost**: exponential in Points. Formula: `cost(n) = base * mult^n` (placeholder `base=10, mult=1.5`, to balance).
- **Single pool**: all workers live at the Dormitory. Idle = at rest in the Dormitory. Assigned = walking to a building, or working there.
- **Movement**: horizontal only, uniform speed (globally upgradeable later).
- **Visualization**: Hero sprite from the tileset, possibly with a tint or accessory per job (sprite mapping TBD with user).

### Jobs and names

A worker is a "Gubo", a small industriuous creature like lemmings or gnorps.


| Building | Job (placeholder) | Fun name idea |
|---|---|---|
| Tree | Lumberjack | Wood Gubo |
| Rock | Miner | Mine Gubo |
| Dormitory | Idle | Idle Gubo (= unassigned) |
| Compactor | Compactor | Compactor Gubo |
| Assembler | Assembler | Assembler Gubo |
| Loading Dock | Truck Driver | Truck Gubo |
| Play Zone | Crane operator | Crane Gubo |

---

## 7. Minesweeper

### MVP: black box

When a Tile arrives at the Play Zone, it is consumed by the Minesweeper (the crane places it). 
Tile are accumulated bottom to top, left to right.
When N Tiles have accumulated (placeholder formula), the Minesweeper "self-resolves"(MVP) after a few seconds and emits:
- **SP gained**: `1` (MVP constant)
- **Bombs gained**: `2` (MVP constant, independent of grid size)

**SP** is a resource that isn't harvested, but Bombs drop on the floor in a "Bomb zone" (left to play zone).

No real interactive grid in MVP for now.

### Post-MVP

- Real interactive grid (real Minesweeper logic).
- Grid starts **2x2**, grows with upgrades (3x3, 4x4, ...).
- Win = flag all bombs without clicking one → +1 SP + Bombs (= all bombs on the grid).
- Loss = Bombs only (no SP), Minesweeper resets.
- Auto-solver (worker or upgrade): automates the Minesweeper for full idle late-game.
- Research center. Other play grid with other games.

---

## 8. UI

### Permanent HUD (top)

Display: `Points | Wood | SP | Metal`

Plus FPS in debug mode.

### Popup menus

One per building (cf. §4). Opened by clicking a building. Closed by `[x]`, `Esc`, or clicking outside.

### Mouse interactions

- **Left-click on building** → opens menu
- **Left-click on resource source** (Tree, Rock) → manual action (equivalent to one worker tick)
- **Left-click on resource in transit** → "nudge" (speeds up / redirects, exact effect TBD)
- **Mouse drag at screen edge** → camera pan
- **Mouse wheel** → zoom in/out
- **Arrow keys** → camera pan
- **Esc** → close menu / quit

### Zoom

Discrete levels: e.g. `1x, 2x, 3x, 4x, 6x` (8px sprites → 8 / 16 / 24 / 32 / 48 px on-screen). Filter `nearest` (no blur).
Buildings are made with several 8x8 tiles, for example 4x3 of such 8x8 tiles.

---

## 9. Love2D architecture

Modules planned (each = a `src/<name>.lua` file):

```
main.lua        — love.load/update/draw/mousepressed/keypressed, dispatch
conf.lua        — window, title, vsync
src/
  state.lua     — global game state (singleton table)
  world.lua     — buildings, position, fixed order, status (built/locked)
  resources.lua — resource types, helpers (add, spend, can_afford)
  workers.lua   — worker pool, assignment, movement
  jobs.lua      — job registry: action per tick, sprite, etc.
  buildings/
    tree.lua, rock.lua, dormitory.lua, compactor.lua, ...
                — one module per building (action, menu, upgrades)
  ui/
    menu.lua    — generic popup, closable, anchored to building
    hud.lua     — top resource bar
    arrows.lua  — ◀ N ▶ assignment widget
  camera.lua    — scroll, zoom, world ↔ screen transform
  sprites.lua   — Chroma Noir atlas loading, name-based access
  input.lua     — mouse / keyboard routing (separated for testability)
  minesweeper.lua — MVP stub (timer + payout) and later, the grid
```

### Main loop

```lua
function love.update(dt)
  state.time = state.time + dt
  workers.update(dt)         -- movement, action on arrival
  buildings.update(dt)       -- production, consumption, queues
  camera.update(dt)          -- auto pan if edge-scrolling
  ui.update(dt)
end

function love.draw()
  camera.attach()
    world.draw()             -- ground, buildings, in-transit resources
    workers.draw()
  camera.detach()
  ui.draw()                  -- HUD + popup menus in screen coords
end
```

### Data model (global state)

```lua
state = {
  time = 0,
  resources = { points=0, wood=0, stones=0, blocks=0, tiles=0, sp=0, bombs=0 },
  buildings = {
    tree = { built=true, level=1, workers={} },
    rock = { built=true, level=1, workers={} },
    log_pile = { built=true, contents=0, cap=10 },
    stone_pile = { built=true, contents=0, cap=10 },
    dormitory = { built=false, floors=0, workers_idle={} },
    -- …
  },
  workers = { -- worker list
    { id=1, x=120, target=nil, job=nil, anim=… },
    -- …
  },
  in_transit = { -- resources currently being carried across the screen
    -- …
  },
  camera = { x=0, y=0, zoom=2 },
  ui = { open_menu=nil },
}
```

### Save/load

**Out of MVP scope.** When added: `love.filesystem.write` + `serpent.dump(state)`. State is natively serializable (tables + numbers + strings).

---

## 10. MVP scope

### Included

- Love2D window with scrollable + zoomable camera
- Chroma Noir sprites integrated (initial mapping done with user)
- Buildings present at start: Tree, Rock, their adjacent piles
- Manual click action on Tree / Rock (gain Points + material)
- Dormitory purchase (first floor, then exponentially-priced ones)
- Visualized idle worker pool at Dormitory
- Construction of the next buildings (Compactor, Assembler, Loading Dock, Play Zone) at Wood + Points cost
- Construction of the Lumberyard (upgradeable capacity)
- Popup menus per building (hire + 1-2 upgrades per building)
- Hire and unassign
- Horizontal worker movement + visible resource transport
- Minesweeper stub: black-box timer → SP + Bombs per placeholder formula
- Permanent HUD with all counters

### Stubs / placeholders

- Minesweeper: no interactive grid, just timer and fixed payout
- Truck: automatic with a Truck Driver, no mini-game (was never planned)
- Metal: no extraction, Bombs accumulate without use
- Sound, physics particles (Box2D), visual polish
- Save / load
- Numerical balancing (placeholder values to iterate)

### Out of MVP (post-MVP roadmap)

1. **Real Minesweeper** (interactive grid)
2. **Metal extraction** + major upgrades
3. **Save / load** (serpent + love.filesystem)
4. **Auto-solver Minesweeper** (full idle endgame)
5. **Sound + music**
6. **Physics particles** (Box2D for falling stones, etc.)
7. **Balancing** (numerical economy for satisfying progression)
8. **Sprite animations** (idle, run, work)
9. **Visual polish** (background, sky, day/night?)

---

## 11. Risks and open questions

### Risks

- **Performance** with many workers: test with 100+ active workers in MVP. If degradation, batch updates or use SpriteBatch.
- **Visual readability** when buildings are tightly packed: 8x8 zoomed pixel art; test multiple zoom levels from day one.
- **Incremental balancing**: easy to get wrong (too slow = boring, too fast = no satisfying wait). Empirical iteration required.
- **Minesweeper stub** may give a false "this works well" signal that breaks when the real Minesweeper replaces it.

### Open questions (to resolve during implementation or post-MVP)

1. **Initial pile caps** (log, stone): what value? Placeholder 10.
2. **When pile is full, does the click still grant Points?** (yes = anti-frustration; no = forces the player to unlock the chain)
3. **Construction and upgrade costs**: placeholder values, to balance.
4. **Gubo walking speed** + animation cadence.
5. **Exact Chroma Noir → entity sprite mapping**: TBD with user.
6. **Resource nudge in transit**: what exact effect? (+20% speed? teleport to next building edge?)
7. **Camera at game start**: centered on Tree? on Dormitory? framing all initial buildings?
8. **Visual indicator** when a building is buildable, and whether the cost is currently affordable.
9. **Minesweeper solved feedback**: visual flash? sound? popup?

---

## 12. MVP success criteria

The MVP is "done" if:

- The player can start from scratch and reach the first Minesweeper resolution within 5–15 minutes of active play.
- The flow click → automation → full chain is legible without a tutorial (just from clear UI).
- Chroma Noir sprites are actually used (not just rectangles).
- 100+ workers run at 60 FPS on the dev machine.
- The code → relaunch iteration loop is < 2 seconds.
