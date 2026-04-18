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
    upgrade,    // tech-tree / spend Tech points screen
}

enum MAX_MP = 5;

/// How many rerolls an INSTANT resolution can store for next turn.
enum MAX_BANKED_REROLLS = 2;

/// A clickable button. Holds its bounds, label, and visibility/enabled
/// flags, and knows how to hit-test, render its background (canvas), and
/// place its label (textmode).
struct Button
{
    float x, y, w, h;
    string label;
    bool enabled = true;   // false greys the label (still clickable)
    bool visible = true;   // false skips draw and hit-test
    float labelDY = 0;     // shift the label's vertical anchor from y

    bool hitTest(float px, float py) const
    {
        if (!visible) return false;
        return px >= x && px <= x + w && py >= y && py <= y + h;
    }

    void draw(Canvas* c, float mouseVX, float mouseVY) const
    {
        if (!visible) return;
        GameState.drawButtonRect(c, x, y, w, h, hitTest(mouseVX, mouseVY));
    }

    void drawLabel(TM_Console* con) const
    {
        if (!visible || label.length == 0) return;
        int col, row;
        GameState.centerTextInRect(x, y + labelDY, w, h,
                                   cast(int) label.length, col, row);
        con.locate(col, row);
        con.fg(enabled ? TM_colorWhite : TM_colorGrey);
        con.print(label);
    }
}

struct Player
{
    DiceSet dice;
    Avatar avatar;
    int mp = 0;
    // Rerolls banked from a previous turn's INSTANT resolution. Consumed at
    // the start of this player's next turn.
    int bankedRerolls = 0;
    // Helmet tier. Incoming head damage is reduced by helmetLevel (min 0).
    //   0 = no helmet, 1 = basic (match-start default), 2 = reinforced.
    int helmetLevel = 1;
    // Shield wielded by the left arm. Every player starts each match
    // with one. Dropped permanently when the left arm is destroyed —
    // healing the arm back does NOT restore the shield.
    bool hasShield = true;
    // Parry wall — set by rolling a straight. Blocks ALL incoming damage
    // on the opponent's very next turn, then clears.
    bool parryActive = false;

    void reset()
    {
        dice.reset();
        avatar.reset();
        mp = 0;
        bankedRerolls = 0;
        helmetLevel = 1;
        hasShield = true;
        parryActive = false;
    }
}

struct GameState
{
    Player[2] players;
    int activePlayer = 0;     // 0 or 1
    int rollsUsed = 0;        // how many rolls used this turn (0-3)
    // Extra rolls this turn, consumed from the active player's banked
    // rerolls at startTurn(). Adds on top of MAX_ROLLS for the current turn.
    int extraRollsThisTurn = 0;
    Phase phase = Phase.rolling;
    string statusText = "";

    // Damage animation state. When phase == resolving, animTimer counts
    // down; `hitAnim` marks body parts on the opponent (= damage receiver)
    // that should flash during the animation.
    float animTimer = 0;
    bool[NUM_BODY_PARTS] hitAnim;
    enum float ANIM_DURATION = 0.8f;    // seconds
    enum float ANIM_BLINK_PERIOD = 0.1f; // seconds per on/off frame

    // ----- Coordinate systems -----
    //
    // Three spaces are in play; helpers below convert between them.
    //
    //   1. Window pixels: actual on-screen pixels (windowW x windowH).
    //   2. Virtual pixels: fixed 16:9 design space (VIRTUAL_W x VIRTUAL_H).
    //      Letterboxed inside the window using a uniform scale.
    //   3. Console cells: text-mode grid (CONSOLE_COLS x CONSOLE_ROWS).
    //
    // text-mode picks the largest cell size in pixels that is a multiple of 8
    // and fits CONSOLE_COLS x CONSOLE_ROWS in the window, then centers. We
    // mirror that exact choice for the virtual viewport so:
    //   * the canvas viewport and the console occupy the same on-screen rect
    //   * 1 console cell == CELL_VIRTUAL virtual pixels (here 12),
    //     which gives 80*12 = 960 = VIRTUAL_W and 45*12 = 540 = VIRTUAL_H.
    //
    enum CONSOLE_COLS = 80;
    enum CONSOLE_ROWS = 45;
    enum CELL_VIRTUAL = 12;
    enum VIRTUAL_W = CONSOLE_COLS * CELL_VIRTUAL; // 960
    enum VIRTUAL_H = CONSOLE_ROWS * CELL_VIRTUAL; // 540

    // Layout constants (virtual pixels)
    enum DICE_SIZE = 50.0f;
    enum DICE_GAP = 15.0f;
    enum DICE_Y = 298.0f;
    // 264 = 22 console cells. REROLL and INSTANT share this width so
    // they line up vertically.
    enum REROLL_W = 264.0f;
    enum REROLL_H = 40.0f;
    enum REROLL_Y = 390.0f;
    // The drawn background rectangle sits half a row lower than REROLL_Y
    // so the label visually rides high in the button. Hit-testing follows
    // the drawn rect; label layout and INSTANT_Y still anchor to REROLL_Y.
    enum REROLL_BG_Y = REROLL_Y + CELL_VIRTUAL * 0.5f;

