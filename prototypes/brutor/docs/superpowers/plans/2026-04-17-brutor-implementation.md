# Brutor Dice Combat Game Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a 2-player turn-based dice combat game in D using the turtle library, where players roll dice Yahtzee-style to damage opponent body parts.

**Architecture:** Multi-module design with `main.d` as the TurtleGame entry point, and four modules under `brutor/`: `dice.d` (dice logic + combination detection), `avatar.d` (body parts + canvas rendering), `combat.d` (damage resolution), and `game.d` (state machine + orchestration). Canvas API draws dice/avatars/HP bars, textmode API handles text labels.

**Tech Stack:** D language, turtle library (TurtleGame, Canvas API, textmode/TM_Console), dub build system.

---

### Task 1: Project Setup & Skeleton

**Files:**
- Create: `source/main.d`
- Create: `source/brutor/package.d`
- Create: `dub.json`

- [ ] **Step 1: Create `dub.json`**

```json
{
  "name": "brutor",
  "targetType": "executable",
  "dependencies": {
    "turtle": "~>0.0"
  },
  "sourcePaths": ["source"],
  "importPaths": ["source"]
}
```

- [ ] **Step 2: Create the package module at `source/brutor/package.d`**

```d
module brutor;

public import brutor.dice;
public import brutor.avatar;
public import brutor.combat;
public import brutor.game;
```

- [ ] **Step 3: Create `source/main.d` with a minimal TurtleGame**

```d
import turtle;

int main(string[] args)
{
    runGame(new BrutorGame);
    return 0;
}

class BrutorGame : TurtleGame
{
    override void load()
    {
        setBackgroundColor(color("#1a1a2e"));
        setTitle("Brutor");
        console.size(60, 30);
    }

    override void update(double dt)
    {
        if (keyboard.isDown("escape")) exitGame;
    }

    override void draw()
    {
        with (console)
        {
            cls();
            locate(20, 14);
            fg(TM_colorWhite);
            print("BRUTOR");
        }
    }
}
```

- [ ] **Step 4: Build and run to verify window appears**

Run: `dub run`
Expected: A window titled "Brutor" with dark background and "BRUTOR" text.

- [ ] **Step 5: Commit**

```bash
git add source/main.d source/brutor/package.d dub.json
git commit -m "feat: project skeleton with turtle game loop"
```

---

### Task 2: Dice Data & Logic (`brutor/dice.d`)

**Files:**
- Create: `source/brutor/dice.d`

- [ ] **Step 1: Create `source/brutor/dice.d` with DiceSet struct and types**

```d
module brutor.dice;

import turtle;

enum NUM_DICE = 5;
enum MAX_ROLLS = 3;

/// Body part indices corresponding to dice values 1-6
enum BodyPart : int
{
    leftLeg = 0,   // dice value 1
    rightLeg = 1,  // dice value 2
    leftArm = 2,   // dice value 3
    rightArm = 3,  // dice value 4
    chest = 4,     // dice value 5
    head = 5,      // dice value 6
}

enum NUM_BODY_PARTS = 6;

/// Maps dice face value (1-6) to body part index (0-5)
BodyPart diceToBodyPart(int diceValue)
{
    return cast(BodyPart)(diceValue - 1);
}

/// The type of combination detected for a group of matching dice
enum ComboType
{
    single,       // 1 die  - no damage
    pair,         // 2 dice - 2 damage
    threeOfAKind, // 3 dice - 3 damage
    fourOfAKind,  // 4 dice - set HP to 1
    yahtzee,      // 5 dice - destroy body part
}

/// A single detected combination from analyzing the dice
struct Combo
{
    ComboType type;
    BodyPart target;  // which body part this hits
}

struct DiceSet
{
    int[NUM_DICE] values = [1, 1, 1, 1, 1];
    bool[NUM_DICE] kept = [false, false, false, false, false];

    /// Roll all un-kept dice
    void roll()
    {
        foreach (i; 0 .. NUM_DICE)
        {
            if (!kept[i])
                values[i] = randInt(1, 7); // randInt is [min, max)
        }
    }

    /// Toggle the kept state of a die
    void toggleKeep(int index)
    {
        kept[index] = !kept[index];
    }

    /// Reset all dice to un-kept state
    void reset()
    {
        kept[] = false;
    }

    /// Analyze the current dice and return all combinations found.
    /// A full house returns TWO combos (threeOfAKind + pair).
    Combo[] analyze()
    {
        // Count occurrences of each face value
        int[7] counts = 0; // index 0 unused, 1-6 for dice faces
        foreach (v; values)
            counts[v]++;

        Combo[] combos;
        foreach (face; 1 .. 7)
        {
            int c = counts[face];
            if (c == 0) continue;

            BodyPart bp = diceToBodyPart(face);

            if (c == 5)
                combos ~= Combo(ComboType.yahtzee, bp);
            else if (c == 4)
                combos ~= Combo(ComboType.fourOfAKind, bp);
            else if (c == 3)
                combos ~= Combo(ComboType.threeOfAKind, bp);
            else if (c == 2)
                combos ~= Combo(ComboType.pair, bp);
            // c == 1 is a single, no damage, skip
        }

        return combos;
    }
}
```

