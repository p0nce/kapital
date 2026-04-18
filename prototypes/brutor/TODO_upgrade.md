# Upgrade System — TODO & Suggestions

Current state: one upgrade (REPAIR, 1 MP, +1 HP on the most damaged part). MP caps at 5, earned only via straights.

## Structural tasks

- [ ] Extract upgrades into a data-driven list (`struct Upgrade { string name; int cost; string desc; void function(ref Player) apply; bool function(ref Player) isAvailable; }`) so new upgrades are a one-liner.
- [ ] Render the upgrade screen as a vertical list of N upgrade buttons instead of a single hard-coded REPAIR button. Grey out unaffordable / unavailable entries rather than hiding them.
- [ ] Show per-button cost + effect text uniformly (e.g. `REPAIR   1 MP   +1 HP on weakest part`).
- [ ] Keyboard shortcut: number keys 1..N select an upgrade, ESC goes back.
- [ ] Display a short toast / status line after purchase ("Repaired L.Arm +1 HP") instead of silent state change.
- [ ] Rename the `Phase.upgrade` screen title from `MAGIC` to `UPGRADE` for consistency with the button.
- [ ] Currently entering the upgrade screen costs nothing but also does nothing if no upgrade is affordable once inside — with multiple upgrades, some may be affordable and some not; the greyed-out list handles this cleanly.

## Gameplay polish

- [x] Decide whether using an upgrade ends the turn or is free. Right now it's free — once multiple upgrades exist, this may be too strong. => no, it doesn't end turn.
- [x] Consider a per-turn upgrade cap (e.g. one upgrade per turn) as an alternative to ending the turn. => no cap.
- [ ] Animate the HP bump on REPAIR (brief green flash on the repaired part) to mirror the damage flash.

## Suggested upgrades (cheap → expensive)

- [ ] **REINFORCED HELMET** (1 MP) — Helmet is more efficient. All enemy attacks are lowered by 2 dmg instead of 1 dmg.
- [ ] **SHIELD** (1 MP) — Restore left arm +1 HP. Displays a shield, all enemy attacks are lowered by 1 dmg.


### Dice manipulation

- [ ] **NUDGE** (1 MP) — pick one die and shift its value by +1 or -1 (wraps 1↔6 or clamps — pick one).
- [ ] **EXTRA ROLL** (2 MP) — grants one extra reroll this turn (raises the cap past `MAX_ROLLS` for the current turn only).
- [ ] **LOCK** (1 MP) — kept dice cannot be un-kept this turn (mostly thematic; useful if opponent gets dice-interference upgrades later).

## Balance questions to resolve

- MP economy: straights are rare. If most upgrades cost 2+ MP, players will almost never buy them. Either lower costs, raise MP gain rate, or add more ways to earn MP (e.g. any non-damaging roll yields 1 MP? full house yields MP + damage?).
- `MAX_MP = 5` combined with 3+ MP upgrades forces hoarding across many turns. Consider `MAX_MP = 3` + cheaper upgrades, or uncapped MP.
- Does the opponent being able to see your MP create interesting bluff play, or does it just telegraph intent? (Currently both MP bars are public.)

## Out of scope (flag before implementing)

- Persistent upgrades across matches / meta-progression.
- Tech tree with prerequisites.
- Per-player upgrade loadouts chosen before the match.
