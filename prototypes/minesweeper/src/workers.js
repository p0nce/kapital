const TILE_SIZE      = 32;
const SPEED          = 52;   // px/sec when working (before research multiplier)
const SPEED_IDLE     = 18;   // px/sec when idle
const WANDER_IDLE    = 2;    // tile radii from home when idle or between tasks
const WORK_REACH     = 0.7;  // tiles — must be within this distance to start working
const WORK_TIME      = 1.5;  // seconds of standing at tile to complete work
const MAX_LAB_WORKERS = 3;

export function createWorkers(world, buildings, resources, tick, research) {
  const list = JSON.parse(localStorage.getItem('workers') || '[]');
  list.forEach(_initVisual);

  function _save() {
    const data = list.map(w => {
      const d = { bldTx: w.bldTx, bldTy: w.bldTy, job: w.job };
      if (w.labTx != null) { d.labTx = w.labTx; d.labTy = w.labTy; }
      return d;
    });
    try { localStorage.setItem('workers', JSON.stringify(data)); } catch (e) {}
  }

  function _homeX(w) { return (w.bldTx + 1) * TILE_SIZE; }
  function _homeY(w) { return (w.bldTy + 1) * TILE_SIZE; }
  function _labCx(w) { return (w.labTx + 1.5) * TILE_SIZE; }
  function _labCy(w) { return (w.labTy + 1.5) * TILE_SIZE; }

  function _initVisual(w) {
    if (w.job === 'lab' && w.labTx != null) {
      w.x = _labCx(w); w.y = _labCy(w);
    } else {
      w.x = _homeX(w); w.y = _homeY(w);
    }
    w.targetX   = w.x;
    w.targetY   = w.y;
    w.walkPhase = Math.random() * Math.PI * 2;
    w.facing    = 1;
    w.selected  = false;
    w.workTarget = null;
    w.workTimer  = 0;
    w.oneShot    = null;
  }

  function _pickTarget(w) {
    if (w.job === 'lab' && w.labTx != null) {
      const r = TILE_SIZE;
      w.targetX = _labCx(w) + (Math.random() * 2 - 1) * r;
      w.targetY = _labCy(w) + (Math.random() * 2 - 1) * r;
    } else {
      const r = WANDER_IDLE * TILE_SIZE;
      w.targetX = _homeX(w) + (Math.random() * 2 - 1) * r;
      w.targetY = _homeY(w) + (Math.random() * 2 - 1) * r;
    }
  }

  function assign(w, worldX, worldY) {
    w.targetX = worldX;
    w.targetY = worldY;
  }

  function assignOnce(w, tx, ty) {
    w.oneShot   = { tx, ty };
    w.workTimer = 0;
  }

  function _findAvailableLab(w) {
    const labs = buildings.getAllOfType('lab');
    let best = null, bestDist = Infinity;
    for (const lab of labs) {
      const count = list.filter(o => o.job === 'lab' && o.labTx === lab.tx && o.labTy === lab.ty).length;
      if (count >= MAX_LAB_WORKERS) continue;
      const dist = Math.hypot(w.bldTx - lab.tx, w.bldTy - lab.ty);
      if (dist < bestDist) { bestDist = dist; best = lab; }
    }
    return best;
  }

  function addWorker(bldTx, bldTy) {
    if (list.some(w => w.bldTx === bldTx && w.bldTy === bldTy)) return;
    const w = { bldTx, bldTy, job: 'idle' };
    _initVisual(w);
    list.push(w);
    _save();
  }

  function getWorker(bldTx, bldTy) {
    return list.find(w => w.bldTx === bldTx && w.bldTy === bldTy) ?? null;
  }

  function setJob(bldTx, bldTy, job) {
    const w = getWorker(bldTx, bldTy);
    if (!w) return;
    if (job === 'lab') {
      const lab = _findAvailableLab(w);
      if (!lab) return;
      w.labTx = lab.tx; w.labTy = lab.ty;
      assign(w, _labCx(w), _labCy(w));
    } else {
      w.labTx = undefined; w.labTy = undefined;
    }
    w.job        = job;
    w.workTarget = null;
    w.workTimer  = 0;
    w.oneShot    = null;
    _save();
  }

  function hasAvailableLab(bldTx, bldTy) {
    const w = getWorker(bldTx, bldTy);
    if (!w) return false;
    if (w.job === 'lab') return true;
    return _findAvailableLab(w) !== null;
  }

  function getLabWorkerCount() {
    return list.filter(w => w.job === 'lab').length;
  }

  // ── per-tile work helpers ─────────────────────────────────────────────────

  function _isHarvestable(tile) {
    if (tile.charred) return true;
    if (tile.revealed && tile.object?.type === 'number' && tile.object.value === 0) return true;
    return false;
  }

  function _findClearTarget(w) {
    const radius = research.getWorkerRange();
    const hx = w.bldTx + 1, hy = w.bldTy + 1;
    let best = null, bestDist = Infinity;
    for (let dy = -radius; dy <= radius; dy++) {
      for (let dx = -radius; dx <= radius; dx++) {
        const tx = hx + dx, ty = hy + dy;
        const tile = world.getTile(tx, ty);
        if (!_isHarvestable(tile) || buildings.isOccupied(tx, ty)) continue;
        const d = dx * dx + dy * dy;
        if (d < bestDist) { bestDist = d; best = { tx, ty }; }
      }
    }
    return best;
  }

  function _findDiscoverTarget(w) {
    const radius = research.getWorkerRange();
    const hx = w.bldTx + 1, hy = w.bldTy + 1;
    let best = null, bestDist = Infinity;
    for (let dy = -radius; dy <= radius; dy++) {
      for (let dx = -radius; dx <= radius; dx++) {
        const tx = hx + dx, ty = hy + dy;
        const tile = world.getTile(tx, ty);
        if (tile.revealed || tile.flagged || tile.charred) continue;
        let frontier = false;
        outer: for (let ny = -1; ny <= 1; ny++) {
          for (let nx = -1; nx <= 1; nx++) {
            if (nx === 0 && ny === 0) continue;
            if (world.getTile(tx + nx, ty + ny).revealed) { frontier = true; break outer; }
          }
        }
        if (!frontier) continue;
        const d = dx * dx + dy * dy;
        if (d < bestDist) { bestDist = d; best = { tx, ty }; }
      }
    }
    return best;
  }

  function _targetIsStillValid(w, tx, ty) {
    const tile = world.getTile(tx, ty);
    if (w.job === 'clear')    return _isHarvestable(tile) && !buildings.isOccupied(tx, ty);
    if (w.job === 'discover') return !tile.revealed && !tile.flagged && !tile.charred;
    return true; // oneShot: check at execution time
  }

  function _execute(w, tx, ty) {
    const tile = world.getTile(tx, ty);
    if (w.oneShot) {
      if (_isHarvestable(tile) && !buildings.isOccupied(tx, ty)) {
        const r = world.harvestTile(tx, ty);
        if (r) resources.add(r.resource, r.amount);
      } else if (!tile.revealed && !tile.flagged && !tile.charred) {
        if (tile.object?.type === 'mine') tick.triggerExplosion(tx, ty);
        else world.reveal(tx, ty);
      }
      w.oneShot    = null;
      w.workTarget = null;
    } else if (w.job === 'clear') {
      if (_isHarvestable(tile) && !buildings.isOccupied(tx, ty)) {
        const r = world.harvestTile(tx, ty);
        if (r) resources.add(r.resource, r.amount);
      }
      w.workTarget = null;
    } else if (w.job === 'discover') {
      if (!tile.revealed && !tile.flagged && !tile.charred) {
        if (tile.object?.type === 'mine') tick.triggerExplosion(tx, ty);
        else world.reveal(tx, ty);
      }
      w.workTarget = null;
    }
  }

  function _updateWork(w, dt) {
    // Resolve active target
    const target = w.oneShot ?? w.workTarget;

    if (target) {
      if (!w.oneShot && !_targetIsStillValid(w, target.tx, target.ty)) {
        w.workTarget = null; w.workTimer = 0; return;
      }
      const cx   = (target.tx + 0.5) * TILE_SIZE;
      const cy   = (target.ty + 0.5) * TILE_SIZE;
      const dist = Math.hypot(w.x - cx, w.y - cy);
      if (dist > WORK_REACH * TILE_SIZE) {
        w.workTimer = 0;
        w.targetX = cx; w.targetY = cy;
      } else {
        w.workTimer += dt;
        if (w.workTimer >= WORK_TIME) {
          w.workTimer = 0;
          _execute(w, target.tx, target.ty);
        }
      }
    } else {
      const found = w.job === 'clear'    ? _findClearTarget(w)
                  : w.job === 'discover' ? _findDiscoverTarget(w) : null;
      if (found) {
        w.workTarget = found;
        w.workTimer  = 0;
        w.targetX    = (found.tx + 0.5) * TILE_SIZE;
        w.targetY    = (found.ty + 0.5) * TILE_SIZE;
      }
    }
  }

  function _updateLab(w) {
    if (w.labTx == null) return;
    if (Math.hypot(w.x - _labCx(w), w.y - _labCy(w)) > TILE_SIZE * 2.5) {
      w.targetX = _labCx(w); w.targetY = _labCy(w);
    }
  }

  function update(dt) {
    for (const w of list) {
      // Job-specific logic updates targetX/Y
      if (w.job === 'lab') {
        _updateLab(w);
      } else if (w.job !== 'idle') {
        _updateWork(w, dt);
      }

      // Movement toward targetX/Y
      const dx   = w.targetX - w.x;
      const dy   = w.targetY - w.y;
      const dist = Math.hypot(dx, dy);
      if (dist >= 2) {
        const speed = w.job === 'idle' ? SPEED_IDLE : SPEED * research.getWorkerSpeedMult();
        const step  = Math.min(speed * dt, dist);
        w.x += (dx / dist) * step;
        w.y += (dy / dist) * step;
        w.walkPhase = (w.walkPhase + dt * (w.job === 'idle' ? 4 : 7)) % (Math.PI * 2);
        if (Math.abs(dx) > 1) w.facing = dx > 0 ? 1 : -1;
      } else if (!w.workTarget && !w.oneShot) {
        _pickTarget(w);
      }
    }
  }

  return { addWorker, getWorker, setJob, assign, assignOnce, update, getAll: () => list, hasAvailableLab, getLabWorkerCount };
}
