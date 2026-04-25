import { seededHash } from './noise.js';

const CHUNK_SIZE = 16;
const CACHE_MAX  = 512;

const BIOME_GRID = 25;
const BIOME_DEFS = [
  { density: 0.12, revealedColor: '#a8b8a8', unrevealedColor: '#2a3a2a' },  // green, low
  { density: 0.24, revealedColor: '#bcb8a4', unrevealedColor: '#3a3828' },  // yellow, medium
  { density: 0.38, revealedColor: '#b8a8a8', unrevealedColor: '#3c2e2e' },  // red, high
];

export function createWorld(seed) {
  const tileHash   = seededHash(seed ^ 0x9e3779b9);
  const biomeHashX = seededHash(seed ^ 0x12345678);
  const biomeHashY = seededHash(seed ^ 0xabcdef01);
  const biomeHashT = seededHash(seed ^ 0x87654321);

  const biomeCache = new Map();

  function getBiomeCenter(gx, gy) {
    const key = `${gx},${gy}`;
    if (biomeCache.has(key)) return biomeCache.get(key);
    const cx   = gx * BIOME_GRID + biomeHashX(gx, gy) * BIOME_GRID;
    const cy   = gy * BIOME_GRID + biomeHashY(gx, gy) * BIOME_GRID;
    const def  = BIOME_DEFS[Math.floor(biomeHashT(gx, gy) * BIOME_DEFS.length)];
    const b    = { cx, cy, ...def };
    biomeCache.set(key, b);
    return b;
  }

  function getBiome(tx, ty) {
    const gx = Math.floor(tx / BIOME_GRID);
    const gy = Math.floor(ty / BIOME_GRID);
    let bestDist = Infinity, best = null;
    for (let dy = -1; dy <= 1; dy++) {
      for (let dx = -1; dx <= 1; dx++) {
        const b    = getBiomeCenter(gx + dx, gy + dy);
        const dist = (tx - b.cx) ** 2 + (ty - b.cy) ** 2;
        if (dist < bestDist) { bestDist = dist; best = b; }
      }
    }
    return best;
  }

  const cache = new Map();

  function chunkKey(cx, cy) { return `${cx},${cy}`; }
  function localIndex(lx, ly) { return ly * CHUNK_SIZE + lx; }

  function tileToChunk(tx, ty) {
    const cx = Math.floor(tx / CHUNK_SIZE);
    const cy = Math.floor(ty / CHUNK_SIZE);
    return { cx, cy, lx: tx - cx * CHUNK_SIZE, ly: ty - cy * CHUNK_SIZE };
  }

  function densityAt(tx, ty) {
    return getBiome(tx, ty).density;
  }

  // ── generation ────────────────────────────────────────────────────────────

  function generateChunk(cx, cy) {
    const tiles = new Array(CHUNK_SIZE * CHUNK_SIZE);
    for (let ly = 0; ly < CHUNK_SIZE; ly++) {
      for (let lx = 0; lx < CHUNK_SIZE; lx++) {
        const tx = cx * CHUNK_SIZE + lx;
        const ty = cy * CHUNK_SIZE + ly;
        tiles[localIndex(lx, ly)] = {
          revealed: false,
          charred:  false,
          flagged:  false,
          object: tileHash(tx, ty) < densityAt(tx, ty) ? { type: 'mine' } : null,
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
        const entry = {};
        if (t.revealed) entry.r = 1;
        if (t.charred)  entry.c = 1;
        if (t.flagged)  entry.f = 1;
        if (t.object?.type === 'number')    entry.o = t.object.value;
        else if (t.object?.type === 'mine') entry.o = 'm';
        else if (t.revealed)                entry.o = null; // explicit null overrides procedural mine on reload
        if (Object.keys(entry).length > 0) diff[`${lx},${ly}`] = entry;
      }
    }
    const key = storageKey(chunk.cx, chunk.cy);
    try {
      if (Object.keys(diff).length > 0) {
        localStorage.setItem(key, JSON.stringify(diff));
      } else {
        localStorage.removeItem(key);
      }
    } catch (e) {
      // storage full — continue without saving
    }
    chunk.dirty = false;
  }

  function loadChunk(cx, cy) {
    const tiles = generateChunk(cx, cy);
    const raw = localStorage.getItem(storageKey(cx, cy));
    if (raw) {
      for (const [key, entry] of Object.entries(JSON.parse(raw))) {
        const [lx, ly] = key.split(',').map(Number);
        const tile = tiles[localIndex(lx, ly)];
        // support both compact (r/c/f/o) and legacy (revealed/charred/flagged/object) formats
        if (entry.r || entry.revealed) tile.revealed = true;
        if (entry.c || entry.charred)  tile.charred  = true;
        if (entry.f || entry.flagged)  tile.flagged  = true;
        if (entry.o !== undefined) {
          tile.object = entry.o === 'm'   ? { type: 'mine' } :
                        entry.o === null  ? null :
                        { type: 'number', value: entry.o };
        } else if (entry.object) {
          tile.object = entry.object;
        }
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
      cache.set(key, chunk);
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

  function mutateTile(tx, ty, updates) {
    const { cx, cy, lx, ly } = tileToChunk(tx, ty);
    const chunk = getChunk(cx, cy);
    Object.assign(chunk.tiles[localIndex(lx, ly)], updates);
    chunk.dirty = true;
  }

  // ── game logic ────────────────────────────────────────────────────────────

  function isMineAt(tx, ty) {
    return getTile(tx, ty).object?.type === 'mine';
  }

  function countAdjacentMines(tx, ty) {
    let count = 0;
    for (let dy = -1; dy <= 1; dy++) {
      for (let dx = -1; dx <= 1; dx++) {
        if (dx === 0 && dy === 0) continue;
        if (isMineAt(tx + dx, ty + dy)) count++;
      }
    }
    return count;
  }

  function _flood(stack, visited) {
    while (stack.length > 0) {
      const [tx, ty] = stack.pop();
      const key = `${tx},${ty}`;
      if (visited.has(key)) continue;
      visited.add(key);
      const tile = getTile(tx, ty);
      if (tile.revealed || tile.flagged || tile.charred || tile.object?.type === 'mine') continue;
      const adj = countAdjacentMines(tx, ty);
      mutateTile(tx, ty, {
        revealed: true,
        object: adj > 0 ? { type: 'number', value: adj } : null,
      });
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
  }

  function reveal(startTx, startTy) {
    _flood([[startTx, startTy]], new Set());
    scheduleSave();
  }

  function harvestTile(tx, ty) {
    const tile = getTile(tx, ty);
    const isUncharedZero = tile.revealed && !tile.charred && tile.object?.type === 'number' && tile.object.value === 0;
    if (!tile.charred && !isUncharedZero) return null;

    // Revealed exploded mine → Mine resource; tile becomes empty uncharred
    if (tile.revealed && tile.object?.type === 'mine') {
      mutateTile(tx, ty, { object: null, charred: false });
      for (let dy = -1; dy <= 1; dy++) {
        for (let dx = -1; dx <= 1; dx++) {
          if (dx === 0 && dy === 0) continue;
          const n = getTile(tx+dx, ty+dy);
          if (n.revealed && n.object?.type === 'number') {
            const adj = countAdjacentMines(tx+dx, ty+dy);
            mutateTile(tx+dx, ty+dy, { object: { type: 'number', value: adj } });
          }
        }
      }
      scheduleSave();
      return { resource: 'mine', amount: 1 };
    }

    // Revealed number → resource of that number type; recalculate and flood if now empty
    if (tile.revealed && tile.object?.type === 'number') {
      const value = tile.object.value;
      const adj   = countAdjacentMines(tx, ty);
      if (adj > 0) {
        mutateTile(tx, ty, { object: { type: 'number', value: adj }, charred: false });
      } else {
        mutateTile(tx, ty, { object: null, charred: false });
        const initStack   = [];
        const initVisited = new Set([`${tx},${ty}`]);
        for (let dy = -1; dy <= 1; dy++)
          for (let dx = -1; dx <= 1; dx++)
            if (dx !== 0 || dy !== 0) initStack.push([tx+dx, ty+dy]);
        _flood(initStack, initVisited);
      }
      scheduleSave();
      return { resource: String(value), amount: 1 };
    }

    // Charred flagged → Wood; becomes uncharred unrevealed (flag removed, object stays)
    if (tile.flagged) {
      mutateTile(tx, ty, { flagged: false, charred: false });
      scheduleSave();
      return { resource: 'wood', amount: 1 };
    }

    // Charred unrevealed → Charcoal; becomes revealed uncharred
    if (!tile.revealed) {
      const adj = countAdjacentMines(tx, ty);
      mutateTile(tx, ty, {
        revealed: true,
        charred:  false,
        object:   adj > 0 ? { type: 'number', value: adj } : null,
      });
      scheduleSave();
      return { resource: 'charcoal', amount: 1 };
    }

    // Revealed empty charred → Dust (number was decremented to 0 by a mine harvest)
    if (tile.revealed && !tile.object) {
      mutateTile(tx, ty, { charred: false });
      scheduleSave();
      return { resource: '0', amount: 1 };
    }

    return null;
  }

  function applyMineBuilding(tx, ty) {
    mutateTile(tx, ty, { object: { type: 'mine' } });
    for (let dy = -1; dy <= 1; dy++) {
      for (let dx = -1; dx <= 1; dx++) {
        if (dx === 0 && dy === 0) continue;
        const n = getTile(tx + dx, ty + dy);
        if (n.revealed && !n.charred && n.object?.type !== 'mine') {
          const adj = countAdjacentMines(tx + dx, ty + dy);
          mutateTile(tx + dx, ty + dy, { object: adj > 0 ? { type: 'number', value: adj } : null });
        }
      }
    }
    scheduleSave();
  }

  function toggleFlag(tx, ty) {
    const tile = getTile(tx, ty);
    if (!tile.revealed) {
      mutateTile(tx, ty, { flagged: !tile.flagged });
      scheduleSave();
    }
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

  return { CHUNK_SIZE, getChunk, getTile, mutateTile, toggleFlag, reveal, harvestTile, applyMineBuilding, countAdjacentMines, scheduleSave, saveAll: saveAllDirty, getBiome };
}
