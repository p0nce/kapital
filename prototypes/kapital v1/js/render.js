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
  if (type === 'tower')     { drawTower(x, y, s, owner, row, col); return; }
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

function isTowerAt(row, col) {
  if (row < 0 || row >= ROWS) return false;
  if (grid[row][col].type === 'tower') return true;
  // Cells pending in the current build animation aren't in `grid` yet.
  if (animBuild) {
    for (const c of animBuild.cells)
      if (c.type === 'tower' && c.row === row && c.col === col) return true;
  }
  return false;
}

function drawTower(x, y, s, owner, row, col) {
  // Choose tower variant based on vertical neighbours (tower runs merge).
  const hasAbove = row != null && isTowerAt(row + 1, col);
  const hasBelow = row != null && isTowerAt(row - 1, col);
  let variant;
  if (!hasAbove && !hasBelow)      variant = 'tower_alone';
  else if (!hasAbove &&  hasBelow) variant = 'tower_up';    // top of run
  else if ( hasAbove && !hasBelow) variant = 'tower_down';  // bottom of run
  else                              variant = 'tower_mid';  // middle of run

  TileAtlas.drawTile(ctx, variant, x, y, currentNow, s / TILE_SIZE);
  return;

  // Procedural fallback (unused while atlas is active)
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
  const name = role === 'left'  ? 'platform_left'
             : role === 'right' ? 'platform_right'
             :                    'platform_base';
  TileAtlas.drawTile(ctx, name, x, y, currentNow, s / TILE_SIZE);
  return;

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

function drawApartment(x, y, s) {
  TileAtlas.drawTile(ctx, 'apartment', x, y, currentNow, s / TILE_SIZE);
}

function drawFlag(x, y, s, row, col) {
  TileAtlas.drawTile(ctx, 'flag', x, y, currentNow, s / TILE_SIZE);
}

function drawCannon(x, y, s, owner, row, col) {
  const cx = x + s / 2;
  const apexY = y + s - CANNON_PIVOT_Y;   // apex of the triangular base

  // Barrel — animated, extending beyond the cell. Drawn first so the tile
  // base (drawn after) sits on top of the pivot hub.
  const angle = cannonAngle(row, col, currentNow);
  const dir   = owner === 0 ? 1 : -1;
  const px    = cx, py = apexY;
  const ex    = px + dir * BARREL_LEN * Math.cos(angle);
  const ey    = py - BARREL_LEN * Math.sin(angle);

  ctx.lineCap = 'butt';
  ctx.strokeStyle = '#8a8a8a';
  ctx.lineWidth = 10;
  ctx.beginPath(); ctx.moveTo(px, py); ctx.lineTo(ex, ey); ctx.stroke();

  // Pivot hub
  ctx.fillStyle = '#8a8a8a';
  ctx.beginPath(); ctx.arc(px, py, 4, 0, Math.PI * 2); ctx.fill();

  // Tile base drawn on top of the barrel's pivot end
  TileAtlas.drawTile(ctx, 'cannon', x, y, currentNow, s / TILE_SIZE);
}

function drawGrid() {
  // First pass: every block except cannons
  for (let row = 0; row < ROWS; row++)
    for (let col = 0; col < TOTAL_COLS; col++) {
      const { type, owner, role } = grid[row][col];
      if (type === 'empty' || type === 'ground' || type === 'cannon') continue;
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
  ctx.fillStyle = '#111212';
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
  const scale = CELL / TILE_SIZE;
  for (let col = 0; col < TOTAL_COLS; col++) {
    TileAtlas.drawTile(ctx, 'ground', cellX(col), gy, currentNow, scale);
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
      ctx.fillRect(cellX(col), 0, CELL, cellY(0));
    }
}

// ─── Side panel ───────────────────────────────────────────────────────────────
function sideBtn(label, sub, x, y, w, h, active, color, disabled) {
  ctx.fillStyle   = active ? color + '28' : '#111';
  ctx.fillRect(x, y, w, h);
  ctx.strokeStyle = active ? color : '#222222';
  ctx.lineWidth   = active ? 2 : 1;
  ctx.strokeRect(x, y, w, h);

  const textColor = disabled ? '#555555' : '#eeeeee';
  ctx.fillStyle = textColor;
  ctx.font      = '14px monospace';
  ctx.textAlign = 'center';
  const labelY = y + h / 2 - 3;
  const subY   = y + h / 2 + 14;
  ctx.fillText(label, x + w / 2, labelY);
  if (sub) ctx.fillText(sub, x + w / 2, subY);

  if (disabled) {
    ctx.strokeStyle = textColor;
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(x + 8,     y + h / 2 + 2);
    ctx.lineTo(x + w - 8, y + h / 2 + 2);
    ctx.stroke();
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
  const ppH = 108;
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
    const textColor = isActive ? '#eeeeee' : '#555555';
    ctx.fillStyle = textColor;
    ctx.font      = '14px monospace';
    const pad2 = n => String(n).padStart(2, '0');
    ctx.fillText(PLAYER_NAMES[p], bx + 8, y + 16);
    ctx.fillText(`$${pad2(state.wallets[p])} / $${WALLET_MAX}`, bx + 8, y + 34);

    // Wallet fill bar
    const barX = bx + 8;
    const barY = y + 42;
    const barW = bw - 16;
    const barH = 5;
    ctx.fillStyle = '#222';
    ctx.fillRect(barX, barY, barW, barH);
    const frac = Math.max(0, Math.min(1, state.wallets[p] / WALLET_MAX));
    ctx.fillStyle = textColor;
    ctx.fillRect(barX, barY, Math.round(barW * frac), barH);

    ctx.fillStyle = isActive ? '#999999' : '#444444';
    ctx.fillText(`+$${calcIncome(p)} / turn`, bx + 8, y + 66);

    const maxI  = calcMaxInhabitants(p);
    const curI  = Math.min(state.inhabitants[p], maxI);
    ctx.fillStyle = textColor;
    ctx.fillText(`${curI} / ${maxI} inhabitants`, bx + 8, y + 84);

    // Inhabitants fill bar
    const ibY = y + 92;
    ctx.fillStyle = '#222';
    ctx.fillRect(barX, ibY, barW, barH);
    const ifrac = maxI > 0 ? curI / maxI : 0;
    ctx.fillStyle = textColor;
    ctx.fillRect(barX, ibY, Math.round(barW * ifrac), barH);

    y += ppH + 8;
  }

  y += 2;
  ctx.strokeStyle = '#222'; ctx.lineWidth = 1;
  ctx.beginPath(); ctx.moveTo(bx, y); ctx.lineTo(bx + bw, y); ctx.stroke(); y += 14;

  // Build buttons
  ctx.fillStyle = '#777'; ctx.font = '10px monospace'; ctx.fillText('BUILD', bx, y + 10); y += 20;
  buildBtns.length = 0;
  const bh = 44;
  for (const { type, label } of BUILD_TYPES) {
    const sel  = ui.selectedType === type;
    const cost = type === 'flag' ? flagCost(state.turn) : BLOCK_COSTS[type];
    const affd = state.wallets[state.turn] >= cost;
    buildBtns.push({ type, x: bx, y, w: bw, h: bh });
    sideBtn(label, `$${cost}`, bx, y, bw, bh, sel, PLAYER_COLORS[state.turn], !affd);
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
  ctx.fillStyle = idle ? '#dddddd' : '#444'; ctx.font = '14px monospace';
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
  ctx.fillStyle = '#111212';
  ctx.fillRect(0, 0, CW, CH);

  // World (camera-translated, clipped to viewport)
  ctx.save();
  ctx.beginPath();
  ctx.rect(0, 0, GRID_W, CH);
  ctx.clip();
  ctx.translate(-Math.round(cameraX), -Math.round(cameraY));
  drawBackground();
  drawGrid();
  drawAnim(now);
  drawHoverHighlight();
  ctx.restore();

  // UI (screen space)
  drawSidePanel();
  drawWinScreen(now);
  requestAnimationFrame(render);
}
