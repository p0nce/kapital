// ─── Block colours ────────────────────────────────────────────────────────────
// Greyscale palette — players are not distinguished by colour.
const GREY = (base, hi, shadow) => [{ base, hi, shadow }, { base, hi, shadow }];
const BLOCK_COLORS = {
  ground:    { base: '#1c1c1c', hi: '#2a2a2a', shadow: '#0e0e0e' },
  tower:     GREY('#3a3a3a', '#555555', '#1a1a1a'),
  platform:  GREY('#323232', '#4a4a4a', '#161616'),
  cannon:    GREY('#222222', '#333333', '#0c0c0c'),
  apartment: GREY('#444444', '#606060', '#1e1e1e'),
};

function getColors(type, owner) {
  const c = BLOCK_COLORS[type];
  return Array.isArray(c) ? c[owner ?? 0] : c;
}

// ─── Block drawing ────────────────────────────────────────────────────────────
function drawBlock(col, row, type, owner, role) {
  const x = cellX(col), y = cellY(row), s = CELL;

  if (type === 'apartment') { drawApartment(x, y, s); return; }
  if (type === 'tower')     { drawTower(x, y, s, owner); return; }
  if (type === 'platform')  {
    const r = role || grid[row]?.[col]?.role || 'base';
    drawPlatform(x, y, s, r, owner);
    return;
  }
  if (type === 'cannon')    { drawCannon(x, y, s, owner, row, col); return; }
  if (type === 'flag')      { drawFlag(x, y, s, row, col);          return; }

  const { base, hi, shadow } = getColors(type, owner);
  ctx.fillStyle = base;   ctx.fillRect(x + 1, y + 1, s - 2, s - 2);
  ctx.fillStyle = hi;     ctx.fillRect(x + 1, y + 1, s - 2, 3);
                          ctx.fillRect(x + 1, y + 1, 3, s - 2);
  ctx.fillStyle = shadow; ctx.fillRect(x + 1, y + s - 4, s - 2, 3);
                          ctx.fillRect(x + s - 4, y + 1, 3, s - 2);
}

// Player-tinted brick tower. Fills edge-to-edge and uses a world-aligned brick
// pattern so stacked tower cells merge seamlessly with no visible separation.
const TOWER_PALETTE = [
  { brick: '#555555', hi: '#707070', dark: '#2a2a2a', mortar: '#121212' },
  { brick: '#555555', hi: '#707070', dark: '#2a2a2a', mortar: '#121212' },
];

// Fill the rectangle (x,y,w,h) with a world-aligned brick pattern.
function drawBrickBody(x, y, w, h, palette) {
  const brickH = 6;
  ctx.fillStyle = palette.brick;
  ctx.fillRect(x, y, w, h);

  ctx.fillStyle = palette.mortar;
  const firstLine = Math.ceil(y / brickH) * brickH;
  for (let by = firstLine; by < y + h; by += brickH) {
    ctx.fillRect(x, by, w, 1);
  }

  for (let by = firstLine - brickH; by < y + h; by += brickH) {
    const absRow = Math.floor(by / brickH);
    const offset = (absRow % 2) * 6;
    for (let bx = x + offset; bx < x + w; bx += 12) {
      const top = Math.max(by + 1, y);
      const bot = Math.min(by + brickH, y + h);
      if (bot > top) ctx.fillRect(bx, top, 1, bot - top);
    }
  }
}

function drawTower(x, y, s, owner) {
  const p = TOWER_PALETTE[owner ?? 0];
  drawBrickBody(x, y, s, s, p);

  // Left edge highlight / right edge shadow for volume
  ctx.fillStyle = p.hi;   ctx.fillRect(x, y, 1, s);
  ctx.fillStyle = p.dark; ctx.fillRect(x + s - 1, y, 1, s);

  // Window — same shape as apartment window but dark grey
  const wW = 10, wH = 10;
  const wx = x + (s - wW) / 2;
  const wy = y + (s - wH) / 2 - 1;
  // Frame
  ctx.fillStyle = '#050505';
  ctx.fillRect(wx - 1, wy - 1, wW + 2, wH + 2);
  // Dark pane
  ctx.fillStyle = '#181818';
  ctx.fillRect(wx, wy, wW, wH);
  // Cross bars
  ctx.fillStyle = '#303030';
  ctx.fillRect(wx + wW / 2 - 0.5, wy, 1, wH);
  ctx.fillRect(wx, wy + wH / 2 - 0.5, wW, 1);
  // Subtle highlight pixel
  ctx.fillStyle = '#383838';
  ctx.fillRect(wx + 1, wy + 1, 2, 2);
  // Sill
  ctx.fillStyle = '#0a0a0a';
  ctx.fillRect(wx - 2, wy + wH, wW + 4, 2);
}

