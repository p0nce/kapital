import { BUILDING_TYPES } from './buildings.js';
import { NUMBER_COLORS, drawMineShape } from './constants.js';

const PREVIEW_SIZE = 48;

function drawWirePreview(cv) {
  const c    = cv.getContext('2d');
  const s    = PREVIEW_SIZE;
  const tcx  = s / 2, tcy = s / 2;
  const lw   = Math.max(2, s * 0.11);

  c.clearRect(0, 0, s, s);

  // Tile background
  c.fillStyle = '#b8b8b8';
  c.fillRect(1, 1, s - 2, s - 2);

  // 4-way connected wire (preview always shows fully connected)
  c.strokeStyle = '#ffcc00';
  c.lineWidth   = lw;
  c.lineCap     = 'round';
  c.beginPath();
  c.moveTo(1,   tcy); c.lineTo(s - 1, tcy);
  c.moveTo(tcx, 1);   c.lineTo(tcx,   s - 1);
  c.stroke();

  // Center node
  c.fillStyle = '#ffcc00';
  c.beginPath();
  c.arc(tcx, tcy, lw * 0.8, 0, Math.PI * 2);
  c.fill();
}

function drawMinePreview(cv) {
  const c = cv.getContext('2d');
  const s = PREVIEW_SIZE;
  c.clearRect(0, 0, s, s);
  c.fillStyle = '#b8b8b8';
  c.fillRect(1, 1, s - 2, s - 2);
  c.save();
  drawMineShape(c, s / 2, s / 2, s, false);
  c.restore();
}

function drawLabPreview(cv) {
  const c = cv.getContext('2d');
  const s = PREVIEW_SIZE;
  c.clearRect(0, 0, s, s);
  c.fillStyle = '#1a2a1a';
  c.fillRect(1, 1, s - 2, s - 2);
  c.strokeStyle = '#3a8a3a';
  c.lineWidth = 2;
  c.strokeRect(3, 3, s - 6, s - 6);
  const cell = (s - 6) / 3;
  c.strokeStyle = '#2a4a2a';
  c.lineWidth = 1;
  for (let i = 1; i < 3; i++) {
    c.beginPath(); c.moveTo(3 + cell * i, 3); c.lineTo(3 + cell * i, s - 3); c.stroke();
    c.beginPath(); c.moveTo(3, 3 + cell * i); c.lineTo(s - 3, 3 + cell * i); c.stroke();
  }
  c.fillStyle = '#44cc44';
  c.font = `bold ${Math.floor(s * 0.25)}px monospace`;
  c.textAlign = 'center';
  c.textBaseline = 'middle';
  c.fillText('LAB', s / 2, s / 2);
}

function drawLotPreview(cv) {
  const c = cv.getContext('2d');
  const s = PREVIEW_SIZE;
  c.clearRect(0, 0, s, s);
  c.fillStyle = '#2a1e0a';
  c.fillRect(1, 1, s - 2, s - 2);
  c.strokeStyle = '#8a6428';
  c.lineWidth = 2;
  c.strokeRect(3, 3, s - 6, s - 6);
  c.strokeStyle = '#3a2a10';
  c.lineWidth = 1;
  c.beginPath();
  c.moveTo(s / 2, 3); c.lineTo(s / 2, s - 3);
  c.moveTo(3, s / 2); c.lineTo(s - 3, s / 2);
  c.stroke();
  // person
  c.fillStyle = '#d4a050';
  c.beginPath(); c.arc(s / 2, s / 2 + s * 0.08, s * 0.14, 0, Math.PI * 2); c.fill();
  c.fillStyle = '#a07030';
  c.beginPath(); c.arc(s / 2, s / 2 - s * 0.13, s * 0.09, 0, Math.PI * 2); c.fill();
}

const COST_ABBREV  = { mine: '✸', charcoal: 'C', wood: 'W' };
const COST_COLORS  = { mine: '#cc4444' };

const PREVIEW_DRAW = {
  wire: drawWirePreview,
  mine: drawMinePreview,
  lab:  drawLabPreview,
  lot:  drawLotPreview,
};

export function createBuildMenu(resources) {
  let selected = null;
  const panel     = document.getElementById('build-menu');
  const buttons   = {};
  const discovered = new Set(JSON.parse(localStorage.getItem('discovered') || '[]'));

  for (const [key, def] of Object.entries(BUILDING_TYPES)) {
    const btn = document.createElement('div');
    btn.className     = 'build-btn';
    btn.style.display = 'none';

    // Wire preview canvas
    const cv = document.createElement('canvas');
    cv.className = 'build-preview';
    cv.width = cv.height = PREVIEW_SIZE;
    if (PREVIEW_DRAW[key]) PREVIEW_DRAW[key](cv);
    btn.appendChild(cv);

    // Cost (small)
    const costEl = document.createElement('div');
    costEl.className = 'build-btn-cost';
    for (const [res, amt] of Object.entries(def.cost)) {
      const n    = parseInt(res, 10);
      const chip = document.createElement('span');
      chip.className   = 'build-cost-chip';
      chip.style.color = !isNaN(n) ? (NUMBER_COLORS[n] || '#ddd') : (COST_COLORS[res] || '#aaa');
      chip.textContent = !isNaN(n) ? res : (COST_ABBREV[res] ?? res[0]);
      costEl.appendChild(chip);
      if (amt > 1) {
        const x = document.createElement('span');
        x.style.color    = '#777';
        x.style.fontSize = '10px';
        x.textContent    = `×${amt}`;
        costEl.appendChild(x);
      }
    }
    btn.appendChild(costEl);

    btn.addEventListener('click', () => selected === key ? deselect() : select(key));
    panel.appendChild(btn);
    buttons[key] = btn;
  }

  function select(type) {
    selected = type;
    for (const [k, b] of Object.entries(buttons)) b.classList.toggle('selected', k === type);
  }

  function deselect() {
    selected = null;
    for (const b of Object.values(buttons)) b.classList.remove('selected');
  }

  function update() {
    for (const [key, def] of Object.entries(BUILDING_TYPES)) {
      const can = resources.canAfford(def.cost);
      if (can && !discovered.has(key)) {
        discovered.add(key);
        try { localStorage.setItem('discovered', JSON.stringify([...discovered])); } catch (e) {}
      }
      const show = discovered.has(key);
      buttons[key].style.display = show ? 'flex' : 'none';
      buttons[key].classList.toggle('unaffordable', show && !can);
      if (!can && selected === key) deselect();
    }
  }

  resources.onChange(update);

  return { getSelectedType: () => selected, deselect };
}