- [ ] **Step 2: Build to verify compilation**

Run: `dub build`
Expected: Compiles without errors (module is imported via `brutor/package.d`).

- [ ] **Step 3: Commit**

```bash
git add source/brutor/dice.d
git commit -m "feat: dice data structures and combination analysis"
```

---

### Task 3: Avatar Data & Rendering (`brutor/avatar.d`)

**Files:**
- Create: `source/brutor/avatar.d`

- [ ] **Step 1: Create `source/brutor/avatar.d` with Avatar struct and canvas rendering**

```d
module brutor.avatar;

import turtle;
import brutor.dice;
import std.algorithm : max;

enum MAX_HP = 5;

struct Avatar
{
    int[NUM_BODY_PARTS] hp;
    
    /// Initialize all body parts to max HP
    void reset()
    {
        hp[] = MAX_HP;
    }

    /// Is this avatar still alive? (head HP > 0)
    bool isAlive()
    {
        return hp[BodyPart.head] > 0;
    }

    /// Apply flat damage to a body part (clamp to 0)
    void applyDamage(BodyPart part, int amount)
    {
        hp[part] = max(0, hp[part] - amount);
    }

    /// Set a body part's HP to a specific value (for four-of-a-kind)
    void setHP(BodyPart part, int value)
    {
        if (hp[part] > value)
            hp[part] = value;
    }

    /// Destroy a body part entirely
    void destroy(BodyPart part)
    {
        hp[part] = 0;
    }

    /// Draw the avatar at the given center position using the canvas API.
    /// cx, cy is the center of the chest area.
    void draw(Canvas* c, float cx, float cy)
    {
        enum headRadius = 18.0f;
        enum chestW = 40.0f;
        enum chestH = 50.0f;
        enum armW = 12.0f;
        enum armH = 45.0f;
        enum legW = 14.0f;
        enum legH = 50.0f;

        float chestTop = cy - chestH / 2;
        float chestBot = cy + chestH / 2;

        // Head (centered above chest)
        if (hp[BodyPart.head] > 0)
        {
            float headCy = chestTop - headRadius - 4;
            c.save();
            c.fillStyle = hpColor(hp[BodyPart.head]);
            c.beginPath();
            c.arc(cx, headCy, headRadius, 0, 6.2832f);
            c.fill();
            c.restore();
        }

        // Chest
        if (hp[BodyPart.chest] > 0)
        {
            c.save();
            c.fillStyle = hpColor(hp[BodyPart.chest]);
            c.beginPath();
            c.moveTo(cx - chestW / 2, chestTop);
            c.lineTo(cx + chestW / 2, chestTop);
            c.lineTo(cx + chestW / 2, chestBot);
            c.lineTo(cx - chestW / 2, chestBot);
            c.closePath();
            c.fill();
            c.restore();
        }

        // Left arm
        if (hp[BodyPart.leftArm] > 0)
        {
            c.save();
            c.fillStyle = hpColor(hp[BodyPart.leftArm]);
            c.beginPath();
            float ax = cx - chestW / 2 - armW;
            float ay = chestTop;
            c.moveTo(ax, ay);
            c.lineTo(ax + armW, ay);
            c.lineTo(ax + armW, ay + armH);
            c.lineTo(ax, ay + armH);
            c.closePath();
            c.fill();
            c.restore();
        }

        // Right arm
        if (hp[BodyPart.rightArm] > 0)
        {
            c.save();
            c.fillStyle = hpColor(hp[BodyPart.rightArm]);
            c.beginPath();
            float ax = cx + chestW / 2;
            float ay = chestTop;
            c.moveTo(ax, ay);
            c.lineTo(ax + armW, ay);
            c.lineTo(ax + armW, ay + armH);
            c.lineTo(ax, ay + armH);
            c.closePath();
            c.fill();
            c.restore();
        }

        // Left leg
        if (hp[BodyPart.leftLeg] > 0)
        {
            c.save();
            c.fillStyle = hpColor(hp[BodyPart.leftLeg]);
            c.beginPath();
            float lx = cx - legW - 2;
            float ly = chestBot;
            c.moveTo(lx, ly);
            c.lineTo(lx + legW, ly);
            c.lineTo(lx + legW, ly + legH);
            c.lineTo(lx, ly + legH);
            c.closePath();
            c.fill();
            c.restore();
        }

        // Right leg
        if (hp[BodyPart.rightLeg] > 0)
        {
            c.save();
            c.fillStyle = hpColor(hp[BodyPart.rightLeg]);
            c.beginPath();
            float lx = cx + 2;
            float ly = chestBot;
            c.moveTo(lx, ly);
            c.lineTo(lx + legW, ly);
            c.lineTo(lx + legW, ly + legH);
            c.lineTo(lx, ly + legH);
            c.closePath();
            c.fill();
            c.restore();
        }
    }

    /// Draw HP bars below the avatar at given position
    void drawHPBars(Canvas* c, float cx, float cy)
    {
        enum barW = 30.0f;
        enum barH = 6.0f;
        enum spacing = 10.0f;
        enum totalW = 3 * barW + 2 * spacing;

        static immutable string[6] labels = [
            "LL", "RL", "LA", "RA", "CH", "HD"
        ];

        // Layout: 3 columns, 2 rows
        // Row 0: leftArm(2), chest(4), rightArm(3)
        // Row 1: leftLeg(0), head(5), rightLeg(1)
        static immutable int[6] colOf = [0, 2, 0, 2, 1, 1];
        static immutable int[6] rowOf = [1, 1, 0, 0, 0, 1];

        float startX = cx - totalW / 2;

        foreach (i; 0 .. NUM_BODY_PARTS)
        {
            float bx = startX + colOf[i] * (barW + spacing);
            float by = cy + rowOf[i] * (barH + 4);

            // Background (dark)
            c.save();
            c.fillStyle = rgba(60, 60, 60, 255);
            c.beginPath();
            c.moveTo(bx, by);
            c.lineTo(bx + barW, by);
            c.lineTo(bx + barW, by + barH);
            c.lineTo(bx, by + barH);
            c.closePath();
            c.fill();
            c.restore();

            // Foreground (HP fill)
            if (hp[i] > 0)
            {
                float fillW = barW * (cast(float) hp[i] / MAX_HP);
                c.save();
                c.fillStyle = hpColor(hp[i]);
                c.beginPath();
                c.moveTo(bx, by);
                c.lineTo(bx + fillW, by);
                c.lineTo(bx + fillW, by + barH);
                c.lineTo(bx, by + barH);
                c.closePath();
                c.fill();
                c.restore();
            }
        }
    }
}

/// Returns a color based on current HP: green (5) -> yellow (3) -> red (1)
private Color hpColor(int currentHP)
{
    float t = cast(float) currentHP / MAX_HP; // 1.0 = full, 0.0 = dead
    // Green at full, yellow at mid, red at low
    int r = cast(int)(255 * (1.0f - t));
    int g = cast(int)(255 * t);
    return rgba(r, g, 40, 255);
}
```

