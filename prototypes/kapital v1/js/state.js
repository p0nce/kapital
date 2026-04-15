// ─── Game state ───────────────────────────────────────────────────────────────
const state = {
  turn: 0,
  wallets: [3, 3],                  // both players start with $3
  phase: 'IDLE',                    // 'IDLE' | 'BUILD_ANIM' | 'VOLLEY' | 'WIN'
  firstTurnPending: [false, true],  // P2's first turn still hasn't happened
  projectiles: [],                  // cannonballs in flight during VOLLEY
};

const ui = {
  selectedType: null,   // 'tower'|'platform'|'cannon'|'apartment'|null
  hoverCol: -1,
};

const winState = { winner: -1, replayBtn: { x: 0, y: 0, w: 0, h: 0 } };

// Button rects — written by render.js, read by input.js
const BTN       = { x: 0, y: 0, w: 0, h: 0 };
const buildBtns = [];

// ─── Camera ───────────────────────────────────────────────────────────────────
let cameraX       = 0;
let cameraTargetX = 0;
const CAMERA_SPEED = 0.12;
const CAMERA_MAX   = WORLD_W - GRID_W;

function focusCameraOn(player) {
  const cityCenterX = cellX(ZONE_START[player]) + (P_COLS * CELL) / 2;
  cameraTargetX = Math.max(0, Math.min(CAMERA_MAX, cityCenterX - GRID_W / 2));
}

function snapCameraOn(player) {
  focusCameraOn(player);
  cameraX = cameraTargetX;
}

function updateCamera() {
  cameraX += (cameraTargetX - cameraX) * CAMERA_SPEED;
  if (Math.abs(cameraTargetX - cameraX) < 0.5) cameraX = cameraTargetX;
}

// ─── Economy ──────────────────────────────────────────────────────────────────
// Income = $1 per apartment + $1 per level of height for each flag
// (flag at row r earns r-1). Tower height alone no longer earns anything.
function calcIncome(player) {
  let apartments = 0;
  let flagIncome = 0;
  for (let row = 0; row < ROWS; row++)
    for (let col = 0; col < TOTAL_COLS; col++) {
      const cell = grid[row][col];
      if (cell.owner !== player || cell.type === 'empty' || cell.type === 'ground') continue;
      if (cell.type === 'apartment') apartments += 1;
      if (cell.type === 'flag')      flagIncome += Math.max(0, row - 1);
    }
  return apartments + flagIncome;
}

// ─── Volley: fire every cannon owned by the given player ────────────────────
function spawnVolley(player) {
  const now = performance.now();
  const projectiles = [];
  for (let row = 0; row < ROWS; row++) {
    for (let col = 0; col < TOTAL_COLS; col++) {
      const cell = grid[row][col];
      if (cell.type !== 'cannon' || cell.owner !== player) continue;
      const angle = cannonAngle(row, col, now);
      const dir   = player === 0 ? 1 : -1;
      // Pivot in world coordinates
      const cx = cellX(col) + CELL / 2;
      const cy = cellY(row) + CELL - CANNON_PIVOT_Y;
      // Launch at the muzzle (end of barrel)
      const lx = cx + dir * BARREL_LEN * Math.cos(angle);
      const ly = cy - BARREL_LEN * Math.sin(angle);
      const vx = dir * BALL_SPEED * Math.cos(angle);
      const vy = -BALL_SPEED * Math.sin(angle);
      projectiles.push({ x: lx, y: ly, vx, vy, owner: player, dead: false });
    }
  }
  return projectiles;
}