// Platform is a \B/ shape spanning 3 cells:
//   role 'base'  — full brick square in the centre column
//   role 'left'  — triangular ramp "\" at col-1 (brick in bottom-right triangle)
//   role 'right' — triangular ramp "/" at col+1 (brick in bottom-left triangle)
function drawPlatform(x, y, s, role, owner) {
  const p = TOWER_PALETTE[owner ?? 0];

  if (role === 'base') {
    drawBrickBody(x, y, s, s, p);
    ctx.fillStyle = p.hi;   ctx.fillRect(x, y, 1, s);
    ctx.fillStyle = p.dark; ctx.fillRect(x + s - 1, y, 1, s);
    // Top highlight to read as the platform "capstone"
    ctx.fillStyle = p.hi; ctx.fillRect(x, y, s, 1);

    // Two thick dark-grey sustaining pillars — drawn over the brick body
    // and extending below the cell so they visually anchor the platform.
    const pillarW  = 6;
    const pillarL  = x;
    const pillarR  = x + s - pillarW;
    const pillarY  = y + 4;
    const pillarH  = s + 14;     // reaches 14px past the cell's bottom edge
    ctx.fillStyle = '#1a1a1a';
    ctx.fillRect(pillarL, pillarY, pillarW, pillarH);
    ctx.fillRect(pillarR, pillarY, pillarW, pillarH);
    // Left-edge highlight on each pillar for volume
    ctx.fillStyle = '#333333';
    ctx.fillRect(pillarL,     pillarY, 1, pillarH);
    ctx.fillRect(pillarR,     pillarY, 1, pillarH);
    // Right-edge shadow
    ctx.fillStyle = '#0a0a0a';
    ctx.fillRect(pillarL + pillarW - 1, pillarY, 1, pillarH);
    ctx.fillRect(pillarR + pillarW - 1, pillarY, 1, pillarH);
    return;
  }

  ctx.save();
  ctx.beginPath();
  if (role === 'left') {
    // Brick fills the upper-right triangle (top full, outer-bottom corner empty)
    // so the visible diagonal edge reads as a "\" going from top-left to bottom-right.
    ctx.moveTo(x,         y);
    ctx.lineTo(x + s,     y);
    ctx.lineTo(x + s,     y + s);
    ctx.closePath();
  } else {
    // right: brick fills the upper-left triangle, diagonal "/" from top-right to bottom-left.
    ctx.moveTo(x,         y);
    ctx.lineTo(x + s,     y);
    ctx.lineTo(x,         y + s);
    ctx.closePath();
  }
  ctx.clip();
  drawBrickBody(x, y, s, s, p);
  ctx.restore();

  // Highlight the diagonal edge so the ramp reads clearly
  ctx.strokeStyle = p.hi;
  ctx.lineWidth   = 2;
  ctx.beginPath();
  if (role === 'left') {
    ctx.moveTo(x,     y);
    ctx.lineTo(x + s, y + s);
  } else {
    ctx.moveTo(x + s, y);
    ctx.lineTo(x,     y + s);
  }
  ctx.stroke();
  ctx.lineWidth = 1;
}