    // "INSTANT" button: shown whenever the active player has a damaging
    // combo AND still has rerolls left. Resolves the turn now and banks
    // the unused rerolls (capped at MAX_BANKED_REROLLS) for their next
    // turn. Sits directly below the REROLL button.
    enum INSTANT_W = REROLL_W;
    enum INSTANT_H = 40.0f;
    enum INSTANT_Y = REROLL_Y + REROLL_H + 10.0f; // 440

    // "MAGIC" button — horizontally centered near the top of the screen.
    enum MAGIC_W = 180.0f;
    enum MAGIC_H = 36.0f;
    enum MAGIC_X = (VIRTUAL_W - MAGIC_W) / 2;  // 390
    enum MAGIC_Y = 42.0f;                       // row ~4

    // Upgrade screen layout — REPAIR, REINFORCE HELMET, and BACK.
    enum REPAIR_COST = 1;
    enum REPAIR_W = 400.0f;
    enum REPAIR_H = 60.0f;
    enum REPAIR_X = (VIRTUAL_W - REPAIR_W) / 2;  // 280
    enum REPAIR_Y = 200.0f;
    enum REINFORCE_COST = 1;
    enum REINFORCE_W = 400.0f;
    enum REINFORCE_H = 60.0f;
    enum REINFORCE_X = (VIRTUAL_W - REINFORCE_W) / 2;  // 280
    enum REINFORCE_Y = 310.0f;
    enum BACK_W   = 200.0f;
    enum BACK_H   = 40.0f;
    enum BACK_X   = (VIRTUAL_W - BACK_W) / 2;     // 380
    enum BACK_Y   = 420.0f;

    // Button colors (Couture palette, sampled from text-mode):
    //   TM_colorRed  = 0x832539 (not hovered)
    //   TM_colorLRed = 0xd43e49 (hovered)
    static Color btnColorIdle()   { return rgba(0x83, 0x25, 0x39, 255); }
    static Color btnColorHover()  { return rgba(0xd4, 0x3e, 0x49, 255); }

    // Mouse position in virtual coords
    float mouseVX = 0;
    float mouseVY = 0;

    void reset()
    {
        players[0].reset();
        players[1].reset();
        activePlayer = 0;
        rollsUsed = 0;
        extraRollsThisTurn = 0;
        phase = Phase.rolling;
        statusText = "";
        animTimer = 0;
        hitAnim[] = false;
    }

    /// Get the opponent of the active player
    int opponent()
    {
        return 1 - activePlayer;
    }

    /// Start a new turn for the active player. Consumes any rerolls the
    /// player banked on their previous turn into this turn's roll quota.
    void startTurn()
    {
        players[activePlayer].dice.reset();
        rollsUsed = 0;
        extraRollsThisTurn = players[activePlayer].bankedRerolls;
        players[activePlayer].bankedRerolls = 0;
        phase = Phase.rolling;
        statusText = "";
    }

    /// Total rolls available this turn (base quota + banked rerolls).
    /// Missing the right arm drops the base quota by 1 — one less reroll
    /// per turn (two rolls instead of three).
    int totalRollsThisTurn() const
    {
        int base = MAX_ROLLS;
        if (players[activePlayer].avatar.hp[BodyPart.rightArm] == 0)
            base--;
        return base + extraRollsThisTurn;
    }

    /// The active player can only toggle KEEP on dice while their head is
    /// still intact.
    bool canKeep() const
    {
        return players[activePlayer].avatar.hp[BodyPart.head] > 0;
    }

    /// Which dice are frozen (can't reroll) for the active player based on
    /// missing legs. One missing leg freezes die #5 (index 4); both legs
    /// missing also freeze die #4 (index 3).
    bool[NUM_DICE] legDebuffMask() const
    {
        bool[NUM_DICE] frozen;
        int legsMissing = 0;
        if (players[activePlayer].avatar.hp[BodyPart.leftLeg]  == 0) legsMissing++;
        if (players[activePlayer].avatar.hp[BodyPart.rightLeg] == 0) legsMissing++;
        if (legsMissing >= 1) frozen[4] = true;
        if (legsMissing >= 2) frozen[3] = true;
        return frozen;
    }

    /// Perform a roll. The initial roll rolls every die. On rerolls,
    /// missing legs freeze dice at the high indices (see legDebuffMask).
    void doRoll()
    {
        bool[NUM_DICE] frozen;
        if (rollsUsed >= 1)
            frozen = legDebuffMask();
        players[activePlayer].dice.roll(frozen);
        rollsUsed++;
        // Always go to selecting so the player can see their dice
        // If no rolls remain, they can only click CONFIRM
        phase = Phase.selecting;
    }

    /// Count how many of the two body parts targeted by a full house
    /// (the 3-of-a-kind and the pair) are still alive on the active
    /// player. Returns a value in 0..2.
    private int fullHouseAliveTargets(Combo[] combos)
    {
        int count = 0;
        foreach (combo; combos)
        {
            if (players[activePlayer].avatar.hp[combo.target] > 0)
                count++;
        }
        return count;
    }

