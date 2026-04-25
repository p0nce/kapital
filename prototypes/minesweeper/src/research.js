const RESEARCH_RATE = 1; // pts/sec per lab worker

export const UPGRADE_DEFS = {
  worker_speed: {
    name: 'Worker Speed',
    desc: '+50% speed / level',
    costs: [60, 150, 375, 940, 2350],
  },
  worker_range: {
    name: 'Worker Range',
    desc: '+5 tile radius / level',
    costs: [50, 130, 320, 800, 2000],
  },
};

export function createResearch() {
  let state = JSON.parse(localStorage.getItem('research') || 'null')
    || { levels: {}, current: null, progresses: {} };

  // migrate old single-progress saves
  if ('progress' in state && !state.progresses) {
    state.progresses = state.current ? { [state.current]: state.progress } : {};
    delete state.progress;
  }

  function _save() {
    try { localStorage.setItem('research', JSON.stringify(state)); } catch (e) {}
  }

  function getLevel(name)    { return state.levels[name] ?? 0; }
  function getProgress(name) { return state.progresses[name] ?? 0; }

  function getWorkerSpeedMult() { return Math.pow(1.5, getLevel('worker_speed')); }
  function getWorkerRange()     { return 10 + getLevel('worker_range') * 5; }

  function startResearch(name) {
    const def = UPGRADE_DEFS[name];
    if (!def) return;
    if (getLevel(name) >= def.costs.length) return;
    state.current = name;
    _save();
  }

  function cancelResearch() {
    state.current = null; // progress for the upgrade is preserved in progresses
    _save();
  }

  function update(dt, labWorkers) {
    if (!state.current || labWorkers === 0) return;
    const name = state.current;
    state.progresses[name] = (state.progresses[name] ?? 0) + labWorkers * RESEARCH_RATE * dt;
    const needed = UPGRADE_DEFS[name].costs[getLevel(name)];
    if (state.progresses[name] >= needed) {
      state.levels[name] = getLevel(name) + 1;
      state.progresses[name] = 0;
      state.current = null;
      _save();
    }
  }

  function getState() { return state; }
  function getDefs()  { return UPGRADE_DEFS; }

  return { update, getLevel, getProgress, getWorkerSpeedMult, getWorkerRange, startResearch, cancelResearch, getState, getDefs };
}
