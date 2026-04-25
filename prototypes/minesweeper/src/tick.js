const TILE_SIZE = 32;

export function createTick(world, effects, buildings) {
  let pending = new Set();
  let next    = new Set();

  function tick() {
    if (pending.size === 0) return;

    effects.triggerScreenShake(5 + pending.size * 2);

    for (const key of pending) {
      const [tx, ty] = key.split(',').map(Number);
      const bld = buildings.getBuildingAt(tx, ty);
      const indestructible = bld?.type === 'lab' || bld?.type === 'lot';
      if (indestructible) continue;

      buildings.removeBuilding(tx, ty);
      world.mutateTile(tx, ty, { revealed: true, charred: true });
      effects.emitParticles(
        tx * TILE_SIZE + TILE_SIZE / 2,
        ty * TILE_SIZE + TILE_SIZE / 2,
        '#ff6600', 14
      );

      for (let dy = -1; dy <= 1; dy++) {
        for (let dx = -1; dx <= 1; dx++) {
          if (dx === 0 && dy === 0) continue;
          const nx = tx + dx, ny = ty + dy;
          const neighbor = world.getTile(nx, ny);
          if (neighbor.object?.type === 'mine' && !neighbor.charred) {
            next.add(`${nx},${ny}`);
          } else if (
            neighbor.object?.type !== 'mine' &&
            !(neighbor.revealed && !neighbor.object) &&
            !buildings.isOccupied(nx, ny)
          ) {
            world.mutateTile(nx, ny, { charred: true });
          }
        }
      }
    }

    world.scheduleSave();
    pending = next;
    next = new Set();
  }

  setInterval(tick, 150);

  function triggerExplosion(tx, ty) {
    pending.add(`${tx},${ty}`);
  }

  return { triggerExplosion };
}
