export function createCamera(canvas) {
  const cam = {
    x: 0,
    y: 0,
    tileSize: 32,

    screenToTile(sx, sy) {
      return {
        tx: Math.floor((sx + this.x) / this.tileSize),
        ty: Math.floor((sy + this.y) / this.tileSize),
      };
    },

    visibleChunkRange(chunkSize) {
      const ts   = this.tileSize;
      const minTx = Math.floor(this.x / ts) - 1;
      const minTy = Math.floor(this.y / ts) - 1;
      const maxTx = Math.ceil((this.x + canvas.width)  / ts) + 1;
      const maxTy = Math.ceil((this.y + canvas.height) / ts) + 1;
      return {
        minCx: Math.floor(minTx / chunkSize),
        minCy: Math.floor(minTy / chunkSize),
        maxCx: Math.floor(maxTx / chunkSize),
        maxCy: Math.floor(maxTy / chunkSize),
      };
    },

    update(dt, keysHeld) {
      const spd = 6 * this.tileSize * dt;
      if (keysHeld.has('ArrowLeft')  || keysHeld.has('KeyA')) this.x -= spd;
      if (keysHeld.has('ArrowRight') || keysHeld.has('KeyD')) this.x += spd;
      if (keysHeld.has('ArrowUp')    || keysHeld.has('KeyW')) this.y -= spd;
      if (keysHeld.has('ArrowDown')  || keysHeld.has('KeyS')) this.y += spd;
    },
  };
  return cam;
}
