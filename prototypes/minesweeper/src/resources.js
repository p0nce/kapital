export function createResources() {
  const counts    = {};
  const listeners = [];

  const _saved = JSON.parse(localStorage.getItem('resources') || '{}');
  for (const [res, amt] of Object.entries(_saved)) {
    if (amt <= 0) continue;
    counts[res] = amt;
    const row = document.getElementById(`res-row-${res}`);
    if (row) row.style.display = 'flex';
    const el = document.getElementById(`res-${res}`);
    if (el) el.textContent = amt;
  }

  function _notify() {
    for (const fn of listeners) fn();
    try { localStorage.setItem('resources', JSON.stringify(counts)); } catch (e) {}
  }

  function add(resource, amount) {
    if (!(resource in counts)) {
      counts[resource] = 0;
      const row = document.getElementById(`res-row-${resource}`);
      if (row) row.style.display = 'flex';
    }
    counts[resource] += amount;
    const el = document.getElementById(`res-${resource}`);
    if (el) el.textContent = counts[resource];
    _notify();
  }

  function spend(resource, amount) {
    if ((counts[resource] || 0) < amount) return false;
    counts[resource] -= amount;
    const el = document.getElementById(`res-${resource}`);
    if (el) el.textContent = counts[resource];
    _notify();
    return true;
  }

  function canAfford(costObj) {
    return Object.entries(costObj).every(([res, amt]) => (counts[res] || 0) >= amt);
  }

  function onChange(fn) { listeners.push(fn); }

  return { add, spend, canAfford, onChange };
}
