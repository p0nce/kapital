# Infinite Minesweeper Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an infinite minesweeper prototype in vanilla JS + Canvas with procedural noise-based mine density, chunked world, chain explosions, and localStorage persistence.

**Architecture:** Seven focused ES modules wired by `main.js`. World state lives in `world.js` (chunk map + localStorage diff persistence). Camera and input are separate. `tick.js` handles time-stepped chain explosions. No build step — open `index.html` directly.

**Tech Stack:** Vanilla JavaScript (ES modules), HTML5 Canvas, localStorage, no dependencies.

**Spec:** `docs/superpowers/specs/2026-04-25-minesweeper-design.md`

---

## File Map

| File | Responsibility |
|---|---|
| `prototypes/minesweeper/index.html` | Canvas host, CSS reset, imports main.js |
| `prototypes/minesweeper/src/noise.js` | `seededHash(seed)` + `createValueNoise(seed)` |
| `prototypes/minesweeper/src/world.js` | Chunk cache, tile state, proc-gen, flood-fill reveal, localStorage diff |
| `prototypes/minesweeper/src/camera.js` | Viewport position, screenToTile, visibleChunkRange, keyboard scroll |
| `prototypes/minesweeper/src/renderer.js` | Canvas draw: clear + iterate visible chunks + draw each tile |
| `prototypes/minesweeper/src/input.js` | Mouse drag/click/right-click + WASD/arrow keysHeld set |
| `prototypes/minesweeper/src/tick.js` | `setInterval` tick, explosion queue propagation |
| `prototypes/minesweeper/src/main.js` | Entry point, resize, game loop, wires all modules |

---

## Task 1: Project Scaffold

**Files:**
- Create: `prototypes/minesweeper/index.html`
- Create: `prototypes/minesweeper/src/noise.js` (empty export)
- Create: `prototypes/minesweeper/src/world.js` (empty export)
- Create: `prototypes/minesweeper/src/camera.js` (empty export)
- Create: `prototypes/minesweeper/src/renderer.js` (empty export)
- Create: `prototypes/minesweeper/src/input.js` (empty export)
- Create: `prototypes/minesweeper/src/tick.js` (empty export)
- Create: `prototypes/minesweeper/src/main.js` (canvas + resize only)

