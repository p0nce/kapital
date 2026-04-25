import { NUMBER_COLORS, drawMineShape } from './constants.js';

export function createRenderer(canvas, ctx) {
  function drawFlag(tcx, tcy, ts) {
    const poleX   = tcx - ts * 0.05;
    const poleTop = tcy - ts * 0.30;
    const poleBot = tcy + ts * 0.28;
    const baseH   = ts * 0.20;
    ctx.save();
    ctx.lineCap = 'round'; ctx.lineJoin = 'round';
    ctx.strokeStyle = '#555'; ctx.lineWidth = ts * 0.07;
    ctx.beginPath(); ctx.moveTo(poleX, poleTop); ctx.lineTo(poleX, poleBot); ctx.stroke();
    ctx.beginPath(); ctx.moveTo(poleX - baseH, poleBot); ctx.lineTo(poleX + baseH, poleBot); ctx.stroke();
    ctx.fillStyle = '#ee2222';
    ctx.beginPath();
    ctx.moveTo(poleX, poleTop);
    ctx.lineTo(poleX + ts * 0.30, poleTop + ts * 0.13);
    ctx.lineTo(poleX, poleTop + ts * 0.26);
    ctx.closePath(); ctx.fill();
    ctx.restore();
  }

  function drawMine(tcx, tcy, ts, charred) {
    ctx.save();
    drawMineShape(ctx, tcx, tcy, ts, charred);
    ctx.restore();
  }

  function drawWire(sx, sy, ts, tx, ty, buildings) {
    const tcx = sx + ts / 2, tcy = sy + ts / 2;
    const lw  = Math.max(2, ts * 0.11);
    ctx.save();
    ctx.strokeStyle = '#ffcc00';
    ctx.lineWidth   = lw;
    ctx.lineCap     = 'round';
    // Line to each cardinal neighbor that has any building
    const dirs = [
      { dx:  0, dy: -1, ex: tcx,       ey: sy + 1      },
      { dx:  0, dy:  1, ex: tcx,       ey: sy + ts - 1 },
      { dx: -1, dy:  0, ex: sx + 1,    ey: tcy         },
      { dx:  1, dy:  0, ex: sx + ts - 1, ey: tcy       },
    ];
    for (const { dx, dy, ex, ey } of dirs) {
      if (buildings.getBuildingAt(tx + dx, ty + dy)) {
        ctx.beginPath();
        ctx.moveTo(tcx, tcy);
        ctx.lineTo(ex, ey);
        ctx.stroke();
      }
    }
    // Center node
    ctx.fillStyle = '#ffcc00';
    ctx.beginPath();
    ctx.arc(tcx, tcy, lw * 0.8, 0, Math.PI * 2);
    ctx.fill();
    ctx.restore();
  }

  function drawTile(tx, ty, tile, cam, hoverInfo, shakeOff, buildings, biome) {
    const { x: camX, y: camY, tileSize: ts } = cam;
    const sx  = tx * ts - camX + shakeOff.x;
    const sy  = ty * ts - camY + shakeOff.y;
    const gap = 1;
    const tcx = sx + ts / 2, tcy = sy + ts / 2;

    // Background
    if (tile.revealed) {
      ctx.fillStyle = tile.charred ? '#3a2010' : (biome?.revealedColor || '#b8b8b8');
    } else {
      ctx.fillStyle = tile.charred ? '#221408' : (biome?.unrevealedColor || '#3a3a3a');
    }
    ctx.fillRect(sx + gap, sy + gap, ts - 2 * gap, ts - 2 * gap);

    // Charred marks
    if (tile.charred) {
      ctx.fillStyle = tile.revealed ? '#1a0c00' : '#110800';
      ctx.fillRect(sx + gap + 2,      sy + gap + 2,      3, 3);
      ctx.fillRect(sx + ts - gap - 5, sy + ts - gap - 5, 3, 3);
      ctx.fillRect(tcx - 1,           sy + gap + 5,      2, 2);
    }

    if (!tile.revealed) {
      if (tile.flagged) drawFlag(tcx, tcy, ts);
    } else if (tile.object) {
      if (tile.object.type === 'number') {
        ctx.fillStyle    = NUMBER_COLORS[tile.object.value];
        ctx.font         = `bold ${Math.floor(ts * 0.55)}px sans-serif`;
        ctx.textAlign    = 'center';
        ctx.textBaseline = 'middle';
        ctx.fillText(tile.object.value, tcx, tcy);
      } else if (tile.object.type === 'mine') {
        drawMine(tcx, tcy, ts, tile.charred);
      }
    }

    // Building
    if (buildings) {
      const bld = buildings.getBuildingAt(tx, ty);
      if (bld) {
        if (bld.type === 'wire') {
          drawWire(sx, sy, ts, tx, ty, buildings);
        } else if (bld.type === 'lot') {
          const lx = tx - bld.tx, ly = ty - bld.ty;
          const lw = 2;
          ctx.fillStyle = '#2a1e0a';
          ctx.fillRect(sx + gap, sy + gap, ts - 2 * gap, ts - 2 * gap);
          ctx.fillStyle = '#8a6428';
          if (lx === 0) ctx.fillRect(sx + gap,           sy + gap, lw, ts - 2 * gap);
          if (lx === 1) ctx.fillRect(sx + ts - gap - lw, sy + gap, lw, ts - 2 * gap);
          if (ly === 0) ctx.fillRect(sx + gap, sy + gap,           ts - 2 * gap, lw);
          if (ly === 1) ctx.fillRect(sx + gap, sy + ts - gap - lw, ts - 2 * gap, lw);
          if (lx === 1 && ly === 1) {
            // sx,sy is the center of the 2×2 building at this point
            ctx.fillStyle = '#d4a050';
            ctx.beginPath(); ctx.arc(sx, sy + ts * 0.08, ts * 0.22, 0, Math.PI * 2); ctx.fill();
            ctx.fillStyle = '#a07030';
            ctx.beginPath(); ctx.arc(sx, sy - ts * 0.20, ts * 0.13, 0, Math.PI * 2); ctx.fill();
          }
        } else if (bld.type === 'lab') {
          const lx = tx - bld.tx, ly = ty - bld.ty;
          const lw = 2;
          ctx.fillStyle = '#1a2a1a';
          ctx.fillRect(sx + gap, sy + gap, ts - 2 * gap, ts - 2 * gap);
          ctx.fillStyle = '#3a8a3a';
          if (lx === 0) ctx.fillRect(sx + gap,            sy + gap, lw, ts - 2 * gap);
          if (lx === 2) ctx.fillRect(sx + ts - gap - lw,  sy + gap, lw, ts - 2 * gap);
          if (ly === 0) ctx.fillRect(sx + gap, sy + gap,            ts - 2 * gap, lw);
          if (ly === 2) ctx.fillRect(sx + gap, sy + ts - gap - lw,  ts - 2 * gap, lw);
          if (lx === 1 && ly === 1) {
            ctx.fillStyle    = '#44cc44';
            ctx.font         = `bold ${Math.floor(ts * 0.4)}px monospace`;
            ctx.textAlign    = 'center';
            ctx.textBaseline = 'middle';
            ctx.fillText('LAB', tcx, tcy);
          }
        }
      }
    }

    // Hover / placement footprint (drawn last)
    if (hoverInfo === 'normal') {
      ctx.fillStyle = 'rgba(255,220,0,0.28)';
      ctx.fillRect(sx + gap, sy + gap, ts - 2 * gap, ts - 2 * gap);
    } else if (hoverInfo === 'valid') {
      ctx.fillStyle = 'rgba(0,220,80,0.35)';
      ctx.fillRect(sx + gap, sy + gap, ts - 2 * gap, ts - 2 * gap);
    } else if (hoverInfo === 'invalid') {
      ctx.fillStyle = 'rgba(255,60,60,0.30)';
      ctx.fillRect(sx + gap, sy + gap, ts - 2 * gap, ts - 2 * gap);
    }
  }

  function drawWorker(w, camX, camY, ts, shakeOff) {
    const sx = w.x - camX + shakeOff.x;
    const sy = w.y - camY + shakeOff.y;

    const h        = ts * 0.62;
    const headR    = h * 0.15;
    const bodyLen  = h * 0.36;
    const legLen   = h * 0.30;
    const armSpan  = h * 0.22;
    const headCY   = sy - h * 0.44;
    const bodyTopY = headCY + headR + 1;
    const bodyBotY = bodyTopY + bodyLen;
    const swing    = Math.sin(w.walkPhase) * legLen * 0.55;
    const armBaseY = bodyTopY + bodyLen * 0.28;

    ctx.save();
    ctx.strokeStyle = '#e8c878';
    ctx.fillStyle   = '#e8c878';
    ctx.lineWidth   = Math.max(1.2, ts * 0.048);
    ctx.lineCap     = 'round';

    ctx.beginPath(); ctx.arc(sx, headCY, headR, 0, Math.PI * 2); ctx.fill();

    ctx.beginPath();
    ctx.moveTo(sx, bodyTopY); ctx.lineTo(sx, bodyBotY);
    ctx.stroke();

    ctx.beginPath();
    ctx.moveTo(sx, armBaseY); ctx.lineTo(sx - armSpan * 0.5 - swing * 0.35, armBaseY + h * 0.18);
    ctx.moveTo(sx, armBaseY); ctx.lineTo(sx + armSpan * 0.5 + swing * 0.35, armBaseY + h * 0.18);
    ctx.stroke();

    ctx.beginPath();
    ctx.moveTo(sx, bodyBotY); ctx.lineTo(sx - swing, bodyBotY + legLen);
    ctx.moveTo(sx, bodyBotY); ctx.lineTo(sx + swing, bodyBotY + legLen);
    ctx.stroke();

    if (w.selected) {
      ctx.save();
      ctx.strokeStyle = 'rgba(255,240,150,0.85)';
      ctx.lineWidth = 1.5;
      ctx.setLineDash([3, 3]);
      ctx.beginPath(); ctx.arc(sx, sy - h * 0.1, h * 0.65, 0, Math.PI * 2); ctx.stroke();
      ctx.restore();
    }

    ctx.restore();
  }

  function render(world, cam, effects, hoveredTile, buildings, workers, lotRadius) {
    ctx.fillStyle = '#1a1a1a';
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    if (!world.getChunk) return;

    const shakeOff = effects.getScreenShakeOffset();
    ctx.save();
    ctx.translate(shakeOff.x, shakeOff.y);

    const { minCx, minCy, maxCx, maxCy } = cam.visibleChunkRange(world.CHUNK_SIZE);

    for (let cy = minCy; cy <= maxCy; cy++) {
      for (let cx = minCx; cx <= maxCx; cx++) {
        const chunk = world.getChunk(cx, cy);
        for (let ly = 0; ly < world.CHUNK_SIZE; ly++) {
          for (let lx = 0; lx < world.CHUNK_SIZE; lx++) {
            const tx   = cx * world.CHUNK_SIZE + lx;
            const ty   = cy * world.CHUNK_SIZE + ly;
            const tile = chunk.tiles[ly * world.CHUNK_SIZE + lx];

            let hoverInfo = null;
            if (hoveredTile?.isPlacement) {
              const { tx: htx, ty: hty, w: hw, h: hh, valid } = hoveredTile;
              if (tx >= htx && tx < htx + hw && ty >= hty && ty < hty + hh) {
                hoverInfo = valid ? 'valid' : 'invalid';
              }
            } else if (hoveredTile?.tx === tx && hoveredTile?.ty === ty) {
              hoverInfo = 'normal';
            }

            drawTile(tx, ty, tile, cam, hoverInfo, effects.getTileShakeOffset(tx, ty), buildings, world.getBiome(tx, ty));
          }
        }
      }
    }

    if (lotRadius) {
      const { x: camX, y: camY } = cam;
      ctx.save();
      ctx.strokeStyle = 'rgba(200,160,80,0.45)';
      ctx.lineWidth = 1.5;
      ctx.setLineDash([5, 5]);
      ctx.beginPath();
      ctx.arc(lotRadius.wx - camX, lotRadius.wy - camY, lotRadius.r, 0, Math.PI * 2);
      ctx.stroke();
      ctx.restore();
    }

    if (workers) {
      const { x: camX, y: camY, tileSize: ts } = cam;
      for (const w of workers.getAll()) {
        drawWorker(w, camX, camY, ts, shakeOff);
      }
    }

    for (const p of effects.particles) {
      const px = p.x - cam.x;
      const py = p.y - cam.y;
      ctx.globalAlpha = Math.max(0, p.life);
      ctx.fillStyle   = p.color;
      ctx.fillRect(px - p.size / 2, py - p.size / 2, p.size, p.size);
    }
    ctx.globalAlpha = 1;

    ctx.restore();
  }

  return { render };
}