// Brick apartment with one lit window + small chimney extending above the tile.
function drawApartment(x, y, s) {
  // Brick body (greyscale stone)
  const brick     = '#5a5a5a';
  const brickDark = '#2a2a2a';
  const mortar    = '#141414';

  ctx.fillStyle = brick;
  ctx.fillRect(x + 1, y + 1, s - 2, s - 2);

  // Horizontal mortar lines
  ctx.fillStyle = mortar;
  const brickH = 5;
  for (let by = y + brickH; by < y + s - 1; by += brickH) {
    ctx.fillRect(x + 1, by, s - 2, 1);
  }
  // Vertical mortar lines (staggered)
  for (let row = 0; row * brickH < s - 2; row++) {
    const oy = y + row * brickH;
    const offset = (row % 2) * 6;
    for (let bx = x + 6 + offset; bx < x + s - 1; bx += 12) {
      ctx.fillRect(bx, oy, 1, brickH);
    }
  }

  // Subtle highlight top row
  ctx.fillStyle = '#7a7a7a';
  ctx.fillRect(x + 1, y + 1, s - 2, 1);
  // Shadow right edge
  ctx.fillStyle = brickDark;
  ctx.fillRect(x + s - 3, y + 1, 2, s - 2);
  ctx.fillRect(x + 1, y + s - 3, s - 2, 2);

  // Window (centred, slightly upper half)
  const wW = 10, wH = 10;
  const wx = x + (s - wW) / 2;
  const wy = y + 10;
  // Frame
  ctx.fillStyle = '#0a0a0a';
  ctx.fillRect(wx - 1, wy - 1, wW + 2, wH + 2);

  // Animated lit pane: sinusoidal brightness, per-apartment phase so no two
  // windows pulse in sync. Wider range (less grey) and 2× faster.
  const phase = x * 0.031 + y * 0.047;
  const fluc  = 0.5 + 0.5 * Math.sin(currentNow * 0.0018 + phase); // 0..1
  const v     = Math.round(215 + 40 * fluc);                      
  ctx.fillStyle = `rgb(${v},${v},${v})`;
  ctx.fillRect(wx, wy, wW, wH);

  // Cross bars
  ctx.fillStyle = '#404040';
  ctx.fillRect(wx + wW / 2 - 0.5, wy, 1, wH);
  ctx.fillRect(wx, wy + wH / 2 - 0.5, wW, 1);

  // Highlight — tracks the pane brightness so it glows too
  const vh = Math.min(255, v + 40);
  ctx.fillStyle = `rgb(${vh},${vh},${vh})`;
  ctx.fillRect(wx + 1, wy + 1, 2, 2);

  // Sill
  ctx.fillStyle = '#1a1a1a';
  ctx.fillRect(wx - 2, wy + wH, wW + 4, 2);

  // Chimney — extends above the tile
  const chX = x + s - 10;
  const chW = 6;
  const chTop = y - 6;
  ctx.fillStyle = '#2a2a2a';
  ctx.fillRect(chX, chTop, chW, 8);
  ctx.fillStyle = '#4a4a4a';
  ctx.fillRect(chX + 1, chTop + 1, chW - 2, 6);
  // Chimney cap
  ctx.fillStyle = '#141414';
  ctx.fillRect(chX - 1, chTop, chW + 2, 2);

  // Smoke puffs
  ctx.fillStyle = 'rgba(180,180,180,0.35)';
  ctx.beginPath(); ctx.arc(chX + chW / 2,     chTop - 3, 2, 0, Math.PI * 2); ctx.fill();
  ctx.beginPath(); ctx.arc(chX + chW / 2 - 2, chTop - 6, 1.5, 0, Math.PI * 2); ctx.fill();
  ctx.fillStyle = 'rgba(200,200,200,0.2)';
  ctx.beginPath(); ctx.arc(chX + chW / 2 + 1, chTop - 9, 2, 0, Math.PI * 2); ctx.fill();
}