- [ ] **Step 1: Create `index.html`**

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Infinite Minesweeper</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { background: #1a1a1a; overflow: hidden; }
    canvas { display: block; }
  </style>
</head>
<body>
  <canvas id="game"></canvas>
  <script type="module" src="src/main.js"></script>
</body>
</html>
```

- [ ] **Step 2: Create stub modules**

`src/noise.js`:
```js
export function seededHash(seed) { return (x, y) => 0; }
export function createValueNoise(seed) { return (x, y) => 0; }
```

`src/world.js`:
```js
export function createWorld(seed) { return {}; }
```

`src/camera.js`:
```js
export function createCamera(canvas) { return {}; }
```

`src/renderer.js`:
```js
export function createRenderer(canvas, ctx) { return { render() {} }; }
```

`src/input.js`:
```js
export function createInput(canvas, cam, world, tick) { return { keysHeld: new Set() }; }
```

`src/tick.js`:
```js
export function createTick(world) { return { triggerExplosion(tx, ty) {} }; }
```

- [ ] **Step 3: Create `src/main.js`**

```js
import { createWorld }    from './world.js';
import { createCamera }   from './camera.js';
import { createRenderer } from './renderer.js';
import { createInput }    from './input.js';
import { createTick }     from './tick.js';

const canvas = document.getElementById('game');
const ctx = canvas.getContext('2d');

function resize() {
  canvas.width = window.innerWidth;
  canvas.height = window.innerHeight;
}
resize();
window.addEventListener('resize', resize);

const SEED = 42;
const world    = createWorld(SEED);
const cam      = createCamera(canvas);
const renderer = createRenderer(canvas, ctx);
const tick     = createTick(world);
const input    = createInput(canvas, cam, world, tick);

let lastTime = 0;
function loop(ts) {
  const dt = Math.min((ts - lastTime) / 1000, 0.1);
  lastTime = ts;
  cam.update(dt, input.keysHeld);
  renderer.render(world, cam);
  requestAnimationFrame(loop);
}
requestAnimationFrame(loop);
```

- [ ] **Step 4: Verify — open `index.html` in a browser**

Expected: black canvas, no console errors.

---

## Task 2: noise.js — Seeded Hash + Value Noise

**Files:**
- Modify: `prototypes/minesweeper/src/noise.js`

- [ ] **Step 1: Implement `seededHash` and `createValueNoise`**

```js
// seededHash(seed)(x, y) → deterministic float in [0, 1]
export function seededHash(seed) {
  return function hash(x, y) {
    let h = (seed | 0) ^ Math.imul(x | 0, 374761393) ^ Math.imul(y | 0, 1103515245);
    h = Math.imul(h ^ (h >>> 13), 1664525) + 1013904223;
    h = Math.imul(h ^ (h >>> 15), 2246822519);
    return (h >>> 0) / 0xFFFFFFFF;
  };
}

// createValueNoise(seed)(x, y) → smooth noise in [0, 1]
export function createValueNoise(seed) {
  const h = seededHash(seed);
  const fade = t => t * t * (3 - 2 * t);
  return function noise(x, y) {
    const ix = Math.floor(x), iy = Math.floor(y);
    const fx = x - ix,        fy = y - iy;
    const a = h(ix,   iy),   b = h(ix+1, iy);
    const c = h(ix,   iy+1), d = h(ix+1, iy+1);
    const sx = fade(fx), sy = fade(fy);
    return a + (b-a)*sx + (c-a)*sy + (a-b-c+d)*sx*sy;
  };
}
```

- [ ] **Step 2: Verify in browser console**

Open DevTools console, add a temporary script tag or paste:
```js
// Quick sanity — values should be in [0,1] and vary
import('./src/noise.js').then(({ createValueNoise }) => {
  const n = createValueNoise(42);
  console.log(n(0,0), n(0.5,0.5), n(100,100), n(100.001,100)); // all in [0,1]
  console.log(n(1,1) === n(1,1)); // true — deterministic
});
```
Expected: four numbers in [0,1], last comparison is `true`.

---

## Task 3: world.js — Chunk System, Proc-Gen, localStorage

**Files:**
- Modify: `prototypes/minesweeper/src/world.js`

- [ ] **Step 1: Implement `createWorld`**

```js
import { seededHash, createValueNoise } from './noise.js';

const CHUNK_SIZE = 16;
const CACHE_MAX  = 512;
const DENSITY_SCALE = 200; // world units per noise cycle

export function createWorld(seed) {
  const densityNoise = createValueNoise(seed);
  const tileHash     = seededHash(seed ^ 0x9e3779b9);

  // LRU cache: Map preserves insertion order; oldest = first entry
  const cache = new Map();

  // ── helpers ──────────────────────────────────────────────────────────────

  function chunkKey(cx, cy) { return `${cx},${cy}`; }

  // Tile local index within chunk
  function localIndex(lx, ly) { return ly * CHUNK_SIZE + lx; }

  // World tile → chunk coords + local coords (works for negative tx/ty)
  function tileToChunk(tx, ty) {
    const cx = Math.floor(tx / CHUNK_SIZE);
    const cy = Math.floor(ty / CHUNK_SIZE);
    return { cx, cy, lx: tx - cx * CHUNK_SIZE, ly: ty - cy * CHUNK_SIZE };
  }

  function densityAt(tx, ty) {
    const n = densityNoise(tx / DENSITY_SCALE, ty / DENSITY_SCALE);
    return 0.05 + n * 0.30; // 5%–35%
  }

  // ── generation ────────────────────────────────────────────────────────────

  function generateChunk(cx, cy) {
    const tiles = new Array(CHUNK_SIZE * CHUNK_SIZE);
    for (let ly = 0; ly < CHUNK_SIZE; ly++) {
      for (let lx = 0; lx < CHUNK_SIZE; lx++) {
        const tx = cx * CHUNK_SIZE + lx;
        const ty = cy * CHUNK_SIZE + ly;
        tiles[localIndex(lx, ly)] = {
          isMine: tileHash(tx, ty) < densityAt(tx, ty),
          state: 'hidden',
          adjacentMines: -1,
        };
      }
    }
    return tiles;
  }

  // ── localStorage persistence ──────────────────────────────────────────────

  function storageKey(cx, cy) { return `chunk:${cx},${cy}`; }

  function saveChunk(chunk) {
    const diff = {};
    for (let ly = 0; ly < CHUNK_SIZE; ly++) {
      for (let lx = 0; lx < CHUNK_SIZE; lx++) {
        const t = chunk.tiles[localIndex(lx, ly)];
        if (t.state !== 'hidden') {
          diff[`${lx},${ly}`] = { state: t.state, adjacentMines: t.adjacentMines };
        }
      }
    }
    const key = storageKey(chunk.cx, chunk.cy);
    if (Object.keys(diff).length > 0) {
      localStorage.setItem(key, JSON.stringify(diff));
    } else {
      localStorage.removeItem(key);
    }
    chunk.dirty = false;
  }

  function loadChunk(cx, cy) {
    const tiles = generateChunk(cx, cy);
    const raw = localStorage.getItem(storageKey(cx, cy));
    if (raw) {
      for (const [key, data] of Object.entries(JSON.parse(raw))) {
        const [lx, ly] = key.split(',').map(Number);
        Object.assign(tiles[localIndex(lx, ly)], data);
      }
    }
    return { tiles, dirty: false, cx, cy };
  }

  // ── cache ─────────────────────────────────────────────────────────────────

  function evictOldest() {
    const key = cache.keys().next().value;
    const chunk = cache.get(key);
    if (chunk.dirty) saveChunk(chunk);
    cache.delete(key);
  }

  function getChunk(cx, cy) {
    const key = chunkKey(cx, cy);
    if (cache.has(key)) {
      const chunk = cache.get(key);
      cache.delete(key);
      cache.set(key, chunk); // move to end = most recently used
      return chunk;
    }
    if (cache.size >= CACHE_MAX) evictOldest();
    const chunk = loadChunk(cx, cy);
    cache.set(key, chunk);
    return chunk;
  }

  // ── tile access ───────────────────────────────────────────────────────────

  function getTile(tx, ty) {
    const { cx, cy, lx, ly } = tileToChunk(tx, ty);
    return getChunk(cx, cy).tiles[localIndex(lx, ly)];
  }

  function setTileState(tx, ty, state, adjacentMines = -1) {
    const { cx, cy, lx, ly } = tileToChunk(tx, ty);
    const chunk = getChunk(cx, cy);
    const tile  = chunk.tiles[localIndex(lx, ly)];
    tile.state = state;
    tile.adjacentMines = adjacentMines;
    chunk.dirty = true;
  }

  // ── game logic ────────────────────────────────────────────────────────────

  function countAdjacentMines(tx, ty) {
    let count = 0;
    for (let dy = -1; dy <= 1; dy++) {
      for (let dx = -1; dx <= 1; dx++) {
        if (dx === 0 && dy === 0) continue;
        if (getTile(tx + dx, ty + dy).isMine) count++;
      }
    }
    return count;
  }

  function reveal(startTx, startTy) {
    const stack   = [[startTx, startTy]];
    const visited = new Set();
    while (stack.length > 0) {
      const [tx, ty] = stack.pop();
      const key = `${tx},${ty}`;
      if (visited.has(key)) continue;
      visited.add(key);
      const tile = getTile(tx, ty);
      if (tile.state !== 'hidden' || tile.isMine) continue;
      const adj = countAdjacentMines(tx, ty);
      setTileState(tx, ty, 'revealed', adj);
      if (adj === 0) {
        for (let dy = -1; dy <= 1; dy++) {
          for (let dx = -1; dx <= 1; dx++) {
            if (dx === 0 && dy === 0) continue;
            const nk = `${tx+dx},${ty+dy}`;
            if (!visited.has(nk)) stack.push([tx+dx, ty+dy]);
          }
        }
      }
    }
    scheduleSave();
  }

  // ── debounced save ────────────────────────────────────────────────────────

  let saveTimer = null;

  function saveAllDirty() {
    for (const chunk of cache.values()) {
      if (chunk.dirty) saveChunk(chunk);
    }
    saveTimer = null;
  }

  function scheduleSave() {
    if (saveTimer) clearTimeout(saveTimer);
    saveTimer = setTimeout(saveAllDirty, 2000);
  }

  window.addEventListener('beforeunload', saveAllDirty);

  // ── density query (for renderer tint) ────────────────────────────────────

  function getDensity(tx, ty) { return densityAt(tx, ty); }

  return { CHUNK_SIZE, getChunk, getTile, setTileState, reveal, countAdjacentMines, scheduleSave, getDensity };
}
```

- [ ] **Step 2: Verify in browser console**

Open `index.html`, paste in DevTools:
```js
// world is available via main.js — check window or add temporary debug exposure
// OR just verify no console errors on page load
```
Expected: no errors. The stubs in main.js construct a world without crashing.

---

## Task 4: camera.js — Viewport & Scroll

**Files:**
- Modify: `prototypes/minesweeper/src/camera.js`

- [ ] **Step 1: Implement `createCamera`**

```js
export function createCamera(canvas) {
  const cam = {
    x: 0,
    y: 0,
    tileSize: 32,

    screenToTile(sx, sy) {
      return {
        tx: Math.floor((sx + this.x) / this.tileSize),
        ty: Math.floor((sy + this.y) / this.tileSize),
      };
    },

    visibleChunkRange(chunkSize) {
      const ts   = this.tileSize;
      const minTx = Math.floor(this.x / ts) - 1;
      const minTy = Math.floor(this.y / ts) - 1;
      const maxTx = Math.ceil((this.x + canvas.width)  / ts) + 1;
      const maxTy = Math.ceil((this.y + canvas.height) / ts) + 1;
      return {
        minCx: Math.floor(minTx / chunkSize),
        minCy: Math.floor(minTy / chunkSize),
        maxCx: Math.floor(maxTx / chunkSize),
        maxCy: Math.floor(maxTy / chunkSize),
      };
    },

    update(dt, keysHeld) {
      const spd = 6 * this.tileSize * dt;
      if (keysHeld.has('ArrowLeft')  || keysHeld.has('KeyA')) this.x -= spd;
      if (keysHeld.has('ArrowRight') || keysHeld.has('KeyD')) this.x += spd;
      if (keysHeld.has('ArrowUp')    || keysHeld.has('KeyW')) this.y -= spd;
      if (keysHeld.has('ArrowDown')  || keysHeld.has('KeyS')) this.y += spd;
    },
  };
  return cam;
}
```

- [ ] **Step 2: Verify — open `index.html`**

Expected: no errors. Keyboard input can't be verified yet (renderer not wired), but no crash.

---

## Task 5: renderer.js — Canvas Draw

**Files:**
- Modify: `prototypes/minesweeper/src/renderer.js`

- [ ] **Step 1: Implement `createRenderer`**

```js
const NUMBER_COLORS = [
  '', '#1a6bff', '#2d7a2d', '#e03333',
  '#00008b', '#8b0000', '#008b8b', '#222222', '#808080',
];

export function createRenderer(canvas, ctx) {
  function drawTile(tx, ty, tile, cam) {
    const { x: camX, y: camY, tileSize: ts } = cam;
    const sx = tx * ts - camX;
    const sy = ty * ts - camY;
    const gap = 1;

    // Background
    switch (tile.state) {
      case 'hidden':   ctx.fillStyle = '#3a3a3a'; break;
      case 'flagged':  ctx.fillStyle = '#3a3a3a'; break;
      case 'revealed': ctx.fillStyle = '#b8b8b8'; break;
      case 'exploded': ctx.fillStyle = '#111111'; break;
      case 'charcoal': ctx.fillStyle = '#2a1f1a'; break;
    }
    ctx.fillRect(sx + gap, sy + gap, ts - gap, ts - gap);

    // Markers
    const cx = sx + ts / 2, cy = sy + ts / 2;

    if (tile.state === 'flagged') {
      ctx.fillStyle = '#ff3333';
      ctx.font = `${Math.floor(ts * 0.5)}px sans-serif`;
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.fillText('F', cx, cy);
    } else if (tile.state === 'revealed' && tile.adjacentMines > 0) {
      ctx.fillStyle = NUMBER_COLORS[tile.adjacentMines];
      ctx.font = `bold ${Math.floor(ts * 0.55)}px sans-serif`;
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.fillText(tile.adjacentMines, cx, cy);
    } else if (tile.state === 'exploded') {
      ctx.fillStyle = '#ff6600';
      ctx.beginPath();
      ctx.arc(cx, cy, ts * 0.25, 0, Math.PI * 2);
      ctx.fill();
    }
  }

  function render(world, cam) {
    ctx.fillStyle = '#1a1a1a';
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    if (!world.getChunk) return; // stub guard

    const { minCx, minCy, maxCx, maxCy } = cam.visibleChunkRange(world.CHUNK_SIZE);

    for (let cy = minCy; cy <= maxCy; cy++) {
      for (let cx = minCx; cx <= maxCx; cx++) {
        const chunk = world.getChunk(cx, cy);
        for (let ly = 0; ly < world.CHUNK_SIZE; ly++) {
          for (let lx = 0; lx < world.CHUNK_SIZE; lx++) {
            const tx   = cx * world.CHUNK_SIZE + lx;
            const ty   = cy * world.CHUNK_SIZE + ly;
            const tile = chunk.tiles[ly * world.CHUNK_SIZE + lx];
            drawTile(tx, ty, tile, cam);
          }
        }
      }
    }
  }

  return { render };
}
```

- [ ] **Step 2: Verify — open `index.html`**

Expected: a grey tiled grid fills the canvas. WASD/arrow keys don't work yet (input not wired), but the grid should be visible and static.

---

## Task 6: input.js — Mouse & Keyboard

**Files:**
- Modify: `prototypes/minesweeper/src/input.js`

- [ ] **Step 1: Implement `createInput`**

```js
export function createInput(canvas, cam, world, tick) {
  const keysHeld = new Set();

  // ── keyboard ──────────────────────────────────────────────────────────────
  window.addEventListener('keydown', e => {
    keysHeld.add(e.code);
    // Prevent arrow keys from scrolling the page
    if (['ArrowUp','ArrowDown','ArrowLeft','ArrowRight'].includes(e.code)) {
      e.preventDefault();
    }
  });
  window.addEventListener('keyup', e => keysHeld.delete(e.code));

  // ── mouse drag / click ────────────────────────────────────────────────────
  let dragStart   = null;
  let camAtDrag   = null;
  let dragged     = false;

  canvas.addEventListener('mousedown', e => {
    if (e.button !== 0) return;
    dragStart = { x: e.clientX, y: e.clientY };
    camAtDrag = { x: cam.x, y: cam.y };
    dragged   = false;
  });

  canvas.addEventListener('mousemove', e => {
    if (!dragStart) return;
    const dx = e.clientX - dragStart.x;
    const dy = e.clientY - dragStart.y;
    if (!dragged && (Math.abs(dx) > 4 || Math.abs(dy) > 4)) dragged = true;
    if (dragged) {
      cam.x = camAtDrag.x - dx;
      cam.y = camAtDrag.y - dy;
    }
  });

  canvas.addEventListener('mouseup', e => {
    if (e.button === 0 && dragStart && !dragged) {
      handleLeftClick(e.clientX, e.clientY);
    }
    dragStart = null;
  });

  canvas.addEventListener('contextmenu', e => {
    e.preventDefault();
    handleRightClick(e.clientX, e.clientY);
  });

  // ── tile interactions ─────────────────────────────────────────────────────
  function handleLeftClick(sx, sy) {
    const { tx, ty } = cam.screenToTile(sx, sy);
    const tile = world.getTile(tx, ty);
    if (tile.state === 'hidden') {
      if (tile.isMine) {
        tick.triggerExplosion(tx, ty);
      } else {
        world.reveal(tx, ty);
      }
    }
  }

  function handleRightClick(sx, sy) {
    const { tx, ty } = cam.screenToTile(sx, sy);
    const tile = world.getTile(tx, ty);
    if (tile.state === 'hidden') {
      world.setTileState(tx, ty, 'flagged');
      world.scheduleSave();
    } else if (tile.state === 'flagged') {
      world.setTileState(tx, ty, 'hidden');
      world.scheduleSave();
    }
  }

  return { keysHeld };
}
```

- [ ] **Step 2: Verify — open `index.html`**

Expected:
- WASD and arrow keys scroll the grid
- Drag pans the camera
- Left-clicking a tile reveals it (grey → lighter grey with number, or flood-fills if 0)
- Right-clicking a tile places/removes a flag ("F")

---

## Task 7: tick.js — Chain Explosion Tick

**Files:**
- Modify: `prototypes/minesweeper/src/tick.js`

- [ ] **Step 1: Implement `createTick`**

```js
export function createTick(world) {
  let pending = new Set(); // "tx,ty" keys for mines exploding this tick
  let next    = new Set(); // mines queued for next tick

  function tick() {
    if (pending.size === 0) return;

    for (const key of pending) {
      const [tx, ty] = key.split(',').map(Number);
      world.setTileState(tx, ty, 'exploded');

      for (let dy = -1; dy <= 1; dy++) {
        for (let dx = -1; dx <= 1; dx++) {
          if (dx === 0 && dy === 0) continue;
          const nx = tx + dx, ny = ty + dy;
          const neighbor = world.getTile(nx, ny);
          const nstate   = neighbor.state;
          if (neighbor.isMine && (nstate === 'hidden' || nstate === 'flagged')) {
            next.add(`${nx},${ny}`);
          } else if (!neighbor.isMine && (nstate === 'hidden' || nstate === 'flagged')) {
            world.setTileState(nx, ny, 'charcoal');
          }
        }
      }
    }

    world.scheduleSave();
    pending = next;
    next = new Set();
  }

  setInterval(tick, 150);

  function triggerExplosion(tx, ty) {
    pending.add(`${tx},${ty}`);
  }

  return { triggerExplosion };
}
```

- [ ] **Step 2: Verify — open `index.html`**

Expected:
- Left-clicking a hidden mine tile triggers an explosion (black + orange dot) and neighbouring safe tiles become dark brown (charcoal)
- Dense mine regions produce chain reactions that ripple outward tick by tick (~150ms per wave)
- Clicking in a low-density region reveals large open areas via flood-fill
- Refreshing the page restores the revealed/exploded/flagged state (localStorage persistence)

---

## Self-Review Notes

- All tile states (`hidden`, `flagged`, `revealed`, `exploded`, `charcoal`) are covered in renderer ✓
- Negative tile coordinates handled by `Math.floor` division in `tileToChunk` ✓
- Flood-fill is iterative (stack), no recursion stack-overflow risk ✓
- LRU eviction saves dirty chunks immediately ✓
- `scheduleSave` called after every mutation path ✓
- Stub guard in `renderer.render` prevents crash before world is real ✓
- No TDD ceremony per project convention — prototype verified by opening in browser ✓
