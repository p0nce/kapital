// ─── Grid data ────────────────────────────────────────────────────────────────
// grid[row][col] = { type: 'empty'|'ground'|'tower'|'platform'|'cannon'|'special', owner: null|0|1 }
const grid = Array.from({ length: ROWS }, () =>
  Array.from({ length: TOTAL_COLS }, () => ({ type: 'empty', owner: null, role: null }))
);

function setCell(row, col, type, owner, role = null) {
  grid[row][col] = { type, owner, role };
}

function topOf(col) {
  for (let row = ROWS - 1; row >= 0; row--)
    if (grid[row][col].type !== 'empty') return row;
  return -1;
}

function inZone(col, player) {
  return col >= ZONE_START[player] && col <= ZONE_END[player];
}

function initGrid() {
  for (let c = 0; c < TOTAL_COLS; c++) setCell(0, c, 'ground', null);

  // Default city: 3 apartments side by side, the middle one sits on a
  // single-cell tower, a flag on top of that middle apartment.
  const p1c = P1_START + Math.floor(P_COLS / 2);
  setCell(1, p1c - 1, 'apartment', 0);
  setCell(1, p1c,     'tower',     0);
  setCell(1, p1c + 1, 'apartment', 0);
  setCell(2, p1c,     'apartment', 0);
  setCell(3, p1c,     'flag',      0);

  const p2c = P2_START + Math.floor(P_COLS / 2);
  setCell(1, p2c - 1, 'apartment', 1);
  setCell(1, p2c,     'tower',     1);
  setCell(1, p2c + 1, 'apartment', 1);
  setCell(2, p2c,     'apartment', 1);
  setCell(3, p2c,     'flag',      1);
}

// ─── Physics ──────────────────────────────────────────────────────────────────
function fallPass() {
  let changed = true;
  while (changed) {
    changed = false;
    for (let row = 1; row < ROWS; row++)
      for (let col = 0; col < TOTAL_COLS; col++) {
        const cell = grid[row][col];
        if (cell.type === 'empty' || cell.type === 'ground') continue;

        // Platform wings are supported by their base (same row, adjacent col),
        // not by whatever is directly below them.
        if (cell.type === 'platform' && (cell.role === 'left' || cell.role === 'right')) {
          const baseCol = cell.role === 'left' ? col + 1 : col - 1;
          const base = grid[row]?.[baseCol];
          if (base && base.type === 'platform' && base.role === 'base') continue;
        }

        if (grid[row - 1][col].type === 'empty') {
          grid[row - 1][col] = cell;
          grid[row][col] = { type: 'empty', owner: null, role: null };
          changed = true;
        }
      }
  }
}

function destroyBlock(col) {
  const top = topOf(col);
  if (top <= 0) return;
  grid[top][col] = { type: 'empty', owner: null, role: null };
  fallPass();
}

// Support-graph cascade destruction used by cannon hits.
// Rules:
//   - A block above (r+1,c) is supported by (r,c) unless the block above is
//     a platform wing (role 'left' or 'right'). Wings are supported by their
//     base, not by what's below them.
//   - A platform base at (r,c) supports its wings at (r,c-1) and (r,c+1)
//     (when those cells are wings).
// Destroying a block recursively destroys everything transitively supported
// by it.
function cascadeDestroy(startRow, startCol, maxCount = Infinity) {
  if (startRow <= 0) return;  // never destroy the ground
  if (maxCount <= 0) return;
  const destroyed = new Set();
  const queue = [[startRow, startCol]];
  let billed = 0;    // number of destructions that count toward maxCount (wings are free)
  while (queue.length) {
    const [r, c] = queue.shift();
    if (r < 0 || r >= ROWS || c < 0 || c >= TOTAL_COLS) continue;
    const key = r * 1000 + c;
    if (destroyed.has(key)) continue;
    const cell = grid[r][c];
    if (cell.type === 'empty' || cell.type === 'ground') continue;

    // Platform wings come with their base for free — they don't use strength.
    const isWing = cell.type === 'platform' && (cell.role === 'left' || cell.role === 'right');
    if (!isWing) {
      if (billed >= maxCount) continue;
      billed++;
    }
    destroyed.add(key);

    // Whatever sits directly above — unless it's a platform wing
    if (r + 1 < ROWS) {
      const above = grid[r + 1][c];
      const isWing = above.type === 'platform' && (above.role === 'left' || above.role === 'right');
      if (!isWing && above.type !== 'empty' && above.type !== 'ground') {
        queue.push([r + 1, c]);
      }
    }

    // If this cell is a platform base, its wings come down with it
    if (cell.type === 'platform' && cell.role === 'base') {
      if (c - 1 >= 0) {
        const left = grid[r][c - 1];
        if (left.type === 'platform' && left.role === 'left') queue.push([r, c - 1]);
      }
      if (c + 1 < TOTAL_COLS) {
        const right = grid[r][c + 1];
        if (right.type === 'platform' && right.role === 'right') queue.push([r, c + 1]);
      }
    }
  }
  for (const key of destroyed) {
    const r = Math.floor(key / 1000);
    const c = key % 1000;
    const was = grid[r][c];
    if (was.type === 'apartment' && was.owner != null) {
      state.inhabitants[was.owner] = Math.max(0, state.inhabitants[was.owner] - 1);
    }
    grid[r][c] = { type: 'empty', owner: null, role: null };
  }
}
