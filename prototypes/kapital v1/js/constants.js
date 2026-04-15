// ─── Layout ───────────────────────────────────────────────────────────────────
const CELL       = 36;
const P_COLS     = 11;                      // 2 extra columns on each side
const GAP_COLS   = 20;                       // wide gap between cities
const TOTAL_COLS = P_COLS * 2 + GAP_COLS;    // 42
const ROWS       = 22;
const SKY_LIMIT  = 18;
const SIDE_W     = 200;

// Viewport: only part of the world is visible at once. Camera pans.
const VIEW_COLS  = 14;
const GRID_W     = VIEW_COLS * CELL;         // 504 visible grid width
const WORLD_W    = TOTAL_COLS * CELL;        // 1224 total world width

const CW         = GRID_W + SIDE_W;          // 704
const CH         = ROWS * CELL;              // 792

// Player zone column bounds
const P1_START = 0;
const P1_END   = P_COLS - 1;           // 6
const P2_START = P_COLS + GAP_COLS;    // 11
const P2_END   = TOTAL_COLS - 1;       // 17

const ZONE_START = [P1_START, P2_START];
const ZONE_END   = [P1_END,   P2_END];

// ─── Player config ────────────────────────────────────────────────────────────
const PLAYER_NAMES  = ['PLAYER 1', 'PLAYER 2'];
const PLAYER_COLORS = ['#cccccc', '#cccccc'];

// ─── Block config ─────────────────────────────────────────────────────────────
const BLOCK_COSTS = { tower: 2, platform: 2, flag: 2, cannon: 4, apartment: 3 };
const BUILD_TYPES = [
  { type: 'tower',     label: 'TOWER',     cost: 2 },
  { type: 'platform',  label: 'PLATFORM',  cost: 2 },
  { type: 'flag',      label: 'FLAG',      cost: 2 },
  { type: 'apartment', label: 'APARTMENT', cost: 3 },
  { type: 'cannon',    label: 'CANNON',    cost: 4 },
];

// ─── Canvas ───────────────────────────────────────────────────────────────────
const canvas = document.getElementById('c');
canvas.width  = CW;
canvas.height = CH;
const ctx = canvas.getContext('2d');

function cellX(col) { return col * CELL; }
function cellY(row) { return (ROWS - 1 - row) * CELL; }

// ─── Cannon / ballistics ──────────────────────────────────────────────────────
const CANNON_MIN_DEG = 0;
const CANNON_MAX_DEG = 60;
const CANNON_MID_DEG = (CANNON_MIN_DEG + CANNON_MAX_DEG) / 2;  // 30
const CANNON_AMP_DEG = (CANNON_MAX_DEG - CANNON_MIN_DEG) / 2;  // 30
const CANNON_OMEGA   = 1.12;        // radians/sec sweep rate (30% slower)
const BARREL_LEN     = 26;          // pixels from pivot to muzzle
const CANNON_PIVOT_Y = 28;          // distance from cell bottom to pivot (near apex of triangular base)

// Ballistic range @ 45°: R = v²/g.
// Target: ~18 tiles (648 px) max range, slow visible flight (~2 s).
// v = 475 px/s, g = 348 px/s² → R ≈ 648 px, time of flight ≈ 1.93 s.
const BALL_SPEED   = 475;
const BALL_GRAVITY = 348;