function drawFlag(x, y, s, row, col) {
  // Pole — thin vertical bar, just left of centre
  const poleX   = x + s / 2 - 1;
  const poleTop = y + 3;
  const poleBot = y + s - 2;
  ctx.fillStyle = '#1a1a1a';
  ctx.fillRect(poleX, poleTop, 2, poleBot - poleTop);
  ctx.fillStyle = '#4a4a4a';
  ctx.fillRect(poleX, poleTop, 1, poleBot - poleTop);
  // Finial at the top
  ctx.fillStyle = '#666';
  ctx.fillRect(poleX - 1, poleTop - 1, 4, 2);

  // Waving triangular flag
  const phase = col * 0.6 + row * 0.4;
  const wave  = Math.sin(currentNow * 0.005 + phase) * 2;
  const baseX = poleX + 2;
  const topY  = y + 5;
  const botY  = y + 15;
  const tipX  = baseX + 14;

  ctx.fillStyle = '#888888';
  ctx.beginPath();
  ctx.moveTo(baseX,        topY);
  ctx.lineTo(tipX + wave,  (topY + botY) / 2 + wave * 0.4);
  ctx.lineTo(baseX,        botY);
  ctx.closePath();
  ctx.fill();
  // Shadow on the under-fold
  ctx.fillStyle = '#555555';
  ctx.beginPath();
  ctx.moveTo(baseX,        (topY + botY) / 2);
  ctx.lineTo(tipX + wave,  (topY + botY) / 2 + wave * 0.4);
  ctx.lineTo(baseX,        botY);
  ctx.closePath();
  ctx.fill();
  // Outline
  ctx.strokeStyle = '#2a2a2a';
  ctx.lineWidth = 1;
  ctx.beginPath();
  ctx.moveTo(baseX,        topY);
  ctx.lineTo(tipX + wave,  (topY + botY) / 2 + wave * 0.4);
  ctx.lineTo(baseX,        botY);
  ctx.stroke();

  // Tiny base rock at the pole foot
  ctx.fillStyle = '#333';
  ctx.fillRect(poleX - 3, y + s - 3, 8, 2);
  ctx.fillStyle = '#1a1a1a';
  ctx.fillRect(poleX - 3, y + s - 1, 8, 1);
}

function drawCannon(x, y, s, owner, row, col) {
  const cx = x + s / 2;
  const apexY = y + s - CANNON_PIVOT_Y;   // apex of the triangular base

  // Triangular base — stone wedge pointing up, filling the cell
  ctx.fillStyle = '#3a3a3a';
  ctx.beginPath();
  ctx.moveTo(x + 1,      y + s - 1);    // bottom-left
  ctx.lineTo(x + s - 1,  y + s - 1);    // bottom-right
  ctx.lineTo(cx,         apexY);        // apex
  ctx.closePath();
  ctx.fill();

  // Left-face highlight
  ctx.strokeStyle = '#5a5a5a';
  ctx.lineWidth = 1;
  ctx.beginPath();
  ctx.moveTo(x + 1, y + s - 1);
  ctx.lineTo(cx,    apexY);
  ctx.stroke();

  // Right-face shadow
  ctx.fillStyle = '#1e1e1e';
  ctx.beginPath();
  ctx.moveTo(cx,         apexY);
  ctx.lineTo(x + s - 1,  y + s - 1);
  ctx.lineTo(cx,         y + s - 1);
  ctx.closePath();
  ctx.fill();

  // Bottom edge shadow
  ctx.fillStyle = '#0a0a0a';
  ctx.fillRect(x + 1, y + s - 2, s - 2, 1);

  // Barrel — animated, extending beyond the cell
  const angle = cannonAngle(row, col, currentNow);
  const dir   = owner === 0 ? 1 : -1;
  const px    = cx, py = apexY;
  const ex    = px + dir * BARREL_LEN * Math.cos(angle);
  const ey    = py - BARREL_LEN * Math.sin(angle);

  ctx.lineCap = 'round';
  ctx.strokeStyle = '#121212';
  ctx.lineWidth = 8;
  ctx.beginPath(); ctx.moveTo(px, py); ctx.lineTo(ex, ey); ctx.stroke();
  ctx.strokeStyle = '#3a3a3a';
  ctx.lineWidth = 3;
  ctx.beginPath(); ctx.moveTo(px, py); ctx.lineTo(ex, ey); ctx.stroke();
  ctx.lineCap = 'butt';

  // Muzzle
  ctx.fillStyle = '#050505';
  ctx.beginPath(); ctx.arc(ex, ey, 4, 0, Math.PI * 2); ctx.fill();
  ctx.fillStyle = '#2a2a2a';
  ctx.beginPath(); ctx.arc(ex, ey, 1.5, 0, Math.PI * 2); ctx.fill();

  // Pivot hub
  ctx.fillStyle = '#1a1a1a';
  ctx.beginPath(); ctx.arc(px, py, 3, 0, Math.PI * 2); ctx.fill();
}

