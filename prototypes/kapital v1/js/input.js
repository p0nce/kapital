// ─── Pointer helpers ─────────────────────────────────────────────────────────
function canvasPos(e) {
  const rect = canvas.getBoundingClientRect();
  return {
    mx: (e.clientX - rect.left) * (canvas.width  / rect.width),
    my: (e.clientY - rect.top)  * (canvas.height / rect.height),
  };
}

function inRect(mx, my, r) {
  return mx >= r.x && mx <= r.x + r.w && my >= r.y && my <= r.y + r.h;
}

// ─── Events ──────────────────────────────────────────────────────────────────
canvas.addEventListener('mousemove', e => {
  const { mx } = canvasPos(e);
  ui.hoverCol = (mx >= 0 && mx < GRID_W) ? Math.floor((mx + cameraX) / CELL) : -1;
});

canvas.addEventListener('click', e => {
  const { mx, my } = canvasPos(e);

  if (state.phase === 'WIN') {
    if (inRect(mx, my, winState.replayBtn)) resetGame();
    return;
  }
  if (state.phase !== 'IDLE') return;

  // End Turn
  if (inRect(mx, my, BTN)) {
    endTurn();
    ui.selectedType = 'tower';
    return;
  }

  // Build buttons
  for (const b of buildBtns) {
    if (inRect(mx, my, b)) {
      ui.selectedType = ui.selectedType === b.type ? null : b.type;
      return;
    }
  }

  // Grid click
  if (mx < GRID_W) {
    const col = Math.floor((mx + cameraX) / CELL);
    if (ui.selectedType) {
      placeBlock(ui.selectedType, col, state.turn);
    }
  }
});

// ─── Bootstrap ───────────────────────────────────────────────────────────────
initGrid();
snapCameraOn(0);
requestAnimationFrame(render);