    /// Add `amount` MP to the active player, clamped to MAX_MP.
    private void grantMP(int amount)
    {
        int mp = players[activePlayer].mp + amount;
        if (mp > MAX_MP) mp = MAX_MP;
        players[activePlayer].mp = mp;
    }

    /// Mutate incoming damage actions in place according to the opponent's
    /// defensive gear. The helmet reduces head damage by helmetLevel (min 0).
    private void applyDefenderModifiers(ref DamageAction[] actions)
    {
        int reduction = players[opponent].helmetLevel;
        if (reduction <= 0)
            return;
        foreach (ref a; actions)
        {
            if (a.target == BodyPart.head && a.type == DamageAction.Type.flatDamage)
                a.amount = a.amount > reduction ? a.amount - reduction : 0;
        }
    }

    /// Resolve the current dice against the opponent, apply damage, and
    /// start the damage animation. Turn only switches once the animation
    /// finishes (see update()). Straights raise a parry wall on the active
    /// player; full houses grant MP — both skip the damage animation.
    void doResolve()
    {
        auto combos = players[activePlayer].dice.analyze();

        // The defender's parry wall (if any) was set up specifically to
        // protect against this turn. Consume it now, regardless of what
        // the active player rolled.
        bool defenderParried = players[opponent].parryActive;
        players[opponent].parryActive = false;

        if (isStraight(combos))
        {
            // Raise a wall in front of the active player — it will absorb
            // every damage action the opponent rolls on their next turn.
            players[activePlayer].parryActive = true;
            hitAnim[] = false;
            phase = Phase.resolving;
            animTimer = ANIM_DURATION * 0.5f; // brief pause before handing over
            return;
        }

        if (isFullHouse(combos))
        {
            grantMP(fullHouseAliveTargets(combos));
            hitAnim[] = false;
            phase = Phase.resolving;
            animTimer = ANIM_DURATION * 0.5f;
            return;
        }

        auto actions = resolveDamage(combos);
        if (defenderParried)
        {
            // The wall absorbs everything before helmet/shield even matter.
            foreach (ref a; actions)
                a.amount = 0;
        }
        else
        {
            applyDefenderModifiers(actions);
        }

        // Only flash body parts that will actually take damage.
        hitAnim[] = false;
        foreach (action; actions)
            if (action.amount > 0)
                hitAnim[action.target] = true;

        applyActions(players[opponent].avatar, actions);

        // The shield is dropped permanently once the left arm is gone.
        if (players[opponent].avatar.hp[BodyPart.leftArm] == 0)
            players[opponent].hasShield = false;

        phase = Phase.resolving;
        animTimer = ANIM_DURATION;
    }

    /// Number of rerolls the active player would bank by clicking INSTANT
    /// right now. Capped at MAX_BANKED_REROLLS.
    int instantBankAmount() const
    {
        int unused = totalRollsThisTurn() - rollsUsed;
        if (unused < 0) unused = 0;
        return unused > MAX_BANKED_REROLLS ? MAX_BANKED_REROLLS : unused;
    }

    /// Resolve via INSTANT: bank the unused rerolls onto the active player
    /// and resolve damage as usual.
    void doInstant()
    {
        players[activePlayer].bankedRerolls = instantBankAmount();
        doResolve();
    }

    /// Per-frame update: advances the damage animation and, once done,
    /// either ends the game or hands the turn over to the other player.
    void update(double dt)
    {
        if (phase != Phase.resolving)
            return;

        animTimer -= cast(float) dt;
        if (animTimer > 0)
            return;

        animTimer = 0;
        hitAnim[] = false;

        if (!players[opponent].avatar.isAlive())
        {
            phase = Phase.gameOver;
            statusText = format("Player %d wins!", activePlayer + 1);
        }
        else
        {
            activePlayer = opponent;
            startTurn();
            doRoll();
        }
    }

    /// Is the flash "on" this frame? (Toggles every ANIM_BLINK_PERIOD.)
    bool animFlashOn() const
    {
        if (phase != Phase.resolving)
            return false;
        int tick = cast(int)((ANIM_DURATION - animTimer) / ANIM_BLINK_PERIOD);
        return (tick & 1) == 0;
    }

    /// Preview lines describing the damage the active player's current
    /// dice would deal if they ended the turn now. Delegates to
    /// combat.describeDamage so the preview and the actual resolve share
    /// a single source of truth for damage values.
    string[] previewDamageLines()
    {
        auto combos = players[activePlayer].dice.analyze();
        if (isFullHouse(combos))
        {
            int n = fullHouseAliveTargets(combos);
            return [format("Full house \u2192 +%d MP.", n)];
        }
        auto lines = describeDamage(combos).previewLines;

        // If the opponent has a parry wall up, every damage line is moot —
        // call it out and skip the helmet note.
        if (players[opponent].parryActive)
        {
            bool dealsDamage = false;
            foreach (a; describeDamage(combos).actions)
                if (a.amount > 0) { dealsDamage = true; break; }
            if (dealsDamage)
                lines ~= "Parry wall \u2192 all damage blocked.";
            return lines;
        }

        int reduction = players[opponent].helmetLevel;
        if (reduction > 0)
        {
            foreach (combo; combos)
            {
                if (combo.target == BodyPart.head)
                {
                    lines ~= format("Helmet \u2192 -%d head damage.", reduction);
                    break;
                }
            }
        }
        return lines;
    }

