# Infinite Minesweeper — Design Spec
**Date:** 2026-04-25

## Overview

A minesweeper game on an infinite 2D world. The player explores freely, reveals tiles, triggers chain explosions, and navigates without win or lose conditions. Inspired by development games like Minecraft — mines and charcoal are future harvestable resources. Built with vanilla JavaScript and HTML5 Canvas, no build step.

---

## Stack

- Vanilla JavaScript (ES modules)
- HTML5 Canvas
- No dependencies, no bundler — open `index.html` directly in a browser

---

## File Structure

```
prototypes/minesweeper/
  index.html
  src/
    main.js       — entry point, game loop (requestAnimationFrame)
    world.js      — chunk map, tile state, procedural generation, localStorage persistence
    noise.js      — seeded 2D value noise for mine density map
    camera.js     — viewport position, pan, keyboard scroll
    renderer.js   — canvas draw calls
    input.js      — mouse (drag/click/right-click) + WASD/arrow keys
    tick.js       — setInterval tick, chain explosion propagation (extensible for future mechanics)
```

---

## World & Chunks

**Chunk size:** 16×16 tiles, addressed by integer `(cx, cy)`.  
**Chunk cache:** `Map` keyed by `"cx,cy"` string. LRU eviction at 512 chunks.

**Lazy generation:** chunks are generated on demand. Each frame the renderer computes the visible chunk range and calls `world.getChunk(cx, cy)` for each. On cache miss, the chunk is generated immediately (stateless hash — fast enough to be imperceptible), any saved localStorage diff is applied, and it is inserted into the LRU cache.

**Tile data:**
```js
{ isMine: bool, state: string, adjacentMines: int }
// state: 'hidden' | 'flagged' | 'revealed' | 'exploded' | 'charcoal'
// adjacentMines: computed lazily on first reveal
```

**Procedural generation (stateless, deterministic):**
1. Low-frequency 2D value noise (scale ~200 tiles, seeded) produces a density map — values map to mine probability from ~5% (safe zones) to ~35% (dense zones).
2. Per-tile: `hash(worldSeed, tileX, tileY)` yields a deterministic `[0, 1]` value; compared against local density to decide `isMine`.

The world seed is fixed at startup. Generation is stateless, so evicted chunks can be regenerated identically.

**Persistence (localStorage):**
- Only mutations are saved: tiles whose state differs from `hidden`.
- Format: `localStorage["chunk:cx,cy"]` = JSON `{ "x,y": { state, adjacentMines } }`.
- Writes are debounced (2s after last mutation), on `beforeunload`, and immediately on LRU eviction if the chunk has unsaved mutations.
- On chunk load: generate fresh, then apply saved diff on top.

---

## Camera & Input

**Camera:** `{ x, y }` world-space pixel position of the viewport top-left. Fixed `tileSize = 32px`.

```
tileX = floor((screenX + camera.x) / tileSize)
tileY = floor((screenY + camera.y) / tileSize)
```

**Pan:** `mousedown` records start. `mousemove` while held updates `camera.x/y` by delta. `mouseup` — if drag distance < 4px, treat as click.

**Keyboard scroll:** WASD / arrow keys held move camera at 6 tiles/sec, tracked via `keysHeld` set in the game loop.

**Mouse interactions:**
- Left click hidden tile → reveal (or trigger explosion if mine)
- Right click hidden tile → toggle flag
- Right click flagged tile → remove flag

**Tile visibility:** each frame, compute visible chunk range from camera and canvas size; iterate only those chunks.

**Canvas:** fills the browser window, updates on `resize`.

---

## Game Tick

`tick()` runs via `setInterval` at 150ms. Handles anything needing time-stepped updates.

**Chain explosion propagation:**
- `pendingExplosions: Set<"tileX,tileY">` — mines exploding this tick
- `nextExplosions: Set<"tileX,tileY">` — mines queued for next tick

Each tick:
1. For each tile in `pendingExplosions`: set state to `exploded`
2. For each of its 8 neighbors:
   - Mine (hidden/flagged) → add to `nextExplosions`
   - Safe hidden/flagged → set to `charcoal`
   - Already revealed → leave unchanged
3. Mark affected chunks dirty for debounced localStorage save
4. Swap: `pendingExplosions = nextExplosions`, clear `nextExplosions`

**Triggering:** left-clicking a mine adds it to `pendingExplosions` immediately (first explosion fires on the next tick, ~150ms later).

---

## Renderer

Each frame: clear canvas, draw all visible tiles.

| State | Visual |
|---|---|
| `hidden` | Dark grey fill |
| `flagged` | Dark grey + red flag marker |
| `revealed` | Light grey fill + colored number (1-8), empty if 0 |
| `exploded` | Black fill + orange/red crater marker |
| `charcoal` | Dark brown fill |

Number colors follow minesweeper convention (1=blue, 2=green, 3=red, 4=darkblue, 5=darkred, 6=teal, 7=black, 8=grey).

1px gap between tiles (via slight inset on fill rect) gives grid feel without drawing grid lines.

Optional: subtle tint on hidden tiles based on local noise density value to hint at danger zones.

---

## Future Hooks (not in this prototype)

- Harvesting: click revealed mine/charcoal to collect resources
- Resource inventory UI
- Crafting / building loop