- [ ] **Step 2: Build to verify compilation**

Run: `dub build`
Expected: Compiles without errors.

- [ ] **Step 3: Commit**

```bash
git add source/brutor/avatar.d
git commit -m "feat: avatar body parts with canvas rendering and HP bars"
```

---

### Task 4: Combat Resolution (`brutor/combat.d`)

**Files:**
- Create: `source/brutor/combat.d`

- [ ] **Step 1: Create `source/brutor/combat.d` with damage resolution logic**

```d
module brutor.combat;

import brutor.dice;
import brutor.avatar;
import turtle;

/// A single damage action to apply to an avatar
struct DamageAction
{
    enum Type
    {
        flatDamage,  // subtract amount from HP
        setTo1,      // set HP to 1 (four of a kind)
        destroy,     // set HP to 0 (yahtzee)
    }

    Type type;
    BodyPart target;
    int amount; // only used for flatDamage
}

/// Resolve dice combos into damage actions.
/// isCritical = true if player confirmed on first roll (no re-rolls used).
DamageAction[] resolveDamage(Combo[] combos, bool isCritical)
{
    DamageAction[] actions;

    foreach (combo; combos)
    {
        final switch (combo.type)
        {
            case ComboType.single:
                // No damage
                break;

            case ComboType.pair:
                int dmg = isCritical ? 4 : 2;
                actions ~= DamageAction(DamageAction.Type.flatDamage, combo.target, dmg);
                break;

            case ComboType.threeOfAKind:
                int dmg = isCritical ? 6 : 3;
                actions ~= DamageAction(DamageAction.Type.flatDamage, combo.target, dmg);
                break;

            case ComboType.fourOfAKind:
                actions ~= DamageAction(DamageAction.Type.setTo1, combo.target, 0);
                if (isCritical)
                {
                    // Also set a random OTHER body part to 1
                    BodyPart other = randomOtherBodyPart(combo.target);
                    actions ~= DamageAction(DamageAction.Type.setTo1, other, 0);
                }
                break;

            case ComboType.yahtzee:
                actions ~= DamageAction(DamageAction.Type.destroy, combo.target, 0);
                if (isCritical)
                {
                    // Also destroy a random OTHER body part
                    BodyPart other = randomOtherBodyPart(combo.target);
                    actions ~= DamageAction(DamageAction.Type.destroy, other, 0);
                }
                break;
        }
    }

    return actions;
}

/// Apply a list of damage actions to an avatar
void applyActions(ref Avatar avatar, DamageAction[] actions)
{
    foreach (action; actions)
    {
        final switch (action.type)
        {
            case DamageAction.Type.flatDamage:
                avatar.applyDamage(action.target, action.amount);
                break;
            case DamageAction.Type.setTo1:
                avatar.setHP(action.target, 1);
                break;
            case DamageAction.Type.destroy:
                avatar.destroy(action.target);
                break;
        }
    }
}

/// Pick a random body part that is NOT the given one
private BodyPart randomOtherBodyPart(BodyPart exclude)
{
    BodyPart result;
    do
    {
        result = cast(BodyPart) randInt(0, NUM_BODY_PARTS);
    }
    while (result == exclude);
    return result;
}
```