    /// True when the player may click INSTANT: a scoring combo is on the
    /// table (damage, straight, or full house) and they have at least one
    /// reroll left to bank. Hands with no combo at all can't INSTANT —
    /// they have nothing worth locking in.
    bool canInstant()
    {
        if (phase != Phase.selecting)
            return false;
        if (rollsUsed >= totalRollsThisTurn())
            return false;
        auto combos = players[activePlayer].dice.analyze();
        if (combos.length == 0)
            return false;
        return true;
    }

    /// Handle SPACE/ENTER key to roll or end turn
    void handleRollKey()
    {
        if (phase == Phase.selecting)
        {
            if (rollsUsed < totalRollsThisTurn())
                doRoll();
            else
                doResolve();
        }
        else if (phase == Phase.gameOver)
        {
            reset();
            startTurn();
            doRoll();
        }
    }

    /// Cell size in window pixels chosen by text-mode for the current window:
    /// the largest multiple of 8 that fits CONSOLE_COLS x CONSOLE_ROWS.
    static int cellSizePx(float windowW, float windowH)
    {
        int byW = cast(int)(windowW / CONSOLE_COLS);
        int byH = cast(int)(windowH / CONSOLE_ROWS);
        int cell = (byW < byH ? byW : byH) & ~7; // floor to multiple of 8
        return cell < 8 ? 8 : cell;
    }

    /// Scale factor: multiply a virtual length by this to get window pixels.
    static float virtualScale(float windowW, float windowH)
    {
        return cellSizePx(windowW, windowH) / cast(float) CELL_VIRTUAL;
    }

    /// Top-left of the virtual viewport in window pixels (letterbox offset).
    /// Matches the rect text-mode renders into.
    static void viewportOffset(float windowW, float windowH,
                               out float offsetX, out float offsetY)
    {
        float s = virtualScale(windowW, windowH);
        offsetX = (windowW - VIRTUAL_W * s) * 0.5f;
        offsetY = (windowH - VIRTUAL_H * s) * 0.5f;
    }

    /// Window pixels -> virtual coords.
    static void windowToVirtual(float wx, float wy, float windowW, float windowH,
                                out float vx, out float vy)
    {
        float s = virtualScale(windowW, windowH);
        float offX, offY;
        viewportOffset(windowW, windowH, offX, offY);
        vx = (wx - offX) / s;
        vy = (wy - offY) / s;
    }

    /// Virtual coords -> the console cell (col, row) that contains them.
    /// Useful for placing text labels relative to canvas-drawn UI.
    static void virtualToConsole(float vx, float vy, out int col, out int row)
    {
        col = cast(int)(vx / CELL_VIRTUAL);
        row = cast(int)(vy / CELL_VIRTUAL);
    }

    /// Console cell (col, row) -> top-left virtual coord of that cell.
    static void consoleToVirtual(int col, int row, out float vx, out float vy)
    {
        vx = col * cast(float) CELL_VIRTUAL;
        vy = row * cast(float) CELL_VIRTUAL;
    }

    /// Center an N-cell-wide, 1-cell-tall text label inside a virtual rect.
    /// Returns the (col, row) to pass to console.locate().
    static void centerTextInRect(float rectVX, float rectVY, float rectVW, float rectVH,
                                 int textCells, out int col, out int row)
    {
        float vx = rectVX + (rectVW - textCells * cast(float) CELL_VIRTUAL) * 0.5f;
        float vy = rectVY + (rectVH - cast(float) CELL_VIRTUAL) * 0.5f;
        // Round to nearest cell rather than truncating, for better visual centering.
        col = cast(int)(vx / CELL_VIRTUAL + 0.5f);
        row = cast(int)(vy / CELL_VIRTUAL + 0.5f);
    }

    /// Update mouse position for hover detection
    void updateMousePos(float mx, float my, float windowW, float windowH)
    {
        windowToVirtual(mx, my, windowW, windowH, mouseVX, mouseVY);
    }

    /// Check if a point is inside a rectangle
    static bool hitTest(float px, float py, float rx, float ry, float rw, float rh)
    {
        return px >= rx && px <= rx + rw && py >= ry && py <= ry + rh;
    }

    // ----- Buttons -----
    //
    // Each screen button is built from live state here. Layout, label,
    // visibility, and enabled-ness live in one place per button; drawing
    // and hit-testing go through the generic Button struct.

    Button rerollButton()
    {
        float btnX = (VIRTUAL_W - REROLL_W) / 2;
        string lbl = (rollsUsed < totalRollsThisTurn()) ? "REROLL" : "NEXT TURN";
        Button b = {
            x: btnX, y: REROLL_BG_Y, w: REROLL_W, h: REROLL_H,
            label: lbl, visible: phase == Phase.selecting,
            labelDY: REROLL_Y - REROLL_BG_Y,
        };
        return b;
    }

