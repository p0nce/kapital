// ─── Game state ───────────────────────────────────────────────────────────────
const state = {
  turn: 0,
  wallets: [3, 3],                  // both players start with $3
  inhabitants: [3, 3],              // grows on apartment build, shrinks on destroy
  phase: 'IDLE',                    // 'IDLE' | 'BUILD_ANIM' | 'VOLLEY' | 'WIN'
  firstTurnPending: [false, true],  // P2's first turn still hasn't happened
  projectiles: [],                  // cannonballs in flight during VOLLEY
};

const ui = {
  selectedType: null,   // 'tower'|'platform'|'cannon'|'apartment'|null
  hoverCol: -1,
  mouseX: -1,           // last known mouse pos in canvas coords (for edge-scroll)
  mouseY: -1,
};

const winState = { winner: -1, replayBtn: { x: 0, y: 0, w: 0, h: 0 } };

// Button rects — written by render.js, read by input.js
const BTN       = { x: 0, y: 0, w: 0, h: 0 };
const buildBtns = [];

// ─── Camera ───────────────────────────────────────────────────────────────────
let cameraX       = 0;
let cameraY       = 0;
let cameraTargetX = 0;
let cameraTargetY = 0;
const CAMERA_SPEED = 0.12;
const CAMERA_MIN_Y = -SKY_BUFFER * CELL;       // pan up to reveal empty sky
const GROUND_BUFFER = 10 * CELL;               // pan down past the ground line
let CAMERA_MAX_X  = 0;
let CAMERA_MAX_Y  = 0;
let CAMERA_MAX    = 0;                         // legacy alias (animation.js)

function recalcCameraBounds() {
  CAMERA_MAX_X = Math.max(0, WORLD_W - GRID_W);
  CAMERA_MAX_Y = Math.max(CAMERA_MIN_Y, WORLD_H + GROUND_BUFFER - CH);
  CAMERA_MAX   = CAMERA_MAX_X;
  // Keep current camera inside new bounds
  cameraTargetX = Math.max(0, Math.min(CAMERA_MAX_X, cameraTargetX));
  cameraTargetY = Math.max(CAMERA_MIN_Y, Math.min(CAMERA_MAX_Y, cameraTargetY));
  cameraX = Math.max(0, Math.min(CAMERA_MAX_X, cameraX));
  cameraY = Math.max(CAMERA_MIN_Y, Math.min(CAMERA_MAX_Y, cameraY));
}
recalcCameraBounds();

// Edge-scroll: moving the mouse near the viewport edge pans the camera.
const EDGE_MARGIN  = 160;
const EDGE_SPEED   = 22;    // pixels of world per frame at the very edge
const EDGE_GRACE_MS = 100;  // hover time before edge-scroll engages
let edgeEnterTime = 0;      // timestamp when mouse first entered an edge zone

const KEY_SPEED = 22;       // pixels of world per frame while an arrow key is held
const keyState = { left: false, right: false, up: false, down: false };

function focusCameraOn(player) {
  const cityCenterX = cellX(ZONE_START[player]) + (P_COLS * CELL) / 2;
  cameraTargetX = Math.max(0, Math.min(CAMERA_MAX_X, cityCenterX - GRID_W / 2));
  cameraTargetY = Math.max(CAMERA_MIN_Y, Math.min(CAMERA_MAX_Y, 0));
}

function snapCameraOn(player) {
  focusCameraOn(player);
  cameraX = cameraTargetX;
  cameraY = cameraTargetY;
}

function edgeScrollStep() {
  const mx = ui.mouseX, my = ui.mouseY;
  if (mx < 0 || mx >= GRID_W || my < 0 || my >= CH) {
    edgeEnterTime = 0;
    return;
  }

  const inLeft  = mx < EDGE_MARGIN;
  const inRight = mx > GRID_W - EDGE_MARGIN;
  const inTop   = my < EDGE_MARGIN;
  const inBot   = my > CH - EDGE_MARGIN;
  if (!inLeft && !inRight && !inTop && !inBot) {
    edgeEnterTime = 0;
    return;
  }

  const now = performance.now();
  if (!edgeEnterTime) edgeEnterTime = now;
  if (now - edgeEnterTime < EDGE_GRACE_MS) return;

  // Horizontal
  if (inLeft) {
    const k = 1 - mx / EDGE_MARGIN;
    cameraTargetX = Math.max(0, cameraTargetX - EDGE_SPEED * k);
  } else if (inRight) {
    const k = 1 - (GRID_W - mx) / EDGE_MARGIN;
    cameraTargetX = Math.min(CAMERA_MAX_X, cameraTargetX + EDGE_SPEED * k);
  }

  // Vertical
  if (inTop) {
    const k = 1 - my / EDGE_MARGIN;
    cameraTargetY = Math.max(CAMERA_MIN_Y, cameraTargetY - EDGE_SPEED * k);
  } else if (inBot) {
    const k = 1 - (CH - my) / EDGE_MARGIN;
    cameraTargetY = Math.min(CAMERA_MAX_Y, cameraTargetY + EDGE_SPEED * k);
  }
}

