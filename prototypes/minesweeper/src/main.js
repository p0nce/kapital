import { createWorld }     from './world.js';
import { createCamera }    from './camera.js';
import { createRenderer }  from './renderer.js';
import { createInput }     from './input.js';
import { createTick }      from './tick.js';
import { createEffects }   from './effects.js';
import { createResources } from './resources.js';
import { createBuildings } from './buildings.js';
import { createBuildMenu } from './buildmenu.js';
import { createWorkers }   from './workers.js';
import { createResearch }  from './research.js';

const canvas = document.getElementById('game');
const ctx    = canvas.getContext('2d');

function resize() {
  canvas.width  = window.innerWidth;
  canvas.height = window.innerHeight;
}
resize();
window.addEventListener('resize', resize);

const SEED = (() => {
  let s = localStorage.getItem('seed');
  if (!s) { s = (Math.random() * 0xffffffff) >>> 0; localStorage.setItem('seed', s); }
  return Number(s);
})();
const world     = createWorld(SEED);
const cam       = createCamera(canvas);
const effects   = createEffects();
const renderer  = createRenderer(canvas, ctx);
const resources = createResources();
const buildings = createBuildings(world);
const buildMenu = createBuildMenu(resources);
const tick      = createTick(world, effects, buildings);
const research  = createResearch();
const workers   = createWorkers(world, buildings, resources, tick, research);
const input     = createInput(canvas, cam, world, tick, effects, resources, buildings, buildMenu, workers, research);

document.getElementById('btn-save').addEventListener('click', () => {
  world.saveAll();
  const btn = document.getElementById('btn-save');
  btn.textContent = 'Saved!';
  setTimeout(() => { btn.textContent = 'Save'; }, 1200);
});

document.getElementById('btn-export').addEventListener('click', () => {
  world.saveAll();
  const data = {};
  for (let i = 0; i < localStorage.length; i++) {
    const key = localStorage.key(i);
    data[key] = localStorage.getItem(key);
  }
  const blob = new Blob([JSON.stringify(data)], { type: 'application/json' });
  const url  = URL.createObjectURL(blob);
  const a    = document.createElement('a');
  a.href     = url;
  a.download = 'minesweeper.json';
  a.click();
  URL.revokeObjectURL(url);
});

document.getElementById('btn-import').addEventListener('click', () => {
  const input = document.createElement('input');
  input.type   = 'file';
  input.accept = '.json';
  input.onchange = e => {
    const reader = new FileReader();
    reader.onload = ev => {
      const data = JSON.parse(ev.target.result);
      localStorage.clear();
      for (const [key, value] of Object.entries(data)) {
        localStorage.setItem(key, value);
      }
      location.reload();
    };
    reader.readAsText(e.target.files[0]);
  };
  input.click();
});

document.getElementById('hard-reset').addEventListener('click', () => {
  const newSeed = (Math.random() * 0xffffffff) >>> 0;
  localStorage.clear();
  localStorage.setItem('seed', newSeed);
  location.reload();
});

let lastTime = 0;
function loop(ts) {
  const dt = Math.min((ts - lastTime) / 1000, 0.1);
  lastTime = ts;
  effects.update(dt);
  research.update(dt, workers.getLabWorkerCount());
  workers.update(dt);
  cam.update(dt, input.keysHeld);
  renderer.render(world, cam, effects, input.getHoveredTile(), buildings, workers, input.getActiveLotRadius());
  requestAnimationFrame(loop);
}
requestAnimationFrame(loop);