function drawGrid() {
  // First pass: every block except cannons
  for (let row = 0; row < ROWS; row++)
    for (let col = 0; col < TOTAL_COLS; col++) {
      const { type, owner, role } = grid[row][col];
      if (type === 'empty' || type === 'cannon') continue;
      drawBlock(col, row, type, owner, role);
    }
  // Second pass: cannons on top so their barrels overlap neighbours freely
  for (let row = 0; row < ROWS; row++)
    for (let col = 0; col < TOTAL_COLS; col++) {
      const cell = grid[row][col];
      if (cell.type === 'cannon') drawBlock(col, row, 'cannon', cell.owner, null);
    }
}

// ─── Background ───────────────────────────────────────────────────────────────
function drawBackground() {
  const grad = ctx.createLinearGradient(0, 0, 0, CH);
  grad.addColorStop(0, '#030303'); grad.addColorStop(0.6, '#080808'); grad.addColorStop(1, '#111111');
  ctx.fillStyle = grad;
  ctx.fillRect(0, 0, WORLD_W, CH);

  drawGrassGround();

  const skyY = cellY(SKY_LIMIT);
  ctx.save();
  ctx.shadowColor = '#dddddd'; ctx.shadowBlur = 12;
  ctx.strokeStyle = '#dddddd'; ctx.lineWidth = 2; ctx.setLineDash([6, 4]);
  ctx.beginPath(); ctx.moveTo(0, skyY); ctx.lineTo(WORLD_W, skyY); ctx.stroke();
  ctx.setLineDash([]);
  ctx.restore();
}

function drawGrassGround() {
  const gy = cellY(0);
  const s  = CELL;

  // Dirt body (bottom 2/3)
  ctx.fillStyle = '#2a2a2a';
  ctx.fillRect(0, gy + 6, WORLD_W, s - 6);

  // Dirt speckles
  ctx.fillStyle = '#444444';
  for (let i = 0; i < WORLD_W; i += 7) {
    ctx.fillRect(i, gy + 12, 2, 2);
    ctx.fillRect(i + 3, gy + 22, 2, 2);
  }
  ctx.fillStyle = '#141414';
  for (let i = 0; i < GRID_W; i += 9) {
    ctx.fillRect(i + 1, gy + 16, 2, 2);
    ctx.fillRect(i + 5, gy + 26, 2, 2);
  }

  // Grass top band
  ctx.fillStyle = '#555555';
  ctx.fillRect(0, gy, WORLD_W, 8);
  // Darker bottom edge
  ctx.fillStyle = '#333333';
  ctx.fillRect(0, gy + 6, WORLD_W, 2);
  // Highlight row
  ctx.fillStyle = '#777777';
  ctx.fillRect(0, gy, WORLD_W, 2);

  // Grass blades poking up
  ctx.fillStyle = '#777777';
  for (let x = 0; x < WORLD_W; x += 5) {
    const h = 1 + ((x * 37) % 3);
    ctx.fillRect(x, gy - h, 1, h);
  }
  // Brighter blades
  ctx.fillStyle = '#aaaaaa';
  for (let x = 2; x < WORLD_W; x += 11) {
    ctx.fillRect(x, gy - 2, 1, 2);
  }
}

function drawSilhouettes() {
  ctx.fillStyle = '#050505';
  ctx.fillRect(30, cellY(8), 18, 8 * CELL);
  ctx.fillRect(24, cellY(10), 30, 10 * CELL);
  ctx.beginPath(); ctx.moveTo(33, cellY(8)); ctx.lineTo(39, cellY(13)); ctx.lineTo(45, cellY(8)); ctx.fill();
  const rx = GRID_W - 60;
  ctx.fillRect(rx, cellY(7), 22, 7 * CELL);
  ctx.fillRect(rx - 6, cellY(9), 34, 9 * CELL);
  ctx.beginPath(); ctx.moveTo(rx+5, cellY(7)); ctx.lineTo(rx+11, cellY(12)); ctx.lineTo(rx+17, cellY(7)); ctx.fill();
}

