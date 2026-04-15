// ─── Animation state ─────────────────────────────────────────────────────────
let animPhase = 'IDLE';   // 'IDLE' | 'BUILD' | 'VOLLEY'
let animStart = 0;
let animBuild = null;     // { cells, topRow }
let animFlash = null;     // { col, startTime }
let lastAnimTime = 0;     // used for dt during physics steps

const BUILD_DUR = 260;

// ─── Cannon angle (pure function of row/col/time) ────────────────────────────
// Triangular waveform between CANNON_MIN_DEG and CANNON_MAX_DEG.
function cannonAngle(row, col, now) {
  const phase = col * 0.73 + row * 1.31;
  const t     = now / 1000;
  const raw   = (t * CANNON_OMEGA + phase) / (Math.PI * 2); // normalise period to 1
  const p     = raw - Math.floor(raw);                      // fractional [0,1)
  const tri   = 1 - Math.abs(2 * p - 1);                    // triangular 0→1→0
  const deg   = CANNON_MIN_DEG + (CANNON_MAX_DEG - CANNON_MIN_DEG) * tri;
  return deg * Math.PI / 180;
}

// ─── Start helpers ────────────────────────────────────────────────────────────
function startBuildAnim(cells) {
  animBuild   = { cells, topRow: Math.max(...cells.map(c => c.row)) };
  animPhase   = 'BUILD';
  animStart   = performance.now();
  state.phase = 'BUILD_ANIM';
}

function startVolleyAnim() {
  animPhase    = 'VOLLEY';
  animStart    = performance.now();
  lastAnimTime = 0;
  state.phase  = 'VOLLEY';
}

// ─── Update (call every frame before draw) ───────────────────────────────────
function updateAnim(now) {
  if (animPhase === 'BUILD' && (now - animStart) / BUILD_DUR >= 1) {
    for (const c of animBuild.cells) setCell(c.row, c.col, c.type, c.owner, c.role);
    animBuild = null;
    animPhase = 'IDLE';
    state.phase = 'IDLE';
  } else if (animPhase === 'VOLLEY') {
    updateVolley(now);
  }
}

// Physics step for all projectiles in flight. Uses a few substeps for accuracy.
function updateVolley(now) {
  const frameDt = lastAnimTime ? Math.min((now - lastAnimTime) / 1000, 0.05) : 0.016;
  lastAnimTime = now;
  const SUBSTEPS = 4;
  const dt = frameDt / SUBSTEPS;

  // Camera follows the live projectiles (centroid X)
  let sumX = 0, alive = 0;
  for (const p of state.projectiles) {
    if (p.dead) continue;
    sumX += p.x; alive++;
  }
  if (alive > 0) {
    const avgX = sumX / alive;
    cameraTargetX = Math.max(0, Math.min(CAMERA_MAX, avgX - GRID_W / 2));
  }

  for (const p of state.projectiles) {
    if (p.dead) continue;
    for (let i = 0; i < SUBSTEPS && !p.dead; i++) {
      p.x  += p.vx * dt;
      p.y  += p.vy * dt;
      p.vy += BALL_GRAVITY * dt;

      if (p.x < 0 || p.x > WORLD_W || p.y > CH + 100) { p.dead = true; break; }

      const col = Math.floor(p.x / CELL);
      const row = ROWS - 1 - Math.floor(p.y / CELL);
      if (col < 0 || col >= TOTAL_COLS) { p.dead = true; break; }
      if (row >= ROWS || row < 0) continue;   // still in flight above/below valid rows
      const cell = grid[row][col];
      if (cell.type === 'ground') { p.dead = true; break; }
      if (cell.type !== 'empty' && cell.owner === p.owner) continue;  // pass through own blocks
      if (cell.type !== 'empty') {
        // Strength = sum of two uniform random variables (triangular
        // distribution). Range 1..4 with mean ~2.5. Limits how many blocks
        // the cascade can destroy (closest-first, BFS order).
        const strength = 1 + Math.floor((Math.random() + Math.random()) * 2);
        cascadeDestroy(row, col, strength);
        fallPass();
        animFlash = { col, startTime: now };
        p.dead = true;
        break;
      }
    }
  }
  state.projectiles = state.projectiles.filter(p => !p.dead);
  if (state.projectiles.length === 0) {
    animPhase = 'IDLE';
    lastAnimTime = 0;
    finishTurnTransition();
  }
}

// ─── Draw (call after grid is drawn) ─────────────────────────────────────────
function drawAnim(now) {
  if (animPhase === 'BUILD' && animBuild) {
    const ease    = 1 - Math.pow(1 - Math.min((now - animStart) / BUILD_DUR, 1), 3);
    const offsetY = -(1 - ease) * 3 * CELL;
    ctx.save();
    ctx.translate(0, offsetY);
    for (const c of animBuild.cells) drawBlock(c.col, c.row, c.type, c.owner, c.role);
    ctx.restore();
  }

  if (animPhase === 'VOLLEY') {
    for (const p of state.projectiles) {
      if (p.dead) continue;
      const r = 4;
      ctx.save();
      ctx.shadowColor = '#ffffff';
      ctx.shadowBlur  = 6;
      ctx.fillStyle = '#050505';
      ctx.beginPath(); ctx.arc(p.x, p.y, r, 0, Math.PI * 2); ctx.fill();
      ctx.fillStyle = '#444444';
      ctx.beginPath(); ctx.arc(p.x - 1, p.y - 1, r * 0.45, 0, Math.PI * 2); ctx.fill();
      ctx.restore();
    }
  }

  if (animFlash) {
    const elapsed = now - animFlash.startTime;
    if (elapsed < 280) {
      ctx.fillStyle = `rgba(220,220,220,${(1 - elapsed / 280) * 0.65})`;
      ctx.fillRect(cellX(animFlash.col), 0, CELL, CH);
    } else {
      animFlash = null;
    }
  }
}