    Button instantButton()
    {
        float btnX = (VIRTUAL_W - INSTANT_W) / 2;
        int bank = instantBankAmount();
        string lbl = bank > 0
            ? format("INSTANT (+%d stored)", bank)
            : "INSTANT";
        Button b = {
            x: btnX, y: INSTANT_Y, w: INSTANT_W, h: INSTANT_H,
            label: lbl, visible: canInstant(),
        };
        return b;
    }

    Button magicButton()
    {
        bool vis = phase == Phase.selecting && players[activePlayer].mp > 0;
        Button b = {
            x: MAGIC_X, y: MAGIC_Y, w: MAGIC_W, h: MAGIC_H,
            label: "Upgrade", visible: vis,
        };
        return b;
    }

    Button repairButton()
    {
        bool canAfford = players[activePlayer].mp >= REPAIR_COST;
        Button b = {
            x: REPAIR_X, y: REPAIR_Y, w: REPAIR_W, h: REPAIR_H,
            label: format("REPAIR  +1 HP  (%d MP)", REPAIR_COST),
            enabled: canAfford,
        };
        return b;
    }

    Button reinforceButton()
    {
        bool canAct = players[activePlayer].mp >= REINFORCE_COST
                   && players[activePlayer].helmetLevel < 2;
        Button b = {
            x: REINFORCE_X, y: REINFORCE_Y, w: REINFORCE_W, h: REINFORCE_H,
            label: format("REINFORCE HELMET  (%d MP)", REINFORCE_COST),
            enabled: canAct,
        };
        return b;
    }

    Button backButton()
    {
        Button b = {
            x: BACK_X, y: BACK_Y, w: BACK_W, h: BACK_H,
            label: "BACK",
        };
        return b;
    }