// ─── Hover highlight ─────────────────────────────────────────────────────────
function drawHoverHighlight() {
  if (!ui.selectedType || ui.hoverCol < 0) return;
  const cols = ui.selectedType === 'platform'
    ? [ui.hoverCol - 1, ui.hoverCol, ui.hoverCol + 1]
    : [ui.hoverCol];
  const color = canPlace(ui.selectedType, ui.hoverCol, state.turn)
    ? 'rgba(255,255,255,0.15)' : 'rgba(255,0,0,0.12)';
  for (const col of cols)
    if (col >= 0 && col < TOTAL_COLS) {
      ctx.fillStyle = color;
      ctx.fillRect(cellX(col), 0, CELL, CH);
    }
}

// ─── Side panel ───────────────────────────────────────────────────────────────
function sideBtn(label, sub, x, y, w, h, active, color) {
  ctx.fillStyle   = active ? color + '28' : '#111';
  ctx.fillRect(x, y, w, h);
  ctx.strokeStyle = active ? color : '#222222';
  ctx.lineWidth   = active ? 2 : 1;
  ctx.strokeRect(x, y, w, h);
  ctx.fillStyle   = active ? color : '#888';
  ctx.font        = 'bold 13px monospace';
  ctx.textAlign   = 'center';
  ctx.fillText(label, x + w / 2, y + h / 2 - 3);
  if (sub) {
    ctx.fillStyle = active ? '#dddddd' : '#444';
    ctx.font      = '11px monospace';
    ctx.fillText(sub, x + w / 2, y + h / 2 + 13);
  }
  ctx.textAlign = 'left';
}

function drawSidePanel() {
  const px = GRID_W, pw = SIDE_W, bw = pw - 16, bx = px + 8;

  ctx.fillStyle = '#080808'; ctx.fillRect(px, 0, pw, CH);
  ctx.strokeStyle = '#1a1a10'; ctx.lineWidth = 1; ctx.strokeRect(px, 0, pw, CH);
  ctx.save();
  ctx.shadowColor = '#2a1a08'; ctx.shadowBlur = 8; ctx.strokeStyle = '#2a1a08';
  ctx.beginPath(); ctx.moveTo(px, 0); ctx.lineTo(px, CH); ctx.stroke();
  ctx.restore();

  let y = 16;

  // Title
  ctx.fillStyle = '#dddddd'; ctx.font = 'bold 22px monospace'; ctx.textAlign = 'center';
  ctx.fillText('KAPITAL', px + pw / 2, y + 8); y += 38;
  ctx.textAlign = 'left';
  ctx.strokeStyle = '#222'; ctx.lineWidth = 1;
  ctx.beginPath(); ctx.moveTo(bx, y); ctx.lineTo(bx + bw, y); ctx.stroke(); y += 12;

  // Player panels
  const ppH = 54;
  for (let p = 0; p < 2; p++) {
    const isActive = p === state.turn;
    const col = PLAYER_COLORS[p];
    if (isActive) {
      ctx.save();
      ctx.shadowColor = col; ctx.shadowBlur = 12;
      ctx.fillStyle = col + '18'; ctx.fillRect(bx, y, bw, ppH);
      ctx.restore();
      ctx.strokeStyle = col + '88'; ctx.lineWidth = 1; ctx.strokeRect(bx, y, bw, ppH);
    }
    ctx.fillStyle = isActive ? col : '#555';
    ctx.font = `bold ${isActive ? 14 : 12}px monospace`;
    ctx.fillText(PLAYER_NAMES[p], bx + 8, y + 20);
    ctx.fillStyle = isActive ? '#dddddd' : '#444';
    ctx.font = `${isActive ? 14 : 12}px monospace`;
    ctx.fillText(`$ ${state.wallets[p]}`, bx + 8, y + 40);
    if (isActive) {
      ctx.fillStyle = '#777'; ctx.font = '10px monospace';
      ctx.fillText(`+$${calcIncome(p)}`, bx + bw - 40, y + 40);
    }
    y += ppH + 8;
  }

  y += 2;
  ctx.strokeStyle = '#222'; ctx.lineWidth = 1;
  ctx.beginPath(); ctx.moveTo(bx, y); ctx.lineTo(bx + bw, y); ctx.stroke(); y += 14;

  // Build buttons
  ctx.fillStyle = '#777'; ctx.font = 'bold 10px monospace'; ctx.fillText('BUILD', bx, y + 10); y += 20;
  buildBtns.length = 0;
  const bh = 38;
  for (const { type, label, cost } of BUILD_TYPES) {
    const sel  = ui.selectedType === type;
    const affd = state.wallets[state.turn] >= cost;
    buildBtns.push({ type, x: bx, y, w: bw, h: bh });
    sideBtn(label, `$${cost}`, bx, y, bw, bh, sel, affd ? PLAYER_COLORS[state.turn] : '#333');
    y += bh + 5;
  }

  y += 10;

  // End Turn button
  const etH = bh + 6;
  BTN.x = bx; BTN.y = y; BTN.w = bw; BTN.h = etH;
  const idle = state.phase === 'IDLE';
  ctx.fillStyle   = idle ? '#1e1e1e' : '#111'; ctx.fillRect(bx, y, bw, etH);
  ctx.strokeStyle = idle ? '#dddddd' : '#333'; ctx.lineWidth = idle ? 2 : 1;
  ctx.strokeRect(bx, y, bw, etH);
  ctx.fillStyle = idle ? '#dddddd' : '#444'; ctx.font = 'bold 14px monospace';
  ctx.textAlign = 'center';
  ctx.fillText('END TURN', bx + bw / 2, y + etH / 2 + 5);
  ctx.textAlign = 'left';
}