- [ ] **Step 2: Build to verify compilation**

Run: `dub build`
Expected: Compiles without errors.

- [ ] **Step 3: Commit**

```bash
git add source/brutor/combat.d
git commit -m "feat: combat resolution with critical hit support"
```

---

### Task 5: Game State Machine (`brutor/game.d`)

**Files:**
- Create: `source/brutor/game.d`

- [ ] **Step 1: Create `source/brutor/game.d` with game state, turn logic, and rendering**

```d
module brutor.game;

import turtle;
import textmode;
import brutor.dice;
import brutor.avatar;
import brutor.combat;
import std.conv : to;
import std.format : format;

enum Phase
{
    rolling,
    selecting,
    resolving,
    gameOver,
}

struct Player
{
    DiceSet dice;
    Avatar avatar;

    void reset()
    {
        dice.reset();
        avatar.reset();
    }
}

struct GameState
{
    Player[2] players;
    int activePlayer = 0;     // 0 or 1
    int rollsUsed = 0;        // how many rolls used this turn (0-3)
    Phase phase = Phase.rolling;
    string statusText = "Player 1's turn";

    // Layout constants
    enum DICE_SIZE = 50.0f;
    enum DICE_GAP = 15.0f;
    enum DICE_Y = 420.0f;
    enum BUTTON_W = 100.0f;
    enum BUTTON_H = 30.0f;

    void reset()
    {
        players[0].reset();
        players[1].reset();
        activePlayer = 0;
        rollsUsed = 0;
        phase = Phase.rolling;
        statusText = "Player 1's turn";
    }

    /// Get the opponent of the active player
    int opponent()
    {
        return 1 - activePlayer;
    }

    /// Start a new turn for the active player
    void startTurn()
    {
        players[activePlayer].dice.reset();
        rollsUsed = 0;
        phase = Phase.rolling;
        statusText = format("Player %d's turn", activePlayer + 1);
    }

    /// Perform a roll
    void doRoll()
    {
        players[activePlayer].dice.roll();
        rollsUsed++;
        if (rollsUsed >= MAX_ROLLS)
            phase = Phase.resolving;
        else
            phase = Phase.selecting;
    }

    /// Confirm the current dice and resolve damage
    void doConfirm()
    {
        phase = Phase.resolving;
    }

    /// Resolve the current dice against the opponent
    void doResolve()
    {
        auto combos = players[activePlayer].dice.analyze();
        bool isCritical = (rollsUsed == 1);
        auto actions = resolveDamage(combos, isCritical);
        applyActions(players[opponent].avatar, actions);

        // Build status text describing what happened
        if (combos.length == 0)
            statusText = "No combinations! No damage dealt.";
        else
        {
            statusText = isCritical ? "CRITICAL HIT! " : "";
            foreach (combo; combos)
            {
                statusText ~= comboName(combo.type) ~ " on " ~ bodyPartName(combo.target) ~ "! ";
            }
        }

        // Check for game over
        if (!players[opponent].avatar.isAlive())
        {
            phase = Phase.gameOver;
            statusText = format("Player %d wins!", activePlayer + 1);
        }
        else
        {
            // Switch turns
            activePlayer = opponent;
            startTurn();
            // Auto-roll at start of turn
            doRoll();
        }
    }

    /// Handle mouse click at pixel coordinates (x, y)
    void handleClick(float mx, float my, float windowW)
    {
        final switch (phase)
        {
            case Phase.rolling:
                // Auto-roll happens, shouldn't stay here
                break;

            case Phase.selecting:
                // Check dice clicks
                float totalDiceW = NUM_DICE * DICE_SIZE + (NUM_DICE - 1) * DICE_GAP;
                float diceStartX = (windowW - totalDiceW) / 2;

                foreach (i; 0 .. NUM_DICE)
                {
                    float dx = diceStartX + i * (DICE_SIZE + DICE_GAP);
                    float dy = DICE_Y;
                    if (mx >= dx && mx <= dx + DICE_SIZE &&
                        my >= dy && my <= dy + DICE_SIZE)
                    {
                        players[activePlayer].dice.toggleKeep(i);
                        return;
                    }
                }

                // Check ROLL button
                float rollBtnX = windowW / 2 - 140;
                float rollBtnY = DICE_Y + DICE_SIZE + 30;
                if (rollsUsed < MAX_ROLLS &&
                    mx >= rollBtnX && mx <= rollBtnX + BUTTON_W &&
                    my >= rollBtnY && my <= rollBtnY + BUTTON_H)
                {
                    doRoll();
                    return;
                }

                // Check CONFIRM button
                float confirmBtnX = windowW / 2 + 40;
                float confirmBtnY = DICE_Y + DICE_SIZE + 30;
                if (mx >= confirmBtnX && mx <= confirmBtnX + BUTTON_W &&
                    my >= confirmBtnY && my <= confirmBtnY + BUTTON_H)
                {
                    doConfirm();
                    doResolve();
                    return;
                }
                break;

            case Phase.resolving:
                // Resolve happens instantly, shouldn't stay here
                break;

            case Phase.gameOver:
                reset();
                startTurn();
                doRoll();
                break;
        }
    }

    /// Draw everything using canvas and textmode
    void draw(Canvas* c, TM_Console* con, float windowW, float windowH)
    {
        // Draw avatars
        float avatar1X = windowW * 0.2f;
        float avatar2X = windowW * 0.8f;
        float avatarY = 180.0f;

        players[0].avatar.draw(c, avatar1X, avatarY);
        players[1].avatar.draw(c, avatar2X, avatarY);

        // Draw HP bars below avatars
        players[0].avatar.drawHPBars(c, avatar1X, avatarY + 100);
        players[1].avatar.drawHPBars(c, avatar2X, avatarY + 100);

        // Highlight active player's side
        float highlightX = (activePlayer == 0) ? avatar1X : avatar2X;
        c.save();
        c.fillStyle = rgba(255, 255, 100, 30);
        c.beginPath();
        c.arc(highlightX, avatarY, 100, 0, 6.2832f);
        c.fill();
        c.restore();

        // Draw dice
        drawDice(c, windowW);

        // Draw text with textmode
        drawText(con);
    }

    /// Draw the 5 dice using canvas
    void drawDice(Canvas* c, float windowW)
    {
        float totalDiceW = NUM_DICE * DICE_SIZE + (NUM_DICE - 1) * DICE_GAP;
        float startX = (windowW - totalDiceW) / 2;

        foreach (i; 0 .. NUM_DICE)
        {
            float dx = startX + i * (DICE_SIZE + DICE_GAP);
            float dy = DICE_Y;
            int value = players[activePlayer].dice.values[i];
            bool isKept = players[activePlayer].dice.kept[i];

            // Die background
            c.save();
            if (isKept)
                c.fillStyle = rgba(255, 220, 100, 255); // yellow for kept
            else
                c.fillStyle = rgba(240, 240, 240, 255); // white for unkept
            c.beginPath();
            c.moveTo(dx, dy);
            c.lineTo(dx + DICE_SIZE, dy);
            c.lineTo(dx + DICE_SIZE, dy + DICE_SIZE);
            c.lineTo(dx, dy + DICE_SIZE);
            c.closePath();
            c.fill();
            c.restore();

            // Pips
            drawPips(c, dx, dy, DICE_SIZE, value);
        }
    }

    /// Draw the pips on a single die
    static void drawPips(Canvas* c, float x, float y, float size, int value)
    {
        float pipR = size * 0.08f;
        float cx = x + size / 2;
        float cy = y + size / 2;
        float off = size * 0.28f;

        c.save();
        c.fillStyle = rgba(20, 20, 20, 255);

        // Standard pip positions
        void pip(float px, float py)
        {
            c.beginPath();
            c.arc(px, py, pipR, 0, 6.2832f);
            c.fill();
        }

        // Center pip (1, 3, 5)
        if (value == 1 || value == 3 || value == 5)
            pip(cx, cy);

        // Top-right, bottom-left (2, 3, 4, 5, 6)
        if (value >= 2)
        {
            pip(cx + off, cy - off);
            pip(cx - off, cy + off);
        }

        // Top-left, bottom-right (4, 5, 6)
        if (value >= 4)
        {
            pip(cx - off, cy - off);
            pip(cx + off, cy + off);
        }

        // Middle-left, middle-right (6)
        if (value == 6)
        {
            pip(cx - off, cy);
            pip(cx + off, cy);
        }

        c.restore();
    }

    /// Draw text labels using textmode console
    void drawText(TM_Console* con)
    {
        with (con)
        {
            // Player labels
            locate(5, 1);
            fg((activePlayer == 0) ? TM_colorYellow : TM_colorWhite);
            print("PLAYER 1");

            locate(45, 1);
            fg((activePlayer == 1) ? TM_colorYellow : TM_colorWhite);
            print("PLAYER 2");

            // Rolls remaining
            locate(22, 26);
            fg(TM_colorWhite);
            int remaining = MAX_ROLLS - rollsUsed;
            print("Rolls: " ~ remaining.to!string ~ "/" ~ MAX_ROLLS.to!string);

            // Status text
            locate(2, 28);
            fg(TM_colorCyan);
            // Truncate status if too long for console
            string display = statusText;
            if (display.length > 56)
                display = display[0 .. 56];
            print(display);

            if (phase == Phase.selecting)
            {
                // ROLL button text
                if (rollsUsed < MAX_ROLLS)
                {
                    locate(16, 27);
                    fg(TM_colorGreen);
                    print("[ROLL]");
                }

                // CONFIRM button text
                locate(34, 27);
                fg(TM_colorRed);
                print("[CONFIRM]");
            }

            if (phase == Phase.gameOver)
            {
                locate(20, 14);
                fg(TM_colorYellow);
                print("GAME OVER");
                locate(14, 16);
                fg(TM_colorWhite);
                print("Click to play again");
            }
        }
    }
}

/// Human-readable combo names
string comboName(ComboType type)
{
    final switch (type)
    {
        case ComboType.single: return "Nothing";
        case ComboType.pair: return "Pair";
        case ComboType.threeOfAKind: return "Three of a Kind";
        case ComboType.fourOfAKind: return "Four of a Kind";
        case ComboType.yahtzee: return "YAHTZEE";
    }
}

/// Human-readable body part names
string bodyPartName(BodyPart part)
{
    final switch (part)
    {
        case BodyPart.leftLeg: return "Left Leg";
        case BodyPart.rightLeg: return "Right Leg";
        case BodyPart.leftArm: return "Left Arm";
        case BodyPart.rightArm: return "Right Arm";
        case BodyPart.chest: return "Chest";
        case BodyPart.head: return "Head";
    }
}
```

