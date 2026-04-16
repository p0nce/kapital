// ─── Layout ───────────────────────────────────────────────────────────────────
const CELL       = 36;
const P_COLS     = 11;                      // 2 extra columns on each side
const GAP_COLS   = 20;                       // wide gap between cities
const BORDER_COLS = 20;                      // extra ground tiles outside each player's zone
const TOTAL_COLS = BORDER_COLS * 2 + P_COLS * 2 + GAP_COLS;    // 82
const ROWS       = 22;
const SKY_BUFFER = 10;                       // vertical pan room above the grid (tiles)
const SKY_LIMIT  = 18;
const SIDE_W     = 192;

// World: fixed size determined by the grid.
const WORLD_W    = TOTAL_COLS * CELL;
const WORLD_H    = ROWS * CELL;

// Viewport: dynamic — follows the browser window. The playfield viewport
// (GRID_W × CH) is whatever the window gives us minus the side panel.
// All of CW/CH/GRID_W/VIEW_COLS are recomputed on window resize.
let CW        = 0;
let CH        = 0;
let GRID_W    = 0;
let VIEW_COLS = 0;

// Player zone column bounds — shifted right by BORDER_COLS
const P1_START = BORDER_COLS;                          // 20
const P1_END   = BORDER_COLS + P_COLS - 1;             // 30
const P2_START = BORDER_COLS + P_COLS + GAP_COLS;      // 51
const P2_END   = BORDER_COLS + P_COLS * 2 + GAP_COLS - 1; // 61

const ZONE_START = [P1_START, P2_START];
const ZONE_END   = [P1_END,   P2_END];

// ─── Player config ────────────────────────────────────────────────────────────
const PLAYER_NAMES  = ['PLAYER 1', 'PLAYER 2'];
const PLAYER_COLORS = ['#cccccc', '#cccccc'];

// ─── Block config ─────────────────────────────────────────────────────────────
const MAX_FLAGS  = 2;
const WALLET_MAX = 20;
// Cost to place a flag, indexed by the player's current flag count.
// At MAX_FLAGS, placing one still works (it replaces the oldest).
const FLAG_COSTS = [0, 1, 3];
const BLOCK_COSTS = { tower: 2, platform: 3, flag: 1, cannon: 4, apartment: 2 };
const BUILD_TYPES = [
  { type: 'flag',      label: 'FLAG',      cost: 1 },
  { type: 'tower',     label: 'TOWER',     cost: 2 },
  { type: 'apartment', label: 'APARTMENT', cost: 2 },
  { type: 'platform',  label: 'PLATFORM',  cost: 3 },
  { type: 'cannon',    label: 'CANNON',    cost: 4 },
];

// ─── Canvas ───────────────────────────────────────────────────────────────────
const canvas = document.getElementById('c');
const ctx = canvas.getContext('2d');

function resizeCanvas() {
  CW        = Math.max(320, Math.floor(window.innerWidth));
  CH        = Math.max(240, Math.floor(window.innerHeight));
  GRID_W    = Math.max(CELL, CW - SIDE_W);
  VIEW_COLS = Math.floor(GRID_W / CELL);
  canvas.width  = CW;
  canvas.height = CH;
  if (typeof recalcCameraBounds === 'function') recalcCameraBounds();
}
resizeCanvas();
window.addEventListener('resize', resizeCanvas);

function cellX(col) { return col * CELL; }
function cellY(row) { return (ROWS - 1 - row) * CELL; }

// ─── Cannon / ballistics ──────────────────────────────────────────────────────
const CANNON_MIN_DEG = 0;
const CANNON_MAX_DEG = 60;
const CANNON_MID_DEG = (CANNON_MIN_DEG + CANNON_MAX_DEG) / 2;  // 30
const CANNON_AMP_DEG = (CANNON_MAX_DEG - CANNON_MIN_DEG) / 2;  // 30
const CANNON_OMEGA   = 1.12;        // radians/sec sweep rate (30% slower)
const BARREL_LEN     = 30;          // pixels from pivot to muzzle
const CANNON_PIVOT_Y = 12;          // distance from cell bottom to pivot (3 tile-px lower than 26 at 8-px tile scale)

// Ballistic range @ 45°: R = v²/g.
// Target: ~18 tiles (648 px) max range, slow visible flight (~2 s).
// v = 475 px/s, g = 348 px/s² → R ≈ 648 px, time of flight ≈ 1.93 s.
const BALL_SPEED   = 522;   // +10% energy
const BALL_GRAVITY = 348;