function keyScrollStep() {
  if (keyState.left)  cameraTargetX = Math.max(0,             cameraTargetX - KEY_SPEED);
  if (keyState.right) cameraTargetX = Math.min(CAMERA_MAX_X,  cameraTargetX + KEY_SPEED);
  if (keyState.up)    cameraTargetY = Math.max(CAMERA_MIN_Y,  cameraTargetY - KEY_SPEED);
  if (keyState.down)  cameraTargetY = Math.min(CAMERA_MAX_Y,  cameraTargetY + KEY_SPEED);
}

function updateCamera() {
  edgeScrollStep();
  keyScrollStep();
  cameraX += (cameraTargetX - cameraX) * CAMERA_SPEED;
  cameraY += (cameraTargetY - cameraY) * CAMERA_SPEED;
  if (Math.abs(cameraTargetX - cameraX) < 0.5) cameraX = cameraTargetX;
  if (Math.abs(cameraTargetY - cameraY) < 0.5) cameraY = cameraTargetY;
}

// ─── Economy ──────────────────────────────────────────────────────────────────
// Income = $1 per apartment + $1 per level of height for each flag
// (flag at row r earns r-1). Tower height alone no longer earns anything.
function calcFlagIncome(player) {
  let flagIncome = 0;
  for (let row = 0; row < ROWS; row++)
    for (let col = 0; col < TOTAL_COLS; col++) {
      const cell = grid[row][col];
      if (cell.owner !== player || cell.type === 'empty' || cell.type === 'ground') continue;
      if (cell.type === 'flag') flagIncome += Math.max(0, row - 1);
    }
  return flagIncome;
}

function calcMaxInhabitants(player) {
  let n = 0;
  for (let row = 0; row < ROWS; row++)
    for (let col = 0; col < TOTAL_COLS; col++) {
      const cell = grid[row][col];
      if (cell.owner === player && cell.type === 'apartment') n += 1;
    }
  return n;
}

// $1 per inhabitant + flag height bonus. Inhabitants are clamped to the
// current apartment count so a destroyed apartment instantly reduces income.
function calcIncome(player) {
  const inh = Math.min(state.inhabitants[player], calcMaxInhabitants(player));
  return inh + calcFlagIncome(player);
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
function playerFlags(player) {
  const out = [];
  for (let r = 0; r < ROWS; r++)
    for (let c = 0; c < TOTAL_COLS; c++)
      if (grid[r][c].type === 'flag' && grid[r][c].owner === player) out.push({ r, c });
  return out;
}

function flagCost(player) {
  const n = playerFlags(player).length;
  return FLAG_COSTS[Math.min(n, FLAG_COSTS.length - 1)];
}

function costOf(type, player) {
  return type === 'flag' ? flagCost(player) : BLOCK_COSTS[type];
}

function canPlace(type, col, player) {
  if (state.phase !== 'IDLE') return false;
  if (state.wallets[player] < costOf(type, player)) return false;
  // Outside the native zone, placement is only allowed on top of something
  // the player already owns (i.e. a platform wing they extended).
  if (!inZone(col, player)) {
    const t = topOf(col);
    if (t < 0 || grid[t][col].owner !== player) return false;
  }

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
  if (type === 'cannon' && below === 'ground') return false;
  if (type === 'tower') {
    if (placeRow + 1 >= ROWS) return false;
    if (grid[placeRow + 1][col].type !== 'empty') return false;
  }
  return true;
}

function placeBlock(type, col, player) {
  if (!canPlace(type, col, player)) return false;
  state.wallets[player] -= costOf(type, player);
  if (type === 'apartment') state.inhabitants[player] += 1;

  // Flag limit: placing a flag while at MAX_FLAGS removes the excess first.
  if (type === 'flag') {
    const existing = playerFlags(player);
    while (existing.length >= MAX_FLAGS) {
      const f = existing.shift();
      grid[f.r][f.c] = { type: 'empty', owner: null, role: null };
    }
    fallPass();
  }

  let cells;
  if (type === 'platform') {
    const row = topOf(col) + 1;
    cells = [{ row, col, type, owner: player, role: 'base' }];
    // Wings may extend outside the player's zone — this is how a city
    // reaches past its original footprint.
    if (col - 1 >= 0 && grid[row][col - 1].type === 'empty') {
      cells.push({ row, col: col - 1, type, owner: player, role: 'left' });
    }
    if (col + 1 < TOTAL_COLS && grid[row][col + 1].type === 'empty') {
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
  const p = state.turn;
  if (state.firstTurnPending[p]) {
    state.firstTurnPending[p] = false;
  } else {
    state.wallets[p] = Math.min(WALLET_MAX, state.wallets[p] + calcIncome(p));
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
    inhabitants: [3, 3],
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
