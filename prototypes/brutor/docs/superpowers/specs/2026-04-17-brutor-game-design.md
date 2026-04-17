# Brutor - Dice Combat Game Design Spec

## Overview

A 2-player turn-based dice combat game built with the D turtle library. Players roll 5 dice (Yahtzee-style: up to 3 rolls, keeping dice between rolls) to form combinations that deal damage to their opponent's avatar body parts. A player loses when their head reaches 0 HP.

## Tech Stack

- **Language:** D
- **Framework:** turtle library (TurtleGame)
- **Graphics:** Canvas API for dice, avatars, HP bars, animations
- **Text:** Textmode API for labels, status messages, buttons
- **Input:** Mouse only (click dice to keep/release, click buttons to roll/confirm)

## Module Structure

```
source/
  main.d           -- entry point, TurtleGame subclass, orchestrates everything
  brutor/
    game.d         -- game state machine, turn logic, player state
    dice.d         -- dice values, rolling, keeping, combination detection
    avatar.d       -- body part HP, geometric avatar rendering (canvas API)
    combat.d       -- maps dice combinations to damage, applies to avatar
```

### Module Responsibilities

**main.d** - Inherits `TurtleGame`. Owns a `GameState`. Routes `update()`, `draw()`, `mousePressed()` to the game state. Sets up window title, background color, console size.

**game.d** - Contains `GameState` struct and `Player` struct. Manages turn phases, active player, rolls remaining. `Player` holds a `DiceSet` and an `Avatar`. Provides `update()` and `draw()` methods.

**dice.d** - Contains `DiceSet` struct: 5 dice values (1-6), 5 kept booleans. Provides `roll()` (re-rolls un-kept dice), `toggleKeep(index)`, `reset()`, and `analyze()` which returns detected combinations.

**avatar.d** - Contains `Avatar` struct: 6 body parts each with HP (int, 0-5). Provides `drawAvatar()` using canvas API (geometric shapes), `isAlive()` (head HP > 0), `applyDamage()`.

**combat.d** - Stateless functions. Takes dice analysis results, returns a list of damage actions. Each action is a body part index + damage amount (or special: "set to 1", "set to 0").

## Game Flow

### State Machine

```
ROLL_PHASE -> SELECT_PHASE -> ROLL_PHASE  (up to 3 rolls total)
                           -> RESOLVE_PHASE  (after 3rd roll or player clicks CONFIRM)
RESOLVE_PHASE -> switch active player -> ROLL_PHASE
GAME_OVER -> click to restart
```

### Turn Sequence

1. Turn starts: all 5 dice un-kept, `rollsRemaining = 3`
2. **ROLL_PHASE:** Dice are rolled automatically at turn start. `rollsRemaining` decrements.
3. **SELECT_PHASE:** Player clicks dice to toggle keep/release. Player clicks ROLL to re-roll un-kept dice (returns to ROLL_PHASE) or clicks CONFIRM to finalize.
4. If `rollsRemaining == 0` after a roll, go directly to RESOLVE_PHASE (player can no longer re-roll).
5. **RESOLVE_PHASE:** Analyze dice, compute damage, apply to opponent's avatar. If opponent's head HP reaches 0, go to GAME_OVER. Otherwise, switch active player and start new turn.
6. **GAME_OVER:** Display winner. Click to restart.

## Body Parts

Each avatar has 6 body parts, each starting at 5 HP:

| Dice Value | Body Part |
|---|---|
| 1 | Left leg |
| 2 | Right leg |
| 3 | Left arm |
| 4 | Right arm |
| 5 | Chest |
| 6 | Head |

## Dice Combinations & Damage

After a turn ends, the 5 dice are analyzed for groups of matching values:

| Combination | Condition | Effect |
|---|---|---|
| Single | Only 1 of a value | No damage |
| Pair | Exactly 2 of a value | 2 damage to that body part |
| Three of a kind | Exactly 3 of a value | 3 damage to that body part |
| Full house | 3 of one + 2 of another | 3 damage to each of the two body parts |
| Four of a kind | Exactly 4 of a value | Set that body part HP to 1 (if already <=1, no effect) |
| Yahtzee | All 5 same value | Body part instantly destroyed (HP = 0) |

Multiple independent groups are possible (e.g., two pairs = 2 damage to each of two body parts).

### Edge Cases

- Damage cannot reduce HP below 0
- If head reaches 0, game ends immediately during resolve phase
- Four of a kind on a body part already at 0 HP: no effect
- Yahtzee on head (all 6s): instant win

## Screen Layout

```
+----------------------------------------------------+
|  PLAYER 1 (text)                PLAYER 2 (text)    |
|                                                     |
|  +--Avatar--+                   +--Avatar--+        |
|  |   (o)    |                   |   (o)    |        |
|  |  -|--|   |                   |  -|--|   |        |
|  |   / \   |                   |   / \   |        |
|  +----------+                   +----------+        |
|   HP bars per part              HP bars per part    |
|                                                     |
|            [die] [die] [die] [die] [die]            |
|            (click to keep/release)                  |
|                                                     |
|     [ROLL] (N remaining)        [CONFIRM]           |
|     Status: "Player 1's turn"                       |
+----------------------------------------------------+
```

### Visual Details

**Avatars (canvas API):**
- Head: filled circle
- Chest: filled rectangle
- Arms: thin filled rectangles, angled from chest sides
- Legs: thin filled rectangles, angled from chest bottom
- Body parts at 0 HP: not drawn (visually missing)
- Color coding: healthy = green shades, damaged = yellow/red gradient based on remaining HP

**Dice (canvas API):**
- Filled rounded rectangles (or squares)
- Pips as filled circles in standard dice layout
- Normal dice: white background, black pips
- Kept dice: highlighted border/background color (e.g., yellow or blue tint)

**HP Bars (canvas API):**
- Small horizontal bars under or beside each body part on the avatar
- Green -> yellow -> red gradient based on remaining HP

**Text (textmode API):**
- Player names/labels
- "Player N's turn" status
- Roll count remaining
- Button labels (ROLL, CONFIRM)
- Game over / winner message

## Input

Mouse only:
- **Click a die:** Toggle kept/released state (only during SELECT_PHASE)
- **Click ROLL button:** Re-roll un-kept dice (only during SELECT_PHASE when rollsRemaining > 0)
- **Click CONFIRM button:** End turn and resolve damage (during SELECT_PHASE)
- **Click anywhere during GAME_OVER:** Restart game
