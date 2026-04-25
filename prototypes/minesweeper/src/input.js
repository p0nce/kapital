import { BUILDING_TYPES } from './buildings.js';

const HARVEST_COLORS = {
  mine: '#aaddff', charcoal: '#aa7744', wood: '#88cc44', '0': '#ff8800',
  '1': '#4488ff', '2': '#44aa44', '3': '#ff5555',
  '4': '#4444cc', '5': '#cc3333', '6': '#22bbbb',
  '7': '#888888', '8': '#aaaaaa',
};

export function createInput(canvas, cam, world, tick, effects, resources, buildings, buildMenu, workers, research) {
  const TILE_SIZE = 32;
  const keysHeld = new Set();
  let mouseX = -1, mouseY = -1;
  let dragStart = null;
  let camAtDrag  = null;
  let dragged    = false;
  let selectedWorker = null;

  function _selectWorker(w) {
    if (selectedWorker) selectedWorker.selected = false;
    selectedWorker = w;
    if (w) w.selected = true;
  }

  function _workerAt(screenX, screenY) {
    const wx = screenX + cam.x;
    const wy = screenY + cam.y;
    for (const w of workers.getAll()) {
      if (Math.hypot(wx - w.x, wy - w.y) < 16) return w;
    }
    return null;
  }

  // ── Research popup ─────────────────────────────────────────────────────────
  const researchPopup = document.getElementById('research-popup');
  const researchBody  = researchPopup.querySelector('.popup-body');

  document.getElementById('research-close').addEventListener('click', () => {
    researchPopup.style.display = 'none';
  });

  function _refreshResearchPopup() {
    const state      = research.getState();
    const defs       = research.getDefs();
    const labWorkers = workers.getLabWorkerCount();

    let html = `<div class="research-status">${labWorkers} worker${labWorkers !== 1 ? 's' : ''} in lab</div>`;

    for (const [key, def] of Object.entries(defs)) {
      const level    = research.getLevel(key);
      const maxLevel = def.costs.length;
      const isCurr   = state.current === key;
      const isMaxed  = level >= maxLevel;
      const prog     = research.getProgress(key);
      const needed   = isMaxed ? 1 : def.costs[level];
      const pct      = Math.min(100, (prog / needed) * 100).toFixed(0);
      const hasProgress = prog > 0;

      html += `<div class="research-item${isCurr ? ' active' : ''}${isMaxed ? ' maxed' : ''}">`;
      html += `<div class="research-name">${def.name} <span class="research-level">Lv${level}${isMaxed ? ' MAX' : ''}</span></div>`;
      html += `<div class="research-desc">${def.desc}</div>`;
      if ((isCurr || hasProgress) && !isMaxed) {
        html += `<div class="research-bar"><div class="research-fill" style="width:${pct}%"></div></div>`;
        html += `<div class="research-pts">${Math.floor(prog)} / ${needed} pts</div>`;
      }
      if (!isMaxed) {
        const cost = def.costs[level];
        html += `<button class="research-btn${isCurr ? ' cancel' : ''}" data-key="${key}">${isCurr ? 'HALT' : 'RESEARCH'} (${cost} pts)</button>`;
      }
      html += `</div>`;
    }

    researchBody.innerHTML = html;
    researchBody.querySelectorAll('.research-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        if (state.current === btn.dataset.key) {
          research.cancelResearch();
        } else {
          research.startResearch(btn.dataset.key);
        }
        _refreshResearchPopup();
      });
    });
  }

  setInterval(() => {
    if (researchPopup.style.display !== 'none') _refreshResearchPopup();
  }, 500);

  // ── Worker popup ───────────────────────────────────────────────────────────
  const workerPopup = document.getElementById('worker-popup');
  let activeLot = null;
  document.getElementById('worker-close').addEventListener('click', () => {
    workerPopup.style.display = 'none'; activeLot = null;
  });
  document.querySelectorAll('.job-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      if (!activeLot) return;
      if (btn.classList.contains('disabled')) return;
      workers.setJob(activeLot.tx, activeLot.ty, btn.dataset.job);
      _refreshWorkerPopup();
    });
  });
  function _refreshWorkerPopup() {
    const w = activeLot ? workers.getWorker(activeLot.tx, activeLot.ty) : null;
    document.querySelectorAll('.job-btn').forEach(btn => {
      btn.classList.toggle('active', w?.job === btn.dataset.job);
      if (btn.dataset.job === 'lab') {
        const canLab = activeLot ? workers.hasAvailableLab(activeLot.tx, activeLot.ty) : false;
        btn.classList.toggle('disabled', !canLab);
      }
    });
  }
  function _openWorkerPopup(bldTx, bldTy) {
    activeLot = { tx: bldTx, ty: bldTy };
    _refreshWorkerPopup();
    workerPopup.style.display = 'block';
  }

  window.addEventListener('keydown', e => {
    keysHeld.add(e.code);
    if (e.code === 'Escape') {
      _selectWorker(null);
      buildMenu.deselect();
      researchPopup.style.display = 'none';
      workerPopup.style.display = 'none'; activeLot = null;
    }
    if (['ArrowUp','ArrowDown','ArrowLeft','ArrowRight'].includes(e.code)) e.preventDefault();
  });
  window.addEventListener('keyup', e => keysHeld.delete(e.code));

  canvas.addEventListener('mousedown', e => {
    if (e.button !== 0) return;
    dragStart = { x: e.clientX, y: e.clientY };
    camAtDrag = { x: cam.x, y: cam.y };
    dragged   = false;
  });

  canvas.addEventListener('mousemove', e => {
    mouseX = e.clientX;
    mouseY = e.clientY;

    if (dragStart) {
      const dx = e.clientX - dragStart.x;
      const dy = e.clientY - dragStart.y;
      if (!dragged && (Math.abs(dx) > 4 || Math.abs(dy) > 4)) dragged = true;
      if (dragged) {
        cam.x = camAtDrag.x - dx;
        cam.y = camAtDrag.y - dy;
      }
    }

    canvas.style.cursor = _workerAt(mouseX, mouseY) ? 'pointer'
      : selectedWorker ? 'crosshair'
      : buildMenu.getSelectedType() ? 'cell'
      : getHoveredTile() ? 'pointer' : 'default';
  });

  canvas.addEventListener('mouseup', e => {
    if (e.button === 0 && dragStart && !dragged) handleLeftClick(e.clientX, e.clientY);
    dragStart = null;
  });

  canvas.addEventListener('contextmenu', e => {
    e.preventDefault();
    handleRightClick(e.clientX, e.clientY);
  });

  function getHoveredTile() {
    if (mouseX < 0) return null;
    const { tx, ty } = cam.screenToTile(mouseX, mouseY);

    const type = buildMenu.getSelectedType();
    if (type) {
      const { w, h } = BUILDING_TYPES[type];
      return { tx, ty, isPlacement: true, w, h, valid: buildings.canPlace(type, tx, ty) };
    }

    const tile = world.getTile(tx, ty);

    if (tile.charred) return { tx, ty };
    if (tile.revealed && tile.object?.type === 'mine') return { tx, ty };
    if (tile.revealed) {
      const bt = buildings.getBuildingAt(tx, ty)?.type;
      if (bt === 'lab' || bt === 'lot') return { tx, ty };
    }
    if (!tile.revealed && !tile.flagged) return { tx, ty };

    if (tile.revealed && tile.object?.type === 'number') {
      let knownMines = 0;
      for (let dy = -1; dy <= 1; dy++) {
        for (let dx = -1; dx <= 1; dx++) {
          if (dx === 0 && dy === 0) continue;
          const n = world.getTile(tx + dx, ty + dy);
          if (n.flagged || (n.revealed && n.object?.type === 'mine')) knownMines++;
        }
      }
      if (knownMines === tile.object.value) return { tx, ty };
    }

    return null;
  }

  function handleLeftClick(sx, sy) {
    const clickedW = _workerAt(sx, sy);
    if (clickedW) { _selectWorker(clickedW === selectedWorker ? null : clickedW); return; }
    if (selectedWorker) {
      const { tx, ty } = cam.screenToTile(sx, sy);
      workers.assignOnce(selectedWorker, tx, ty);
      _selectWorker(null);
      return;
    }

    const { tx, ty } = cam.screenToTile(sx, sy);

    const type = buildMenu.getSelectedType();
    if (type) {
      if (buildings.canPlace(type, tx, ty)) {
        for (const [res, amt] of Object.entries(BUILDING_TYPES[type].cost)) {
          resources.spend(res, amt);
        }
        buildings.place(type, tx, ty);
        if (type === 'mine') world.applyMineBuilding(tx, ty);
        if (type === 'lot')  workers.addWorker(tx, ty);
      }
      return;
    }

    const tile = world.getTile(tx, ty);
    const wx   = tx * cam.tileSize + cam.tileSize / 2;
    const wy   = ty * cam.tileSize + cam.tileSize / 2;

    if (tile.charred) {
      if (buildings.isOccupied(tx, ty)) return;
      const result = world.harvestTile(tx, ty);
      if (result) {
        resources.add(result.resource, result.amount);
        effects.triggerTileShake(tx, ty);
        effects.emitParticles(wx, wy, HARVEST_COLORS[result.resource], 8);
      }
      return;
    }

    if (tile.revealed && tile.object?.type === 'number' && tile.object.value === 0 && !tile.charred) {
      const result = world.harvestTile(tx, ty);
      if (result) {
        resources.add(result.resource, result.amount);
        effects.emitParticles(wx, wy, HARVEST_COLORS[result.resource], 8);
      }
      return;
    }

    if (tile.revealed && tile.object?.type === 'number') {
      chordReveal(tx, ty);
      return;
    }

    if (tile.revealed && tile.object?.type === 'mine') {
      effects.triggerTileShake(tx, ty);
      tick.triggerExplosion(tx, ty);
      return;
    }

    const bld = buildings.getBuildingAt(tx, ty);
    if (tile.revealed && bld?.type === 'lab') {
      _refreshResearchPopup();
      researchPopup.style.display = 'block';
      return;
    }
    if (tile.revealed && bld?.type === 'lot') {
      _openWorkerPopup(bld.tx, bld.ty);
      return;
    }

    if (tile.revealed || tile.flagged) return;

    effects.emitParticles(wx, wy, '#c0c0c0', 6);

    if (tile.object?.type === 'mine') {
      effects.triggerTileShake(tx, ty);
      tick.triggerExplosion(tx, ty);
    } else {
      world.reveal(tx, ty);
    }
  }

  function chordReveal(tx, ty) {
    const tile = world.getTile(tx, ty);
    let knownMines = 0;
    for (let dy = -1; dy <= 1; dy++) {
      for (let dx = -1; dx <= 1; dx++) {
        if (dx === 0 && dy === 0) continue;
        const n = world.getTile(tx + dx, ty + dy);
        if (n.flagged || (n.revealed && n.object?.type === 'mine')) knownMines++;
      }
    }
    if (knownMines !== tile.object.value) return;

    for (let dy = -1; dy <= 1; dy++) {
      for (let dx = -1; dx <= 1; dx++) {
        if (dx === 0 && dy === 0) continue;
        const nx = tx + dx, ny = ty + dy;
        const n = world.getTile(nx, ny);
        if (n.revealed || n.flagged || n.charred) continue;
        if (n.object?.type === 'mine') tick.triggerExplosion(nx, ny);
        else world.reveal(nx, ny);
      }
    }
  }

  function handleRightClick(sx, sy) {
    if (buildMenu.getSelectedType()) { buildMenu.deselect(); return; }
    const { tx, ty } = cam.screenToTile(sx, sy);
    const tile = world.getTile(tx, ty);
    if (tile.charred) return;
    world.toggleFlag(tx, ty);
  }

  function getActiveLotRadius() {
    if (!activeLot) return null;
    return {
      wx: (activeLot.tx + 1) * TILE_SIZE,
      wy: (activeLot.ty + 1) * TILE_SIZE,
      r:  research.getWorkerRange() * TILE_SIZE,
    };
  }

  return { keysHeld, getHoveredTile, getActiveLotRadius };
}