// ─── Placement ────────────────────────────────────────────────────────────────
function canPlace(type, col, player) {
  if (state.phase !== 'IDLE') return false;
  if (state.wallets[player] < BLOCK_COSTS[type]) return false;
  if (!inZone(col, player)) return false;

  if (type === 'platform') {
    // Only the base cell (centre column) needs to be empty and supported.
    // Wings may overlap existing blocks — they are simply omitted in that case.
    // Platforms can only rest on tower / apartment / another platform — not the ground.
    const row = topOf(col) + 1;
    if (row >= ROWS) return false;
    if (grid[row][col].type !== 'empty') return false;
    const support = grid[row - 1]?.[col];
    if (!support) return false;
    if (support.type !== 'tower' && support.type !== 'apartment' && support.type !== 'platform')
      return false;
    return true;
  }

  const top = topOf(col);
  if (top < 0) return false;
  const placeRow = top + 1;
  if (placeRow >= ROWS) return false;
  if (grid[placeRow][col].type !== 'empty') return false;
  // Terminal blocks — nothing stacks directly on top of them
  const below = grid[top][col].type;
  if (below === 'cannon' || below === 'flag') return false;
  if (type === 'tower') {
    if (placeRow + 1 >= ROWS) return false;
    if (grid[placeRow + 1][col].type !== 'empty') return false;
  }
  return true;
}

function placeBlock(type, col, player) {
  if (!canPlace(type, col, player)) return false;
  state.wallets[player] -= BLOCK_COSTS[type];

  let cells;
  if (type === 'platform') {
    const row = topOf(col) + 1;
    cells = [{ row, col, type, owner: player, role: 'base' }];
    // Left wing if inside player's zone and the target cell is empty
    if (col - 1 >= ZONE_START[player] && grid[row][col - 1].type === 'empty') {
      cells.push({ row, col: col - 1, type, owner: player, role: 'left' });
    }
    // Right wing
    if (col + 1 <= ZONE_END[player] && grid[row][col + 1].type === 'empty') {
      cells.push({ row, col: col + 1, type, owner: player, role: 'right' });
    }
  } else if (type === 'tower') {
    const row = topOf(col) + 1;
    cells = [
      { row: row,     col, type, owner: player },
      { row: row + 1, col, type, owner: player },
    ];
  } else {
    const row = topOf(col) + 1;
    cells = [{ row, col, type, owner: player }];
  }
  startBuildAnim(cells);
  return true;
}

// ─── Turn flow ────────────────────────────────────────────────────────────────
// Clicking "End Turn" first fires every cannon the current player owns; once
// all projectiles resolve, finishTurnTransition() flips the turn.
function endTurn() {
  if (state.phase !== 'IDLE') return;
  const projectiles = spawnVolley(state.turn);
  if (projectiles.length > 0) {
    state.projectiles = projectiles;
    startVolleyAnim();
  } else {
    finishTurnTransition();
  }
}

function finishTurnTransition() {
  state.turn = 1 - state.turn;
  if (state.firstTurnPending[state.turn]) {
    state.firstTurnPending[state.turn] = false;
  } else {
    state.wallets[state.turn] += calcIncome(state.turn);
  }
  focusCameraOn(state.turn);
  state.phase = 'IDLE';
  checkWin();
}

// Only the player whose turn is starting can win — gives the opponent one
// full turn to knock down the offending block before victory is declared.
function checkWin() {
  const p = state.turn;
  for (let col = ZONE_START[p]; col <= ZONE_END[p]; col++)
    if (topOf(col) > SKY_LIMIT) {
      winState.winner = p;
      state.phase = 'WIN';
      return;
    }
}

function resetGame() {
  for (let r = 0; r < ROWS; r++)
    for (let c = 0; c < TOTAL_COLS; c++)
      grid[r][c] = { type: 'empty', owner: null };
  initGrid();
  Object.assign(state, {
    turn: 0,
    wallets: [3, 3],
    phase: 'IDLE',
    firstTurnPending: [false, true],
    projectiles: [],
  });
  winState.winner = -1;
  Object.assign(ui, { selectedType: null });
  animPhase = 'IDLE';
  animBuild = animFire = animFlash = null;
  snapCameraOn(0);
}