- [ ] **Step 2: Build to verify compilation**

Run: `dub build`
Expected: Compiles without errors.

- [ ] **Step 3: Commit**

```bash
git add source/brutor/game.d
git commit -m "feat: game state machine with turn logic and rendering"
```

---

### Task 6: Wire Everything into main.d

**Files:**
- Modify: `source/main.d`

- [ ] **Step 1: Update `source/main.d` to use GameState**

Replace the entire content of `source/main.d` with:

```d
import turtle;
import brutor;

int main(string[] args)
{
    runGame(new BrutorGame);
    return 0;
}

class BrutorGame : TurtleGame
{
    GameState state;

    override void load()
    {
        setBackgroundColor(color("#1a1a2e"));
        setTitle("Brutor");
        console.size(60, 30);

        state.reset();
        state.startTurn();
        state.doRoll();
    }

    override void update(double dt)
    {
        if (keyboard.isDown("escape")) exitGame;
    }

    override void mousePressed(float x, float y, MouseButton button, int repeat)
    {
        if (button == MouseButton.left)
        {
            state.handleClick(x, y, windowWidth);
        }
    }

    override void draw()
    {
        console.cls();
        state.draw(canvas, console, windowWidth, windowHeight);
    }
}
```

- [ ] **Step 2: Build and run the full game**

