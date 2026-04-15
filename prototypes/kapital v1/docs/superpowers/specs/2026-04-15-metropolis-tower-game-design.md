# Metropolis Tower — Game Design Spec
_Date: 2026-04-15_

## Overview

A two-player hot-seat turn-based city builder played on an HTML Canvas. Each player builds a tower 7 columns wide from a ground base, racing to reach the sky limit first. Cannons let players destroy enemy blocks (causing collapses) to slow their opponent.

Visual style: pixel art with a 1890 Metropolis aesthetic — dark smoky skies, wrought-iron blocks, gothic silhouettes, gas-lamp glow.

---

## Players & Turn Structure

- **2 players**, alternating turns on the same device.
- On your turn:
  1. **Income phase** — collect passive income from your existing blocks.
  2. **Build phase** — spend money to place any number of blocks (limited by wallet).
  3. **Fire phase** — optionally fire one cannon at an enemy column (free).
- Turn ends manually (e.g. "End Turn" button).

---

## Block Types

| Block | Size | Cost | Income/turn | Notes |
|---|---|---|---|---|
| Tower | 1×2 | $2 | $2 ($1/cell) | Stackable; adds height quickly |
| Platform | 3×1 | $3 | $3 ($1/cell) | Levels surface; supported by middle column only |
| Cannon | 1×1 | $5 | $1 | Cannot be built on top of directly; platform can bridge over it |
| Special | 1×1 | $4 | $5 | High income generator; same structural rules as a normal 1×1 block |

**Income** is calculated at the start of each turn: $1 per normal block cell owned, $5 per Special block cell.

---

## Placement Rules

- All blocks must be placed on top of existing structure or ground.
- **Tower**: placed on a single column; occupies 2 vertical cells stacked.
- **Platform**: spans 3 consecutive columns at the height of the middle column's top + 1. Only the middle column needs solid support beneath.
- **Cannon**: placed on any non-cannon top cell. Nothing can be placed directly on top of a cannon. A platform whose middle cell is not a cannon can bridge over one.
- **Special**: placed like a 1×1 block on any column top.

---

## Firing & Destruction

- Player selects one of their placed cannons, then selects a target column on the enemy's side.
- A cannonball travels horizontally at the cannon's row height.
- It hits and destroys the **topmost occupied cell** in the target column.
- After destruction, a **recursive fall pass** runs: any block with no solid support directly below drops one row. Repeats until the grid is stable.
- Firing is free and limited to once per turn.

---

## Win Condition

- The **sky limit** is a fixed row (e.g. 20 blocks above ground), shown as a glowing line across both towers.
- At the start of a player's turn, if their highest block is at or above the sky limit, that player wins.

---

## Starting State

- Each player starts with a small preset base: a 3-wide ground platform + one tower in the centre column.
- Starting wallet: **$5**.

---

## Grid Model

- Each player owns a **7-column × N-row grid** (N = sky limit + buffer).
- Ground row (row 0) is indestructible.
- Cell values: `empty | tower | platform | cannon | special | ground`

---

## Animation State Machine

```
IDLE
  → BUILD_ANIM   (block drops into place, ~300ms)
  → FIRE_ANIM    (cannonball travels across canvas, ~500ms)
  → FALL_ANIM    (cascade: each falling step animated, ~150ms/row)
  → IDLE
```

Game input is locked during any animation state.

---

## Rendering

- **Canvas layout**: Player 1 tower left, Player 2 tower right, gap in the middle for cannonball travel.
- **HUD**: top bar shows player name, wallet ($), and whose turn it is.
- **Sky limit**: glowing horizontal line at the top of both grids.
- **Aesthetic targets**:
  - Dark, near-black sky (#0a0a0f)
  - Wrought-iron block textures in pixel art (hand-drawn feel with slight highlight/shadow per block face)
  - Gas-lamp warm glow (#f5c842) on HUD and active-player indicator
  - Gothic tower silhouette shapes in the background
  - Cannon blocks have a visible barrel pointing toward the opponent

---

## Single File Delivery

The entire game ships as a **single `index.html`** file with inline CSS and JS. No build tools, no dependencies.
