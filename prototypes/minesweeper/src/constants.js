export const NUMBER_COLORS = [
  '#ff8800', '#1a6bff', '#2d7a2d', '#e03333',
  '#00008b', '#8b0000', '#008b8b', '#222222', '#808080',
];

export function drawMineShape(ctx, tcx, tcy, ts, charred) {
  const r = ts * 0.20, spike = ts * 0.38;
  const color = charred ? '#111111' : '#1a1a1a';
  ctx.strokeStyle = color; ctx.fillStyle = color;
  ctx.lineWidth = ts * 0.09; ctx.lineCap = 'round';
  for (let i = 0; i < 8; i++) {
    const a = (i / 8) * Math.PI * 2;
    ctx.beginPath();
    ctx.moveTo(tcx + Math.cos(a) * r * 0.6, tcy + Math.sin(a) * r * 0.6);
    ctx.lineTo(tcx + Math.cos(a) * spike,    tcy + Math.sin(a) * spike);
    ctx.stroke();
  }
  ctx.beginPath(); ctx.arc(tcx, tcy, r, 0, Math.PI * 2); ctx.fill();
  if (!charred) {
    ctx.fillStyle = 'rgba(255,255,255,0.45)';
    ctx.beginPath(); ctx.arc(tcx - r * 0.32, tcy - r * 0.32, r * 0.28, 0, Math.PI * 2); ctx.fill();
  }
}