    /// Handle mouse click at pixel coordinates (x, y) in window space
    void handleClick(float mx, float my, float windowW, float windowH)
    {
        float vx, vy;
        windowToVirtual(mx, my, windowW, windowH, vx, vy);

        final switch (phase)
        {
            case Phase.rolling:
                // Auto-roll happens, shouldn't stay here
                break;

            case Phase.selecting:
                // Check dice clicks — toggling KEEP requires an intact head.
                if (canKeep())
                {
                    float totalDiceW = NUM_DICE * DICE_SIZE + (NUM_DICE - 1) * DICE_GAP;
                    float diceStartX = (VIRTUAL_W - totalDiceW) / 2;

                    foreach (i; 0 .. NUM_DICE)
                    {
                        float dx = diceStartX + i * (DICE_SIZE + DICE_GAP);
                        if (hitTest(vx, vy, dx, DICE_Y, DICE_SIZE, DICE_SIZE))
                        {
                            players[activePlayer].dice.toggleKeep(i);
                            return;
                        }
                    }
                }

                if (instantButton().hitTest(vx, vy))
                {
                    doInstant();
                    return;
                }
                if (rerollButton().hitTest(vx, vy))
                {
                    if (rollsUsed < totalRollsThisTurn())
                        doRoll();
                    else
                        doResolve();
                    return;
                }
                if (magicButton().hitTest(vx, vy))
                {
                    phase = Phase.upgrade;
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

            case Phase.upgrade:
                if (repairButton().hitTest(vx, vy))
                {
                    tryRepair();
                    return;
                }
                if (reinforceButton().hitTest(vx, vy))
                {
                    tryReinforceHelmet();
                    return;
                }
                if (backButton().hitTest(vx, vy))
                {
                    phase = Phase.selecting;
                    return;
                }
                break;
        }
    }

    /// Spend one Tech point to restore 1 HP on the active player's most
    /// damaged (but still alive) body part. No-op if no TP or nothing to
    /// repair.
    void tryRepair()
    {
        if (players[activePlayer].mp < REPAIR_COST)
            return;
        // Pick the alive body part with the lowest HP.
        int target = -1;
        int lowest = MAX_HP + 1;
        foreach (i; 0 .. NUM_BODY_PARTS)
        {
            int hp = players[activePlayer].avatar.hp[i];
            if (hp <= 0 || hp >= MAX_HP)
                continue;
            if (hp < lowest)
            {
                lowest = hp;
                target = i;
            }
        }
        if (target == -1)
            return; // nothing to repair
        players[activePlayer].avatar.hp[target] = lowest + 1;
        players[activePlayer].mp -= REPAIR_COST;
    }

    /// Spend one MP to set the active player's helmet to level 2. If they
    /// currently have no helmet this regenerates one (directly at level 2).
    /// No-op when they already have a reinforced helmet — spending MP would
    /// grant no benefit.
    void tryReinforceHelmet()
    {
        if (players[activePlayer].mp < REINFORCE_COST)
            return;
        if (players[activePlayer].helmetLevel >= 2)
            return;
        players[activePlayer].helmetLevel = 2;
        players[activePlayer].mp -= REINFORCE_COST;
    }

    /// Draw everything using canvas and textmode
    void draw(Canvas* c, TM_Console* con, float windowW, float windowH)
    {
        // Use the same letterboxing as text-mode so the canvas viewport and
        // the console occupy the exact same on-screen rect.
        float scale = virtualScale(windowW, windowH);
        float offsetX, offsetY;
        viewportOffset(windowW, windowH, offsetX, offsetY);

        c.save();
        c.translate(offsetX, offsetY);
        c.scale(scale, scale);

        if (phase == Phase.upgrade)
        {
            drawUpgradeScreen(c);
            c.restore();
            drawUpgradeText(con);
            return;
        }

        // Draw avatars centered above each player's HP box.
        // P1 HP box spans cols 0..20, P2 spans cols 58..78. HP box top row is 36.
        // Centers in virtual px: P1 at 120, P2 at 816; HP box top at y=432.
        float avatar1X = 120.0f;
        float avatar2X = 816.0f;
        float avatarY = 337.0f;
        float avatarScale = 1.2f;

        // Only the opponent (= damage receiver this turn) flashes.
        bool flashOn = animFlashOn();
        bool[NUM_BODY_PARTS] noFlash;
        auto flash0 = (opponent == 0) ? hitAnim : noFlash;
        auto flash1 = (opponent == 1) ? hitAnim : noFlash;

        players[0].avatar.draw(c, avatar1X, avatarY, avatarScale,
                               flash0, flashOn,
                               players[0].helmetLevel, players[0].hasShield);
        players[1].avatar.draw(c, avatar2X, avatarY, avatarScale,
                               flash1, flashOn,
                               players[1].helmetLevel, players[1].hasShield);

        // Parry walls — drawn on the side facing the opponent so the
        // protected player is visibly behind the wall.
        if (players[0].parryActive)
            drawParryWall(c, avatar1X, avatarY, true);
        if (players[1].parryActive)
            drawParryWall(c, avatar2X, avatarY, false);

        // Draw dice
        drawDice(c);

        c.restore();

        // Draw text with textmode
        drawText(con);
    }

    /// Canvas-side rendering of the Upgrade/Tech-tree screen.
    void drawUpgradeScreen(Canvas* c)
    {
        repairButton().draw(c, mouseVX, mouseVY);
        reinforceButton().draw(c, mouseVX, mouseVY);
        backButton().draw(c, mouseVX, mouseVY);
    }

    /// Draw the 5 dice and REROLL button using canvas (in virtual coordinates)
    void drawDice(Canvas* c)
    {
        float totalDiceW = NUM_DICE * DICE_SIZE + (NUM_DICE - 1) * DICE_GAP;
        float startX = (VIRTUAL_W - totalDiceW) / 2;

        // Once the player has no rerolls left the turn is effectively over
        // (they're just about to click NEXT TURN), so freeze the dice into a
        // neutral look: no hover highlight and no kept highlight.
        bool diceInteractive = phase == Phase.selecting
                            && rollsUsed < totalRollsThisTurn()
                            && canKeep();

        // Dice frozen by missing legs render greyed, to signal they can't
        // be re-rolled. Only show the tint once at least one roll has been
        // made (the initial roll rolls everything).
        bool[NUM_DICE] frozen;
        if (rollsUsed >= 1)
            frozen = legDebuffMask();

        foreach (i; 0 .. NUM_DICE)
        {
            float dx = startX + i * (DICE_SIZE + DICE_GAP);
            float dy = DICE_Y;
            int value = players[activePlayer].dice.values[i];
            bool isKept = players[activePlayer].dice.kept[i];
            bool hovered = diceInteractive && !frozen[i] &&
                           hitTest(mouseVX, mouseVY, dx, dy, DICE_SIZE, DICE_SIZE);

            // Die background — frozen wins over every other state.
            c.save();
            if (frozen[i])
                c.fillStyle = rgba(150, 150, 150, 255); // grey — can't reroll
            else if (hovered)
                c.fillStyle = rgba(255, 255, 100, 255); // yellow on hover
            else if (isKept && diceInteractive)
                c.fillStyle = rgba(255, 100, 100, 255); // light red for kept
            else
                c.fillStyle = rgba(240, 240, 240, 255); // white (neutral)
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

        rerollButton().draw(c, mouseVX, mouseVY);
        instantButton().draw(c, mouseVX, mouseVY);
        magicButton().draw(c, mouseVX, mouseVY);
    }

    /// Fill a rectangular button using the Couture red / light-red scheme.
    static void drawButtonRect(Canvas* c, float x, float y, float w, float h, bool hovered)
    {
        c.save();
        c.fillStyle = hovered ? btnColorHover() : btnColorIdle();
        c.beginPath();
        c.moveTo(x, y);
        c.lineTo(x + w, y);
        c.lineTo(x + w, y + h);
        c.lineTo(x, y + h);
        c.closePath();
        c.fill();
        c.restore();
    }

    /// Translucent vertical wall drawn next to a player to signal an
    /// active parry. `facingRight` true puts the wall to the right of the
    /// avatar (P1 facing P2), false puts it on the left (P2 facing P1).
    static void drawParryWall(Canvas* c, float cx, float cy, bool facingRight)
    {
        float wallW = 14.0f;
        float wallH = 200.0f;
        float offset = 56.0f;
        float wx = facingRight ? cx + offset : cx - offset - wallW;
        float wy = cy - wallH / 2;

        // Soft cyan slab + a brighter inner stripe for a "force-field" feel.
        c.save();
        c.fillStyle = rgba(120, 200, 255, 140);
        c.beginPath();
        c.moveTo(wx, wy);
        c.lineTo(wx + wallW, wy);
        c.lineTo(wx + wallW, wy + wallH);
        c.lineTo(wx, wy + wallH);
        c.closePath();
        c.fill();
        c.restore();

        c.save();
        c.fillStyle = rgba(220, 240, 255, 220);
        float innerW = 4.0f;
        float innerX = wx + (wallW - innerW) / 2;
        c.beginPath();
        c.moveTo(innerX, wy);
        c.lineTo(innerX + innerW, wy);
        c.lineTo(innerX + innerW, wy + wallH);
        c.lineTo(innerX, wy + wallH);
        c.closePath();
        c.fill();
        c.restore();
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

    /// Draw 6 HP rows + 1 MP row for one player.
    static void drawPlayerHP(TM_Console* con, ref Avatar avatar, int mp,
                             int col, int startRow)
    {
        static immutable string[6] names = [
            "L.Leg ",
            "R.Leg ",
            "L.Arm ",
            "R.Arm ",
            "Chest ",
            "Head  ",
        ];

        // Content width: name(6) + bar(5) + " N/5 HP"(7) = 18
        // Box: pad(1) + content(18) + border(1) = 20.
        // Panel is now 9 rows tall: top border + 6 HP + 1 MP + bottom border.
        enum boxW = 20;

        with (con)
        {
            // Top border
            locate(col, startRow);
            bg(TM_colorGrey);
            fg(TM_colorGrey);
            foreach (_; 0 .. boxW)
                print(" ");

            // HP rows
            foreach (i; 0 .. NUM_BODY_PARTS)
            {
                locate(col, startRow + 1 + i);
                bg(TM_colorGrey);

                // Name
                fg(TM_colorWhite);
                print(" ");
                print(names[i]);

                int hp = avatar.hp[i];

                // HP bar — white background, light red pips.
                bg(TM_colorWhite);
                foreach (j; 0 .. MAX_HP)
                {
                    if (j < hp)
                    {
                        fg(TM_colorLRed);
                        print("\u25A0");
                    }
                    else
                    {
                        fg(TM_colorGrey);
                        print("\u25A1");
                    }
                }
                bg(TM_colorGrey);

                // Numeric display
                fg(TM_colorWhite);
                print(" " ~ hp.to!string ~ "/" ~ MAX_HP.to!string ~ " HP");

                // Right border
                print(" ");
            }

            // MP row
            locate(col, startRow + 1 + NUM_BODY_PARTS);
            bg(TM_colorGrey);
            fg(TM_colorWhite);
            print(" ");
            print("MP    ");

            // MP bar — white background, blue pips.
            bg(TM_colorWhite);
            foreach (j; 0 .. MAX_MP)
            {
                if (j < mp)
                {
                    fg(TM_colorLBlue);
                    print("\u25A0");
                }
                else
                {
                    fg(TM_colorGrey);
                    print("\u25A1");
                }
            }
            bg(TM_colorGrey);
            fg(TM_colorWhite);
            print(" " ~ mp.to!string ~ "/" ~ MAX_MP.to!string ~ " MP");
            print(" ");

            // Bottom border
            locate(col, startRow + 2 + NUM_BODY_PARTS);
            bg(TM_colorGrey);
            foreach (_; 0 .. boxW)
                print(" ");

            // Reset bg
            bg(TM_colorBlack);
        }
    }

    /// Draw text labels using textmode console
    void drawText(TM_Console* con)
    {
        with (con)
        {
            // Player 1 label (top-left)
            if (activePlayer == 0)
            {
                fg(TM_colorLRed);
                box(0, 0, 16, 5, TM_boxHeavyPlus);
                locate(2, 2);
                fg(TM_colorWhite);
                print(" ACTIVE  P1 ");
            }
            else
            {
                fg(TM_colorRed);
                box(0, 0, 8, 5, TM_boxHeavyPlus);
                locate(2, 2);
                fg(TM_colorWhite);
                print(" P1 ");
            }

            // Player 2 label (top-right)
            if (activePlayer == 1)
            {
                fg(TM_colorLRed);
                box(64, 0, 16, 5, TM_boxHeavyPlus);
                locate(66, 2);
                fg(TM_colorWhite);
                print(" P2  ACTIVE ");
            }
            else
            {
                fg(TM_colorRed);
                box(72, 0, 8, 5, TM_boxHeavyPlus);
                locate(74, 2);
                fg(TM_colorWhite);
                print(" P2 ");
            }

            // Body part HP + MP panel for each player. Panel moved one row
            // up (35 instead of 36) to make room for the MP row.
            drawPlayerHP(con, players[0].avatar, players[0].mp, 0, 35);
            drawPlayerHP(con, players[1].avatar, players[1].mp, 58, 35);

            // Rerolls remaining this turn. Banked rerolls are shown as
            // diamonds next to the player labels, not inline here.
            locate(32, 1);
            fg(TM_colorWhite);
            int rerollsLeft = totalRollsThisTurn() - rollsUsed;
            print(format("%d rerolls remaining.", rerollsLeft));

            // Diamond indicators next to each player label:
            //   active player -> rerolls remaining this turn
            //   other player  -> banked rerolls stored for their next turn
            int p1Pips = (activePlayer == 0) ? rerollsLeft : players[0].bankedRerolls;
            int p2Pips = (activePlayer == 1) ? rerollsLeft : players[1].bankedRerolls;
            int p1LabelEnd = (activePlayer == 0) ? 16 : 8;
            int p2LabelStart = (activePlayer == 1) ? 64 : 72;

            if (p1Pips > 0)
            {
                locate(p1LabelEnd + 1, 1);
                fg(TM_colorLRed);
                foreach (_; 0 .. p1Pips)
                    print("*");
            }
            if (p2Pips > 0)
            {
                locate(p2LabelStart - 1 - p2Pips, 1);
                fg(TM_colorLRed);
                foreach (_; 0 .. p2Pips)
                    print("*");
            }

            // "KEEP" tag below each kept die — only while rerolls remain.
            if (phase == Phase.selecting && rollsUsed < totalRollsThisTurn())
            {
                float totalDiceW = NUM_DICE * DICE_SIZE + (NUM_DICE - 1) * DICE_GAP;
                float startX = (VIRTUAL_W - totalDiceW) / 2;
                foreach (i; 0 .. NUM_DICE)
                {
                    if (!players[activePlayer].dice.kept[i])
                        continue;
                    float dx = startX + i * (DICE_SIZE + DICE_GAP);
                    int col, row;
                    centerTextInRect(dx, DICE_Y + DICE_SIZE + CELL_VIRTUAL,
                                     DICE_SIZE, cast(float) CELL_VIRTUAL,
                                     4, col, row);
                    locate(col, row);
                    fg(TM_colorRed);
                    print("KEEP");
                }
            }

            // Damage preview — active player's dice. Centered in the open
            // space above the dice, both horizontally and vertically.
            if (phase == Phase.selecting || phase == Phase.resolving)
            {
                fg(TM_colorWhite);
                auto lines = previewDamageLines();
                int n = cast(int) lines.length;
                // Vertical mid of the area between the top labels (row 3)
                // and the dice (~row 25): ~row 14. Center the block there.
                int startRow = 14 - n / 2;
                foreach (i, line; lines)
                {
                    int col = (CONSOLE_COLS - cast(int) line.length) / 2;
                    if (col < 0) col = 0;
                    locate(col, startRow + cast(int) i);
                    print(line);
                }
            }

            rerollButton().drawLabel(con);
            magicButton().drawLabel(con);
            instantButton().drawLabel(con);

            if (phase == Phase.gameOver)
            {
                // GAME OVER, centered.
                enum goMsg = "GAME OVER";
                locate((CONSOLE_COLS - cast(int) goMsg.length) / 2, 14);
                fg(TM_colorLRed);
                print(goMsg);

                // Winner line, centered.
                int winCol = (CONSOLE_COLS - cast(int) statusText.length) / 2;
                if (winCol < 0) winCol = 0;
                locate(winCol, 16);
                fg(TM_colorWhite);
                print(statusText);

                // "Click to play again", centered and blinking.
                enum clickMsg = "Click to play again";
                locate((CONSOLE_COLS - cast(int) clickMsg.length) / 2, 18);
                fg(TM_colorWhite);
                style(TM_styleBlink);
                print(clickMsg);
                style(TM_styleNone);
            }
            // Help text at bottom center
            fg(TM_colorGrey);
            locate(24, 42);
            print("Select dice to keep with mouse.");
            locate(27, 43);
            print("Re-roll with RETURN.");
        }
    }

    /// Textmode layer of the Upgrade / Tech tree screen.
    void drawUpgradeText(TM_Console* con)
    {
        with (con)
        {
            // Title
            enum title = "MAGIC";
            locate((CONSOLE_COLS - cast(int) title.length) / 2, 4);
            fg(TM_colorLRed);
            print(title);

            // Active player + MP balance
            string who = format("Player %d", activePlayer + 1);
            locate((CONSOLE_COLS - cast(int) who.length) / 2, 6);
            fg(TM_colorWhite);
            print(who);

            string mpLine = format("%d MP", players[activePlayer].mp);
            locate((CONSOLE_COLS - cast(int) mpLine.length) / 2, 7);
            fg(TM_colorWhite);
            print(mpLine);

            repairButton().drawLabel(con);

            // Description line under REPAIR
            enum desc = "Restores 1 HP on your most damaged body part.";
            locate((CONSOLE_COLS - cast(int) desc.length) / 2,
                   cast(int)((REPAIR_Y + REPAIR_H + 6) / CELL_VIRTUAL));
            fg(TM_colorGrey);
            print(desc);

            reinforceButton().drawLabel(con);

            // Description line under REINFORCE HELMET
            enum reinforceDesc = "Head takes -2 damage; grows a helmet if missing.";
            locate((CONSOLE_COLS - cast(int) reinforceDesc.length) / 2,
                   cast(int)((REINFORCE_Y + REINFORCE_H + 6) / CELL_VIRTUAL));
            fg(TM_colorGrey);
            print(reinforceDesc);

            backButton().drawLabel(con);
        }
    }
}

