// ─── Tile atlas ───────────────────────────────────────────────────────────────
// Editable pixel-art sprite sheet. See docs/superpowers/specs/2026-04-15-tile-atlas-design.md
// Sheet: 48 × 80 px. 8×8 tiles, 6 animation frames per row, 10 rows.

const TILE_SIZE     = 8;
const TILE_FRAMES   = 6;
const TILE_FRAME_MS = 150;

const TILE_ROW = {
  tower_alone:    0,
  tower_up:       1,
  tower_down:     2,
  platform_base:  3,
  platform_left:  4,
  platform_right: 5,
  flag:           6,
  cannon:         7,
  apartment:      8,
  ground:         9,
  tower_mid:     10,
};

const TileAtlas = {
  image: new Image(),
  ready: null,
  drawTile(ctx, name, x, y, now, scale = 1) {
    const img = this.image;
    if (!img.complete || !img.naturalWidth) return;
    const row = TILE_ROW[name];
    if (row === undefined) return;
    const frame = Math.floor(now / TILE_FRAME_MS) % TILE_FRAMES;
    const prev = ctx.imageSmoothingEnabled;
    ctx.imageSmoothingEnabled = false;
    ctx.drawImage(
      img,
      frame * TILE_SIZE, row * TILE_SIZE, TILE_SIZE, TILE_SIZE,
      x, y, TILE_SIZE * scale, TILE_SIZE * scale
    );
    ctx.imageSmoothingEnabled = prev;
  },
};

TileAtlas.ready = new Promise((resolve, reject) => {
  TileAtlas.image.onload  = () => resolve();
  TileAtlas.image.onerror = (e) => reject(e);
});
TileAtlas.image.src = 'assets/atlas.png';
