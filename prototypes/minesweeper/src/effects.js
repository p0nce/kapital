export function createEffects() {
  let shakeIntensity = 0;
  const tileShakes = new Map(); // "tx,ty" -> { elapsed, duration }
  const particles  = [];

  function triggerScreenShake(intensity) {
    shakeIntensity = Math.max(shakeIntensity, intensity);
  }

  function triggerTileShake(tx, ty) {
    tileShakes.set(`${tx},${ty}`, { elapsed: 0, duration: 0.25 });
  }

  function emitParticles(worldX, worldY, color, count) {
    for (let i = 0; i < count; i++) {
      const angle = Math.random() * Math.PI * 2;
      const speed = 40 + Math.random() * 120;
      particles.push({
        x: worldX, y: worldY,
        vx: Math.cos(angle) * speed,
        vy: Math.sin(angle) * speed - 30,
        life: 1,
        decay: 2 + Math.random() * 2,
        size: 2 + Math.random() * 3,
        color,
      });
    }
  }

  function update(dt) {
    shakeIntensity *= Math.max(0, 1 - dt * 10);
    if (shakeIntensity < 0.2) shakeIntensity = 0;

    for (const [key, s] of tileShakes) {
      s.elapsed += dt;
      if (s.elapsed >= s.duration) tileShakes.delete(key);
    }

    for (let i = particles.length - 1; i >= 0; i--) {
      const p = particles[i];
      p.x  += p.vx * dt;
      p.y  += p.vy * dt;
      p.vy += 250 * dt; // gravity
      p.life -= p.decay * dt;
      if (p.life <= 0) particles.splice(i, 1);
    }
  }

  function getScreenShakeOffset() {
    if (shakeIntensity < 0.2) return { x: 0, y: 0 };
    const a = Math.random() * Math.PI * 2;
    return { x: Math.cos(a) * shakeIntensity, y: Math.sin(a) * shakeIntensity };
  }

  function getTileShakeOffset(tx, ty) {
    const s = tileShakes.get(`${tx},${ty}`);
    if (!s) return { x: 0, y: 0 };
    const amp = (1 - s.elapsed / s.duration) * 4;
    return {
      x: Math.sin(s.elapsed * 80) * amp,
      y: Math.cos(s.elapsed * 65) * amp,
    };
  }

  return { triggerScreenShake, triggerTileShake, emitParticles, update,
           getScreenShakeOffset, getTileShakeOffset, particles };
}
