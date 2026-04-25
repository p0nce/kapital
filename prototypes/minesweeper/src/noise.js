// seededHash(seed)(x, y) → deterministic float in [0, 1]
export function seededHash(seed) {
  return function hash(x, y) {
    let h = (seed | 0) ^ Math.imul(x | 0, 374761393) ^ Math.imul(y | 0, 1103515245);
    h = Math.imul(h ^ (h >>> 13), 1664525) + 1013904223;
    h = Math.imul(h ^ (h >>> 15), 2246822519);
    return (h >>> 0) / 0xFFFFFFFF;
  };
}