// ─── Win screen ───────────────────────────────────────────────────────────────
function drawWinScreen(now) {
  if (state.phase !== 'WIN') return;
  const p = winState.winner;
  ctx.fillStyle = 'rgba(0,0,0,0.78)'; ctx.fillRect(0, 0, CW, CH);
  const flicker = 0.7 + 0.3 * Math.sin(now * 0.006);
  ctx.save();
  ctx.shadowColor = PLAYER_COLORS[p]; ctx.shadowBlur = 40 * flicker;
  ctx.strokeStyle = PLAYER_COLORS[p]; ctx.lineWidth = 3;
  ctx.strokeRect(20, 20, CW - 40, CH - 40);
  ctx.restore();
  const cx = CW / 2, cy = CH / 2;
  ctx.save();
  ctx.fillStyle = PLAYER_COLORS[p]; ctx.shadowColor = PLAYER_COLORS[p]; ctx.shadowBlur = 24 * flicker;
  ctx.font = 'bold 52px monospace'; ctx.textAlign = 'center';
  ctx.fillText('VICTORY', cx, cy - 60);
  ctx.restore();
  ctx.fillStyle = '#dddddd'; ctx.font = 'bold 22px monospace'; ctx.textAlign = 'center';
  ctx.fillText(PLAYER_NAMES[p], cx, cy - 10);
  ctx.fillStyle = '#888'; ctx.font = '12px monospace';
  ctx.fillText('has reached the sky limit', cx, cy + 18);
  const bw = 180, bh = 36, bx = cx - 90, by = cy + 50;
  winState.replayBtn = { x: bx, y: by, w: bw, h: bh };
  ctx.fillStyle = '#181818'; ctx.fillRect(bx, by, bw, bh);
  ctx.strokeStyle = '#dddddd'; ctx.lineWidth = 2; ctx.strokeRect(bx, by, bw, bh);
  ctx.fillStyle = '#dddddd'; ctx.font = 'bold 13px monospace';
  ctx.fillText('PLAY AGAIN', cx, by + 24);
  ctx.textAlign = 'left';
}

// ─── Main render loop ────────────────────────────────────────────────────────
let currentNow = 0;
function render(now) {
  currentNow = now;
  updateAnim(now);
  updateCamera();
  ctx.clearRect(0, 0, CW, CH);

  // World (camera-translated, clipped to viewport)
  ctx.save();
  ctx.beginPath();
  ctx.rect(0, 0, GRID_W, CH);
  ctx.clip();
  ctx.translate(-Math.round(cameraX), 0);
  drawBackground();
  drawHoverHighlight();
  drawGrid();
  drawAnim(now);
  ctx.restore();

  // UI (screen space)
  drawSidePanel();
  drawWinScreen(now);
  requestAnimationFrame(render);
}
