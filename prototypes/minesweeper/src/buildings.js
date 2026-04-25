export const BUILDING_TYPES = {
  wire: { name: 'WIRE', w: 1, h: 1, cost: { '1': 1 } },
  mine: { name: 'MINE', w: 1, h: 1, cost: { mine: 1, '3': 1 } },
  lab:  { name: 'LAB',  w: 3, h: 3, cost: { '1': 1, '4': 1, '8': 1 } },
  lot:  { name: 'LOT',  w: 2, h: 2, cost: { '1': 1, '0': 1, '2': 1 } },
};

export function createBuildings(world) {
  const occupiedMap = new Map(); // "tx,ty" → building
  const placed = [];

  function _register(bld) {
    const { w, h } = BUILDING_TYPES[bld.type];
    for (let dy = 0; dy < h; dy++)
      for (let dx = 0; dx < w; dx++)
        occupiedMap.set(`${bld.tx + dx},${bld.ty + dy}`, bld);
  }

  function isOccupied(tx, ty) { return occupiedMap.has(`${tx},${ty}`); }

  function getBuildingAt(tx, ty) { return occupiedMap.get(`${tx},${ty}`) ?? null; }

  function canPlace(type, tx, ty) {
    const { w, h } = BUILDING_TYPES[type];
    for (let dy = 0; dy < h; dy++) {
      for (let dx = 0; dx < w; dx++) {
        const nx = tx + dx, ny = ty + dy;
        if (isOccupied(nx, ny)) return false;
        const tile = world.getTile(nx, ny);
        if (!tile.revealed || tile.charred) return false;
        if (type === 'mine') {
          if (tile.object?.type === 'mine') return false;
        } else {
          if (tile.object && tile.object.type !== 'number') return false;
        }
      }
    }
    return true;
  }

  function place(type, tx, ty) {
    const bld = { type, tx, ty };
    placed.push(bld);
    _register(bld);
    try { localStorage.setItem('buildings', JSON.stringify(placed)); } catch (e) {}
  }

  function removeBuilding(tx, ty) {
    const bld = occupiedMap.get(`${tx},${ty}`);
    if (!bld) return;
    const { w, h } = BUILDING_TYPES[bld.type];
    for (let dy = 0; dy < h; dy++)
      for (let dx = 0; dx < w; dx++)
        occupiedMap.delete(`${bld.tx + dx},${bld.ty + dy}`);
    const idx = placed.findIndex(b => b.tx === bld.tx && b.ty === bld.ty);
    if (idx !== -1) placed.splice(idx, 1);
    try { localStorage.setItem('buildings', JSON.stringify(placed)); } catch (e) {}
  }

  // Load persisted buildings
  const raw = localStorage.getItem('buildings');
  if (raw) {
    for (const data of JSON.parse(raw)) {
      const bld = { type: data.type, tx: data.tx, ty: data.ty };
      placed.push(bld);
      _register(bld);
    }
  }

  function getAllOfType(type) { return placed.filter(b => b.type === type); }

  return { isOccupied, getBuildingAt, canPlace, place, removeBuilding, getAllOfType };
}
