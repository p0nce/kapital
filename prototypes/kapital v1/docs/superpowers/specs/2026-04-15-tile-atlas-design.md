# Tile Atlas — Design Spec
_Date: 2026-04-15_

## Purpose

Introduce an editable pixel-art tile atlas so some blocks can be drawn from authored sprites instead of procedural canvas code. The atlas is loaded at startup and made available to the renderer. No existing procedural drawing is replaced as part of this work — wiring specific blocks to the atlas happens later.

## Asset

**File:** `assets/atlas.png` — 48 × 88 pixel PNG, nearest-neighbour scaling.

**Grid:** each tile is **8 × 8 pixels**. The sheet is **6 columns × 11 rows**.

- **Columns** are animation frames, left to right: frame 0 → frame 5.
- **Rows** are block slots:

| Row | Slot             |
|-----|------------------|
| 0   | `tower_alone`    |
| 1   | `tower_up`       |
| 2   | `tower_down`     |
| 3   | `platform_base`  |
| 4   | `platform_left`  |
| 5   | `platform_right` |
| 6   | `flag`           |
| 7   | `cannon`         |
| 8   | `apartment`      |
| 9   | `ground`         |
| 10  | `tower_mid`      |

Tower has four slots because its appearance depends on vertical neighbours:
- `tower_alone` — standalone single-cell tower.
- `tower_up` — top of a vertical tower run (no tower above, tower below).
- `tower_down` — bottom of a run (tower above, no tower below).
- `tower_mid` — middle of a run (tower both above and below).

## Initial Art

Placeholder only. Each row is a distinct flat colour, with:
- The row index drawn as a 1-pixel marker in the top-left of frame 0.
- The frame index drawn as a 1-pixel marker in the top-right of every frame.
- A subtle per-frame variation (1-pixel shift of one marker) so animation is visible immediately.

The placeholder is produced by a tiny one-shot Node/JS generator script checked into the repo, run manually; its output is the committed PNG. Artists will replace the PNG in an external editor (Aseprite, Piskel, etc.). The generator is not wired into the build.

## Runtime Loader

New module **`js/tileatlas.js`**, loaded before `render.js` via a script tag in `index.html`.

**Public surface:**

```js
const TILE_SIZE = 8;
const TILE_FRAMES = 6;
const TILE_FRAME_MS = 150;     // ≈ 6.7 fps animation

const TILE_ROW = {
  tower_alone:    0,
  tower_up:       1,
  tower_down:     2,
  platform_base:  3,
  platform_left:  4,
  platform_right: 5,
  flag:           6,
  cannon:         7,
  apartment:      8,
  ground:         9,
};

const TileAtlas = {
  image,   // HTMLImageElement
  ready,   // Promise<void>, resolves when image is loaded
  drawTile(ctx, name, x, y, now, scale = 1),
};
```

**Behaviour:**

- On script load, create an `Image()`, set `src = 'assets/atlas.png'`, and store a `ready` Promise that resolves on `onload` / rejects on `onerror`.
- `drawTile` computes `frame = Math.floor(now / TILE_FRAME_MS) % TILE_FRAMES` and calls `ctx.drawImage(image, frame * 8, row * 8, 8, 8, x, y, 8 * scale, 8 * scale)`.
- Drawing before the image loads is a no-op (early return if `!image.complete`).
- `ctx.imageSmoothingEnabled = false` is set at the call site by the caller; the loader does not mutate shared context state.

## Integration

- Add `<script src="js/tileatlas.js"></script>` to `index.html` **before** `render.js`.
- Nothing in `render.js` changes in this task. The atlas is available but unused.
- Render loop does not need to await `ready` — `drawTile` simply no-ops until the image is ready, and the placeholder appears on the next frame.

## Out of Scope

- Replacing any existing procedural drawing.
- Multi-tile "rooms" per block (each slot is a single 8×8 tile).
- A palette file or indexed-colour format.
- Hot reload / dev-time watching of the PNG.
- Authoring tools or in-browser editor.
- `tower_mid` slot (can be added later as row 10).

## Success Criteria

- `assets/atlas.png` exists in the repo at 48 × 88 pixels.
- Opening the PNG in a pixel-art editor clearly shows 10 rows × 6 columns of distinct 8×8 cells.
- Loading `index.html` does not log any errors; `TileAtlas.ready` resolves.
- Calling `TileAtlas.drawTile(ctx, 'tower_alone', 100, 100, performance.now(), 4)` from the dev console draws a 32×32 block that visibly animates through 6 frames.