Run: `dub run`
Expected: Window shows two geometric avatars, 5 dice in the center, player labels. Clicking dice toggles their keep state (yellow highlight). Clicking ROLL re-rolls unkept dice. Clicking CONFIRM resolves damage against opponent.

- [ ] **Step 3: Playtest the core loop**

Test these scenarios manually:
1. Roll dice, keep some, re-roll - verify dice toggling and re-rolling works
2. Get a pair - verify 2 damage to correct body part
3. Use all 3 rolls - verify auto-resolve after 3rd roll
4. Confirm on first roll - verify "CRITICAL" appears in status text
5. Destroy opponent's head - verify game over screen appears
6. Click to restart after game over

- [ ] **Step 4: Commit**

```bash
git add source/main.d
git commit -m "feat: wire game state into main game loop, playable game"
```

---

### Task 7: Polish & Bug Fixes

**Files:**
- Modify: `source/brutor/game.d`
- Modify: `source/main.d`

This task covers fixes discovered during playtesting in Task 6. Common issues to watch for:

- [ ] **Step 1: Fix console access in draw**

The `console()` call in `main.d` may need adjustment depending on how turtle exposes it. If `&console()[0]` doesn't compile, change the draw call to pass the console differently. The TurtleGame base class has `console()` returning a `TM_Console*`. Check the space invader example pattern - it uses `with (console)` directly. If needed, change the `GameState.draw` signature to accept a `TM_Console*` and call it as:

```d
override void draw()
{
    console.cls();
    state.draw(canvas, console, windowWidth, windowHeight);
}
```

- [ ] **Step 2: Verify ROLL/CONFIRM button hit areas match text positions**

The text positions (in character coordinates via `locate()`) must align with the pixel-based hit detection in `handleClick()`. The textmode console maps character positions to pixel positions based on the console size and window size. If buttons don't respond to clicks, adjust either the `locate()` positions or the pixel hit-test coordinates in `handleClick()` to match.

To calculate: `pixelX = charX * (windowWidth / consoleColumns)` and `pixelY = charY * (windowHeight / consoleRows)`.

- [ ] **Step 3: Test and commit fixes**

Run: `dub run`
Verify: All interactions work correctly, damage resolves properly, game over triggers on head destruction.

```bash
git add -u
git commit -m "fix: polish rendering and input alignment"
```
