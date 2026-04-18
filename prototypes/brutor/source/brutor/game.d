module brutor.game;

import turtle;
import textmode;
import brutor.dice;
import brutor.avatar;
import brutor.combat;
import std.conv : to;
import std.format : format;
import std.string : indexOf;

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
enum MAX_REROLLS = 5;

/// A clickable button. Holds its bounds, label, and visibility/enabled
/// flags, and knows how to hit-test, render its background (canvas), and
/// place its label (textmode).
struct Button
{
    float x, y, w, h;
    string label;
    bool enabled = true;   // false → grey background AND not clickable
    bool visible = true;   // false skips draw and hit-test
    bool purchased = false; // true → render green, hover state suppressed
    bool blueStyle = false; // true → blue idle/hover (matches the MP color)

    /// Pure bounds test — true whenever the cursor is inside the button
    /// rect and it's visible. Doesn't care about `enabled`/`purchased`,
    /// so callers can drive hover effects (like tooltips) on locked or
    /// already-bought buttons that shouldn't be clickable.
    bool isHovered(float px, float py) const
    {
        if (!visible) return false;
        return px >= x && px <= x + w && py >= y && py <= y + h;
    }

    /// Click-gate: hover AND the button is accepting input.
    bool hitTest(float px, float py) const
    {
        return isHovered(px, py) && enabled;
    }

    void draw(Canvas* c, float mouseVX, float mouseVY) const
    {
        if (!visible) return;
        if (purchased)
        {
            fillRect(c, rgba(70, 140, 70, 255)); // owned = green
            return;
        }
        if (!enabled)
        {
            fillRect(c, rgba(80, 80, 85, 255));  // locked = grey
            return;
        }
        if (blueStyle)
        {
            bool hovered = hitTest(mouseVX, mouseVY);
            // Idle matches the MP palette entry (rgba(70,130,220,255) set
            // in main.d); hover brightens toward white.
            fillRect(c, hovered
                ? rgba(120, 180, 255, 255)
                : rgba(70, 130, 220, 255));
            return;
        }
        GameState.drawButtonRect(c, x, y, w, h, hitTest(mouseVX, mouseVY));
    }

    private void fillRect(Canvas* c, Color col) const
    {
        c.save();
        c.fillStyle = col;
        c.beginPath();
        c.moveTo(x, y);
        c.lineTo(x + w, y);
        c.lineTo(x + w, y + h);
        c.lineTo(x, y + h);
        c.closePath();
        c.fill();
        c.restore();
    }

    void drawLabel(TM_Console* con) const
    {
        if (!visible || label.length == 0) return;
        int col, row;
        GameState.centerTextInRect(x, y, w, h,
                                   GameState.visibleCCLLen(label), col, row);
        con.locate(col, row);
        // White reads well on red (idle), green (owned), and grey (locked).
        // Use cprint so labels can embed CCL tags (e.g. "<lmagenta>...</lmagenta>").
        con.fg(TM_colorWhite);
        con.cprint(label);
    }
}

struct Player
{
    DiceSet dice;
    Avatar avatar;
    int mp = 0;
    // Persistent reroll pool. Grows by +2 at the start of each of this
    // player's turns (-1 per missing arm), clamped to [0, MAX_REROLLS].
    // The initial roll of a turn is free; every subsequent reroll costs 1.
    int rerolls = 0;
    // Helmet tier. Incoming head damage is reduced by helmetLevel (min 0).
    //   0 = no helmet, 1 = basic (match-start default), 2 = reinforced.
    int helmetLevel = 1;
    // Shield tier wielded by the left arm:
    //   0 = no shield (left arm destroyed, or lost before SHIELD++ restored it)
    //   1 = basic shield (match-start default, cosmetic only)
    //   2 = SHIELD++ (blocks 2 damage to the left arm and chest)
    // Dropped to 0 permanently when the left arm is destroyed — healing
    // the arm back does NOT restore the shield; only the SHIELD++ upgrade does.
    int shieldLevel = 1;
    // Parry wall — set by rolling a straight. Blocks ALL incoming damage
    // on the opponent's very next turn, then clears.
    bool parryActive = false;
    // Bit i set = UPGRADES[i] has been purchased this match. One-shot
    // purchases — once owned, the upgrade can't be bought again.
    ulong upgradesPurchasedMask = 0;
    // Nudges available this turn (+1 on any die, wraps 6→1). Set at the
    // start of each of this player's turns to 1 if the NUDGE upgrade is
    // owned, else 0. Decremented on use.
    int nudgesRemainingThisTurn = 0;

    void reset()
    {
        dice.reset();
        avatar.reset();
        mp = 0;//5;
        rerolls = 0;
        helmetLevel = 1;
        shieldLevel = 1;
        parryActive = false;
        upgradesPurchasedMask = 0;
        nudgesRemainingThisTurn = 0;
    }

    bool isUpgradePurchased(size_t i) const
    {
        return (upgradesPurchasedMask & (1UL << i)) != 0;
    }
}

/// Data-driven upgrade definition. Add a new upgrade by appending one
/// entry to `UPGRADES` and writing its `apply` / `isAvailable` callbacks.
/// `positionInTreeX/Y` are abstract grid coordinates consumed by the
/// upgrade screen layout (tech tree rendering — see TODO_upgrade.md).
/// Sentinel for `Upgrade.requiredId` meaning "no prerequisite".
enum UPGRADE_NO_PREREQ = -1;

struct Upgrade
{
    /// Unique, stable id for this upgrade. Referenced by other upgrades'
    /// `requiredId` to express a prior-purchase dependency.
    int id;
    /// Id of the upgrade that must have been purchased by the active
    /// player before this one becomes available. UPGRADE_NO_PREREQ when
    /// there's no prerequisite.
    int requiredId;
    string name;
    int costInMP;
    string desc;
    /// Applies the upgrade and returns a short toast describing what was
    /// done (e.g. "Repaired Left Arm +1 HP"). An empty string means
    /// "nothing to toast".
    string function(ref Player me, Player other) apply;
    bool function(ref Player me) isAvailable;
    int positionInTreeX;
    int positionInTreeY;
}

private string applyReinforceHelmet(ref Player me, Player other)
{
    me.helmetLevel = 2;
    return "Helmet upgraded";
}

private bool isReinforceAvailable(ref Player me)
{
    return me.helmetLevel < 2;
}

private string applyShieldPlus(ref Player me, Player other)
{
    me.shieldLevel = 2;
    return "Shield upgraded";
}

private bool isShieldPlusAvailable(ref Player me)
{
    return me.shieldLevel < 2;
}

/// Upgrade ids referenced from code that needs to find them by meaning
/// rather than index (e.g. per-turn refresh logic).
enum NUDGE_UPGRADE_ID = 5;
enum INSTANT_PLUS_UPGRADE_ID = 7;
enum PAIR_UPGRADE_ID = 8;

private string applyNudge(ref Player me, Player other)
{
    // Grant the first nudge immediately so the buyer feels it this turn;
    // startTurn() re-primes 1 per turn thereafter.
    me.nudgesRemainingThisTurn = 1;
    return "Nudge unlocked";
}

private bool isNudgeAvailable(ref Player me)
{
    // NUDGE always grants a new per-turn ability on purchase, so it's
    // always "available" until the one-shot mask blocks re-purchase.
    return true;
}

private string applyInstantPlus(ref Player me, Player other)
{
    return "INSTANT at any time";
}

private bool isInstantPlusAvailable(ref Player me)
{
    return true;
}

private string applyPair(ref Player me, Player other)
{
    return "Pair combos enabled";
}

private bool isPairAvailable(ref Player me)
{
    return true;
}

/// REGROW: revive a dead body part (HP == 0) back to 2, scanning body
/// parts in priority order 6 → 1 (head, chest, rightArm, leftArm, rightLeg,
/// leftLeg). If nothing is dead, add 2 HP to the lowest-HP body part
/// (capped at MAX_HP), same priority order breaking ties.
private string applyRegrow(ref Player me, Player other)
{
    foreach_reverse (i; 0 .. NUM_BODY_PARTS)
    {
        if (me.avatar.hp[i] == 0)
        {
            me.avatar.hp[i] = 2;
            return format("Regrew %s to 2 HP", bodyPartName(cast(BodyPart) i));
        }
    }
    int target = -1;
    int lowest = MAX_HP + 1;
    foreach_reverse (i; 0 .. NUM_BODY_PARTS)
    {
        int hp = me.avatar.hp[i];
        if (hp >= MAX_HP) continue;
        if (hp < lowest) { lowest = hp; target = cast(int) i; }
    }
    if (target == -1) return "";
    int newHP = lowest + 2;
    if (newHP > MAX_HP) newHP = MAX_HP;
    me.avatar.hp[target] = newHP;
    return format("Restored %s to %d HP", bodyPartName(cast(BodyPart) target), newHP);
}

private bool isRegrowAvailable(ref Player me)
{
    foreach (hp; me.avatar.hp)
        if (hp < MAX_HP) return true;
    return false;
}

/// REINCARNATION: restore every body part to MAX_HP. Requires REGROW.
private string applyReincarnation(ref Player me, Player other)
{
    me.avatar.reset();
    return "Reincarnated at full HP";
}

private bool isReincarnationAvailable(ref Player me)
{
    foreach (hp; me.avatar.hp)
        if (hp < MAX_HP) return true;
    return false;
}

immutable Upgrade[] UPGRADES = [
    Upgrade(
        2, UPGRADE_NO_PREREQ,
        "HELMET++",
        1,
        "Restore helmet\n-2 dmg to head",
        &applyReinforceHelmet,
        &isReinforceAvailable,
        0, -1,   // defense → above center
    ),
    Upgrade(
        3, /*requires HELMET++*/ 2,
        "SHIELD++",
        1,
        "Restore shield\n-2 dmg L.arm/chest",
        &applyShieldPlus,
        &isShieldPlusAvailable,
        -1, -1,  // top-left, to the left of HELMET++
    ),
    Upgrade(
        4, UPGRADE_NO_PREREQ,
        "REGROW",
        1,
        "Revive dead part\nor +2 to lowest",
        &applyRegrow,
        &isRegrowAvailable,
        -1, 0,   // heal → left of center
    ),
    Upgrade(
        NUDGE_UPGRADE_ID, UPGRADE_NO_PREREQ,
        "NUDGE",
        1,
        "1 nudge/turn\n+1 to any die",
        &applyNudge,
        &isNudgeAvailable,
        1, 0,    // dice → right of center
    ),
    Upgrade(
        6, /*requires REGROW*/ 4,
        "REINCARNATION",
        3,
        "Back to full HP\non all parts",
        &applyReincarnation,
        &isReincarnationAvailable,
        -1, 1,   // heal → directly below REGROW
    ),
    Upgrade(
        INSTANT_PLUS_UPGRADE_ID, /*requires NUDGE*/ NUDGE_UPGRADE_ID,
        "INSTANT++",
        2,
        "INSTANT at any time",
        &applyInstantPlus,
        &isInstantPlusAvailable,
        1, 1,    // dice → directly below NUDGE
    ),
    Upgrade(
        PAIR_UPGRADE_ID, UPGRADE_NO_PREREQ,
        "PAIRS",
        2,
        "Pairs deal damage\n1♦DMG per pair",
        &applyPair,
        &isPairAvailable,
        0, 1,    // attack → directly below center
    ),
];

/// Index into UPGRADES for the upgrade with the given id, or -1 if no
/// such upgrade exists.
private int upgradeIndexById(int id)
{
    foreach (i, ref u; UPGRADES)
        if (u.id == id)
            return cast(int) i;
    return -1;
}

struct GameState
{
    Player[2] players;
    int activePlayer = 0;     // 0 or 1
    // Rolls taken this turn. 0 before the initial (free) roll, 1 after,
    // incrementing for each subsequent reroll.
    int rollsUsed = 0;
    Phase phase = Phase.rolling;
    string statusText = "";
    // Short message shown on the upgrade screen after a successful
    // purchase (e.g. "Repaired Left Arm +1 HP"). Cleared on re-entering
    // the upgrade screen.
    string upgradeToast = "";

    // Damage animation state. When phase == resolving, animTimer counts
    // down; `hitAnim` marks body parts on the opponent (= damage receiver)
    // that should flash during the animation.
    float animTimer = 0;
    bool[NUM_BODY_PARTS] hitAnim;
    enum float ANIM_DURATION = 0.8f;    // seconds
    enum float ANIM_BLINK_PERIOD = 0.1f; // seconds per on/off frame

    // Heal animation state — mirrors the damage flash but in green and
    // tied to the player that just got healed (not always the opponent).
    // Ticks down independently of `phase` so purchases animate even if
    // the player lingered on the upgrade screen before popping back.
    float healAnimTimer = 0;
    bool[NUM_BODY_PARTS] healAnim;
    int healAnimPlayer = 0;

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

    // Layout constants (virtual pixels). Dice are sized to 6x6 cells
    // (6 * CELL_VIRTUAL = 72) and top-aligned to the console grid.
    enum DICE_SIZE = 72.0f;
    enum DICE_GAP = cast(float) CELL_VIRTUAL; // 1 console col between dice
    enum DICE_Y = 276.0f; // row 23, dice occupy rows 23..28
    // Cell rows for the per-die tags, one row above/below the dice block.
    enum DICE_TAG_ROW_ABOVE = 21; // y = 252
    enum DICE_TAG_ROW_BELOW = 30; // y = 360
    // 264 = 22 console cells. REROLL and INSTANT share this width so
    // they line up vertically.
    enum REROLL_W = 264.0f;
    enum REROLL_H = 40.0f;
    enum REROLL_Y = 390.0f;

    // "INSTANT" button: shown whenever the active player has a damaging
    // combo AND still has rerolls left. Resolves the turn now, leaving
    // the reroll pool as-is (unused rerolls stay for future turns).
    // Sits directly below the REROLL button.
    enum INSTANT_W = REROLL_W;
    enum INSTANT_H = 40.0f;
    enum INSTANT_Y = REROLL_Y + REROLL_H + 10.0f; // 440

    // "MAGIC" button — horizontally centered near the top of the screen.
    enum MAGIC_W = 180.0f;
    enum MAGIC_H = 36.0f;
    enum MAGIC_X = (VIRTUAL_W - MAGIC_W) / 2;  // 390
    enum MAGIC_Y = 48.0f;                       // row 4, cell-aligned so label centers

    // Upgrade screen layout — a tech tree centered on (TREE_CX, TREE_CY).
    // The (0, 0) slot is the "WARRIOR" base node, already taken; every
    // UPGRADES entry occupies a cardinal slot around it:
    //   Defense → above   (0, -1)
    //   Attack  → below   (0, +1)
    //   Heal    → left    (-1, 0)
    //   Dice    → right   (+1, 0)
    enum TREE_CX = cast(float) VIRTUAL_W / 2;  // 480 = col 40
    enum TREE_CY = 282.0f;                     // chosen so slots land on cells
    enum TREE_CENTER_W = UPGRADE_W;            // matches upgrade buttons
    enum TREE_CENTER_H = UPGRADE_H;            // matches upgrade buttons
    enum UPGRADE_W = 216.0f;                   // 18 cols
    enum UPGRADE_H = 60.0f;                    // 5 rows
    enum UPGRADE_DX = 240.0f;                  // 20 cols (2-col gap)
    enum UPGRADE_DY = 84.0f;                   // 7 rows (2-row gap)
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
        phase = Phase.rolling;
        statusText = "";
        upgradeToast = "";
        animTimer = 0;
        hitAnim[] = false;
        healAnimTimer = 0;
        healAnim[] = false;
        healAnimPlayer = 0;
    }

    /// Get the opponent of the active player
    int opponent()
    {
        return 1 - activePlayer;
    }

    /// Start a new turn for the active player. Tops up the persistent
    /// reroll pool by +2, minus one per missing arm, clamped to
    /// [0, MAX_REROLLS]. The initial roll is free; subsequent rerolls
    /// deduct from the pool.
    void startTurn()
    {
        players[activePlayer].dice.reset();
        rollsUsed = 0;
        auto av = players[activePlayer].avatar;
        int gain = 2;
        if (av.hp[BodyPart.leftArm]  == 0) gain--;
        if (av.hp[BodyPart.rightArm] == 0) gain--;
        int newPool = players[activePlayer].rerolls + gain;
        if (newPool < 0) newPool = 0;
        if (newPool > MAX_REROLLS) newPool = MAX_REROLLS;
        players[activePlayer].rerolls = newPool;
        // Refill nudges for the active player if they own the NUDGE upgrade.
        int nudgeIdx = upgradeIndexById(NUDGE_UPGRADE_ID);
        players[activePlayer].nudgesRemainingThisTurn =
            (nudgeIdx >= 0 && players[activePlayer].isUpgradePurchased(nudgeIdx)) ? 1 : 0;
        phase = Phase.rolling;
        statusText = "";
    }

    /// Spend one of the active player's nudges to add +1 to die `index`,
    /// wrapping 6→1. No-op if not selecting, out of nudges, or the index
    /// is out of range.
    void nudgeDice(int index)
    {
        if (phase != Phase.selecting) return;
        if (index < 0 || index >= NUM_DICE) return;
        if (players[activePlayer].nudgesRemainingThisTurn <= 0) return;
        int v = players[activePlayer].dice.values[index];
        v = (v >= 6) ? 1 : v + 1;
        players[activePlayer].dice.values[index] = v;
        players[activePlayer].nudgesRemainingThisTurn--;
    }

    /// True while the active player can still roll: either the initial
    /// (free) roll hasn't happened yet, or at least one reroll remains
    /// in the pool.
    bool canRollMore() const
    {
        if (rollsUsed == 0) return true;
        return players[activePlayer].rerolls > 0;
    }

    /// The active player can only toggle KEEP on dice while their head is
    /// still intact.
    bool canKeep() const
    {
        return players[activePlayer].avatar.hp[BodyPart.head] > 0;
    }

    /// Status lines (label + short rule explanation) to display under a
    /// player's label, in order. Only currently-active statuses are returned.
    static struct PlayerStatus { string label; string explain; }
    PlayerStatus[] playerStatuses(int idx)
    {
        PlayerStatus[] out_;
        auto av = players[idx].avatar;
        if (av.hp[BodyPart.head] == 0)
            out_ ~= PlayerStatus("Beheaded", "no KEEP");
        if (av.hp[BodyPart.chest] == 0)
            out_ ~= PlayerStatus("Impaled", "-1 HP all parts/turn");
        int armsGone = 0;
        if (av.hp[BodyPart.leftArm]  == 0) armsGone++;
        if (av.hp[BodyPart.rightArm] == 0) armsGone++;
        if (armsGone == 1)
            out_ ~= PlayerStatus("One-armed", "-1 reroll/turn");
        else if (armsGone == 2)
            out_ ~= PlayerStatus("No arms", "-2 rerolls/turn");
        int legsGone = 0;
        if (av.hp[BodyPart.leftLeg]  == 0) legsGone++;
        if (av.hp[BodyPart.rightLeg] == 0) legsGone++;
        if (legsGone == 1)
            out_ ~= PlayerStatus("Crippled leg", "1 die frozen");
        else if (legsGone == 2)
            out_ ~= PlayerStatus("No legs", "2 dice frozen");
        return out_;
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

    /// Perform a roll. The initial roll (rollsUsed == 0) is free; every
    /// subsequent reroll consumes 1 from the active player's pool.
    /// On rerolls, missing legs freeze dice at the high indices.
    void doRoll()
    {
        bool[NUM_DICE] frozen;
        if (rollsUsed >= 1)
        {
            frozen = legDebuffMask();
            players[activePlayer].rerolls--;
        }
        players[activePlayer].dice.roll(frozen);
        rollsUsed++;
        // Always go to selecting so the player can see their dice
        // If no rolls remain, they can only click CONFIRM
        phase = Phase.selecting;
    }

    /// Flat MP gain awarded for a full house, regardless of body-part state.
    enum int FULL_HOUSE_MP = 2;

    /// Active player's dice combos with upgrade-gated combos filtered out.
    /// Pair (and two-pair) hands are inert unless the player owns PAIRS or
    /// the combos already form a full house.
    private Combo[] activeCombos()
    {
        auto combos = players[activePlayer].dice.analyze();
        if (isFullHouse(combos))
            return combos;
        int idx = upgradeIndexById(PAIR_UPGRADE_ID);
        bool hasPairs = idx >= 0
            && players[activePlayer].isUpgradePurchased(idx);
        if (hasPairs)
            return combos;
        Combo[] filtered;
        foreach (c; combos)
            if (c.type != ComboType.pair)
                filtered ~= c;
        return filtered;
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
    /// SHIELD++ (shieldLevel == 2) reduces left-arm and chest damage by 2.
    private void applyDefenderModifiers(ref DamageAction[] actions)
    {
        int helm   = players[opponent].helmetLevel;
        int shield = (players[opponent].shieldLevel == 2) ? 2 : 0;
        foreach (ref a; actions)
        {
            if (a.type != DamageAction.Type.flatDamage) continue;
            if (a.target == BodyPart.head && helm > 0)
                a.amount = a.amount > helm ? a.amount - helm : 0;
            else if ((a.target == BodyPart.leftArm || a.target == BodyPart.chest) && shield > 0)
                a.amount = a.amount > shield ? a.amount - shield : 0;
        }
    }

    /// Resolve the current dice against the opponent, apply damage, and
    /// start the damage animation. Turn only switches once the animation
    /// finishes (see update()). Straights raise a parry wall on the active
    /// player; full houses grant MP — both skip the damage animation.
    void doResolve()
    {
        auto combos = activeCombos();

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
            grantMP(FULL_HOUSE_MP);
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
            players[opponent].shieldLevel = 0;

        phase = Phase.resolving;
        animTimer = ANIM_DURATION;
    }

    /// Per-frame update: advances the damage animation and, once done,
    /// either ends the game or hands the turn over to the other player.
    void update(double dt)
    {
        // Heal animation ticks independently of phase so a REPAIR flash
        // finishes even if the player is still browsing the upgrade tree.
        if (healAnimTimer > 0)
        {
            healAnimTimer -= cast(float) dt;
            if (healAnimTimer <= 0)
            {
                healAnimTimer = 0;
                healAnim[] = false;
            }
        }

        if (phase != Phase.resolving)
            return;

        animTimer -= cast(float) dt;
        if (animTimer > 0)
            return;

        animTimer = 0;
        hitAnim[] = false;

        // Impaled: a missing chest bleeds 1 HP from every other living part
        // at the end of the impaled player's turn. Bypasses helmet/shield.
        if (players[activePlayer].avatar.hp[BodyPart.chest] == 0)
        {
            foreach (i; 0 .. NUM_BODY_PARTS)
                if (players[activePlayer].avatar.hp[i] > 0)
                    players[activePlayer].avatar.applyDamage(cast(BodyPart) i, 1);
        }

        if (!players[opponent].avatar.isAlive())
        {
            phase = Phase.gameOver;
            statusText = format("Player %d wins!", activePlayer + 1);
        }
        else if (!players[activePlayer].avatar.isAlive())
        {
            phase = Phase.gameOver;
            statusText = format("Player %d wins!", opponent + 1);
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

    /// Is the heal flash "on" this frame? Matches the damage flash cadence.
    bool healFlashOn() const
    {
        if (healAnimTimer <= 0)
            return false;
        int tick = cast(int)((ANIM_DURATION - healAnimTimer) / ANIM_BLINK_PERIOD);
        return (tick & 1) == 0;
    }

    /// Preview lines describing the damage the active player's current
    /// dice would deal if they ended the turn now. Delegates to
    /// combat.describeDamage so the preview and the actual resolve share
    /// a single source of truth for damage values.
    string[] previewDamageLines()
    {
        auto combos = activeCombos();
        if (isFullHouse(combos))
            return [format("Full house: <lblue>%d\u2301MP</lblue> gained.", FULL_HOUSE_MP)];
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
                    lines ~= format("Helmet \u2192 <lred>-%d\u2666DMG</lred> to head.", reduction);
                    break;
                }
            }
        }

        // SHIELD++ shaves 2 off any left-arm or chest damage.
        if (players[opponent].shieldLevel == 2)
        {
            bool armShown = false, chestShown = false;
            foreach (combo; combos)
            {
                if (combo.target == BodyPart.leftArm && !armShown)
                {
                    lines ~= "Shield \u2192 <lred>-2\u2666DMG</lred> to left arm.";
                    armShown = true;
                }
                else if (combo.target == BodyPart.chest && !chestShown)
                {
                    lines ~= "Shield \u2192 <lred>-2\u2666DMG</lred> to chest.";
                    chestShown = true;
                }
            }
        }
        return lines;
    }

    /// True when the player may click INSTANT: a scoring combo is on the
    /// table (damage, straight, or full house) and at least one reroll
    /// remains in the pool (otherwise INSTANT is equivalent to ending the
    /// turn). Baseline INSTANT is additionally restricted to after the
    /// 1st roll; INSTANT++ lifts that restriction.
    bool canInstant()
    {
        if (phase != Phase.selecting)
            return false;
        if (players[activePlayer].rerolls <= 0)
            return false;
        int idx = upgradeIndexById(INSTANT_PLUS_UPGRADE_ID);
        bool anyTime = idx >= 0
            && players[activePlayer].isUpgradePurchased(idx);
        if (!anyTime && rollsUsed >= 2)
            return false;
        auto combos = activeCombos();
        if (combos.length == 0)
            return false;
        return true;
    }

    /// Handle SPACE/ENTER key to roll or end turn
    void handleRollKey()
    {
        if (phase == Phase.selecting)
        {
            if (canRollMore())
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

    /// Visible cell width of a CCL-tagged string — tag bytes (`<...>`)
    /// consume no cells, every other dchar counts as one.
    static int visibleCCLLen(string s) pure
    {
        int n = 0;
        bool inTag = false;
        foreach (dchar c; s)
        {
            if (inTag)
            {
                if (c == '>') inTag = false;
                continue;
            }
            if (c == '<') { inTag = true; continue; }
            n++;
        }
        return n;
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
        // The initial roll is free; after that, rerolls cost 1 from the
        // pool. NEXT TURN replaces REROLL once the pool is empty.
        string lbl;
        if (rollsUsed == 0)
            lbl = "ROLL";
        else if (players[activePlayer].rerolls > 0)
            lbl = "REROLL <lmagenta>-1\u2318</lmagenta>";
        else
            lbl = "NEXT TURN";
        Button b = {
            x: btnX, y: REROLL_Y, w: REROLL_W, h: REROLL_H,
            label: lbl, visible: phase == Phase.selecting,
        };
        return b;
    }

    Button instantButton()
    {
        float btnX = (VIRTUAL_W - INSTANT_W) / 2;
        Button b = {
            x: btnX, y: INSTANT_Y, w: INSTANT_W, h: INSTANT_H,
            label: "INSTANT", visible: canInstant(),
        };
        return b;
    }

    Button magicButton()
    {
        bool vis = phase == Phase.selecting && players[activePlayer].mp > 0;
        Button b = {
            x: MAGIC_X, y: MAGIC_Y, w: MAGIC_W, h: MAGIC_H,
            label: "Upgrade", visible: vis, blueStyle: true,
        };
        return b;
    }

    /// Resolve a tree-grid coordinate into the top-left of its button rect.
    /// (0, 0) is the dead center — the "WARRIOR" base node lives there.
    static void upgradeSlotPos(int treeX, int treeY, out float vx, out float vy)
    {
        float cx = TREE_CX + treeX * UPGRADE_DX;
        float cy = TREE_CY + treeY * UPGRADE_DY;
        vx = cx - UPGRADE_W / 2;
        vy = cy - UPGRADE_H / 2;
    }

    /// Button for the i-th entry in UPGRADES. The button label only
    /// carries the name — cost + effect live in the catalog above the
    /// buttons, so every upgrade reads consistently.
    Button upgradeButton(size_t i)
    {
        auto u = UPGRADES[i];
        float bx, by;
        upgradeSlotPos(u.positionInTreeX, u.positionInTreeY, bx, by);
        bool bought    = players[activePlayer].isUpgradePurchased(i);
        bool canAfford = players[activePlayer].mp >= u.costInMP;
        bool avail     = u.isAvailable(players[activePlayer]);
        bool prereqMet = isPrereqMet(i);
        Button b = {
            x: bx, y: by, w: UPGRADE_W, h: UPGRADE_H,
            label: u.name,
            enabled: !bought && canAfford && avail && prereqMet,
            purchased: bought,
            blueStyle: true,   // match the MP-blue theme for buyable upgrades
        };
        return b;
    }

    /// True when the active player has already bought UPGRADES[i]'s
    /// prerequisite (or it has none).
    bool isPrereqMet(size_t i) const
    {
        int req = UPGRADES[i].requiredId;
        if (req == UPGRADE_NO_PREREQ)
            return true;
        int parentIdx = upgradeIndexById(req);
        if (parentIdx < 0)
            return false; // dangling reference — treat as locked
        return players[activePlayer].isUpgradePurchased(parentIdx);
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
                // Nudge "+1" tags sit one cell below each die (mirroring
                // the KEEP tag above). Check these first so the click is
                // consumed before the dice-body hit-test.
                if (players[activePlayer].nudgesRemainingThisTurn > 0)
                {
                    float totalDiceW = NUM_DICE * DICE_SIZE + (NUM_DICE - 1) * DICE_GAP;
                    float diceStartX = (VIRTUAL_W - totalDiceW) / 2;
                    float nudgeY = DICE_TAG_ROW_BELOW * cast(float) CELL_VIRTUAL;
                    foreach (i; 0 .. NUM_DICE)
                    {
                        float dx = diceStartX + i * (DICE_SIZE + DICE_GAP);
                        if (hitTest(vx, vy, dx, nudgeY, DICE_SIZE, CELL_VIRTUAL))
                        {
                            nudgeDice(cast(int) i);
                            return;
                        }
                    }
                }

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
                    doResolve();
                    return;
                }
                if (rerollButton().hitTest(vx, vy))
                {
                    if (canRollMore())
                        doRoll();
                    else
                        doResolve();
                    return;
                }
                if (magicButton().hitTest(vx, vy))
                {
                    phase = Phase.upgrade;
                    upgradeToast = "";
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
                foreach (i; 0 .. UPGRADES.length)
                {
                    if (upgradeButton(i).hitTest(vx, vy))
                    {
                        tryUpgrade(i);
                        return;
                    }
                }
                if (backButton().hitTest(vx, vy))
                {
                    phase = Phase.selecting;
                    return;
                }
                break;
        }
    }

    /// Apply UPGRADES[i] to the active player. One-shot: an already-bought
    /// upgrade is rejected. Cost is paid only when the upgrade is also
    /// affordable and available (would have an effect).
    void tryUpgrade(size_t i)
    {
        auto u = UPGRADES[i];
        if (players[activePlayer].isUpgradePurchased(i))
            return;
        if (!isPrereqMet(i))
            return;
        if (players[activePlayer].mp < u.costInMP)
            return;
        if (!u.isAvailable(players[activePlayer]))
            return;

        // Snapshot HP so we can detect which part (if any) just healed.
        auto hpBefore = players[activePlayer].avatar.hp;

        upgradeToast = u.apply(players[activePlayer], players[opponent]);
        players[activePlayer].mp -= u.costInMP;
        players[activePlayer].upgradesPurchasedMask |= 1UL << i;

        // Flash every body part whose HP went up (REINCARNATION heals
        // many at once) and pop back to the main screen so the animation
        // is visible on the avatar itself.
        healAnim[] = false;
        bool anyHealed = false;
        foreach (j; 0 .. NUM_BODY_PARTS)
        {
            if (players[activePlayer].avatar.hp[j] > hpBefore[j])
            {
                healAnim[j] = true;
                anyHealed = true;
            }
        }
        if (anyHealed)
        {
            healAnimPlayer = activePlayer;
            healAnimTimer = ANIM_DURATION;
            phase = Phase.selecting;
        }
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

        // Only the opponent (= damage receiver this turn) flashes white.
        bool flashOn = animFlashOn();
        bool[NUM_BODY_PARTS] noFlash;
        auto flash0 = (opponent == 0) ? hitAnim : noFlash;
        auto flash1 = (opponent == 1) ? hitAnim : noFlash;

        // Green heal flash targets whichever player was just healed.
        bool healOn = healFlashOn();
        auto heal0 = (healAnimTimer > 0 && healAnimPlayer == 0) ? healAnim : noFlash;
        auto heal1 = (healAnimTimer > 0 && healAnimPlayer == 1) ? healAnim : noFlash;

        players[0].avatar.draw(c, avatar1X, avatarY, avatarScale,
                               flash0, flashOn,
                               players[0].helmetLevel, players[0].shieldLevel > 0,
                               heal0, healOn);
        players[1].avatar.draw(c, avatar2X, avatarY, avatarScale,
                               flash1, flashOn,
                               players[1].helmetLevel, players[1].shieldLevel > 0,
                               heal1, healOn);

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
        // Connectors first so nodes paint on top of them. Each upgrade
        // links to its prereq (if any) or to the central WARRIOR node.
        foreach (i; 0 .. UPGRADES.length)
        {
            auto u = UPGRADES[i];
            float cx, cy, cw, ch; // child rect (the upgrade)
            upgradeSlotPos(u.positionInTreeX, u.positionInTreeY, cx, cy);
            cw = UPGRADE_W;
            ch = UPGRADE_H;

            float px, py, pw, ph; // parent rect
            int parentIdx = (u.requiredId == UPGRADE_NO_PREREQ)
                          ? -1
                          : upgradeIndexById(u.requiredId);
            if (parentIdx >= 0)
            {
                auto p = UPGRADES[parentIdx];
                upgradeSlotPos(p.positionInTreeX, p.positionInTreeY, px, py);
                pw = UPGRADE_W;
                ph = UPGRADE_H;
            }
            else
            {
                px = TREE_CX - TREE_CENTER_W / 2;
                py = TREE_CY - TREE_CENTER_H / 2;
                pw = TREE_CENTER_W;
                ph = TREE_CENTER_H;
            }
            drawTreeConnector(c, cx, cy, cw, ch, px, py, pw, ph);
        }

        // Central "WARRIOR" base node — already taken; not clickable.
        drawTreeCenter(c);

        // Upgrade buttons in their cardinal slots.
        foreach (i; 0 .. UPGRADES.length)
            upgradeButton(i).draw(c, mouseVX, mouseVY);

        backButton().draw(c, mouseVX, mouseVY);
    }

    /// Render the central "WARRIOR" node with an owned/taken color.
    static void drawTreeCenter(Canvas* c)
    {
        float bx = TREE_CX - TREE_CENTER_W / 2;
        float by = TREE_CY - TREE_CENTER_H / 2;
        c.save();
        c.fillStyle = rgba(70, 95, 70, 255); // dark green = already owned
        c.beginPath();
        c.moveTo(bx, by);
        c.lineTo(bx + TREE_CENTER_W, by);
        c.lineTo(bx + TREE_CENTER_W, by + TREE_CENTER_H);
        c.lineTo(bx, by + TREE_CENTER_H);
        c.closePath();
        c.fill();
        c.restore();
    }

    /// Thin filled rectangle linking a child rect to a parent rect.
    /// Both rects must share either a column (vertical connector) or a
    /// row (horizontal connector); otherwise nothing is drawn.
    static void drawTreeConnector(Canvas* c,
                                  float cx, float cy, float cw, float ch,
                                  float px, float py, float pw, float ph)
    {
        float childMidX  = cx + cw / 2;
        float childMidY  = cy + ch / 2;
        float parentMidX = px + pw / 2;
        float parentMidY = py + ph / 2;

        enum thickness = 4.0f;
        Color col = rgba(120, 90, 60, 220);

        // Tolerance for "same column/row" comparison — rects are placed
        // on the same grid so equality should be exact, but guard anyway.
        enum float eps = 0.5f;

        c.save();
        c.fillStyle = col;
        c.beginPath();

        if (childMidX > parentMidX - eps && childMidX < parentMidX + eps)
        {
            // Vertical: draw between the two facing horizontal edges.
            float top, bot;
            if (cy < py) { top = cy + ch; bot = py; }
            else         { top = py + ph; bot = cy; }
            float x = parentMidX;
            c.moveTo(x - thickness / 2, top);
            c.lineTo(x + thickness / 2, top);
            c.lineTo(x + thickness / 2, bot);
            c.lineTo(x - thickness / 2, bot);
        }
        else if (childMidY > parentMidY - eps && childMidY < parentMidY + eps)
        {
            // Horizontal: draw between the two facing vertical edges.
            float left, right;
            if (cx < px) { left = cx + cw; right = px; }
            else         { left = px + pw; right = cx; }
            float y = parentMidY;
            c.moveTo(left,  y - thickness / 2);
            c.lineTo(right, y - thickness / 2);
            c.lineTo(right, y + thickness / 2);
            c.lineTo(left,  y + thickness / 2);
        }
        else
        {
            c.restore();
            return; // diagonal link — not supported yet
        }

        c.closePath();
        c.fill();
        c.restore();
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
                            && canRollMore()
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

    /// Draw 6 HP rows + 1 Magic row for one player.
    static void drawPlayerHP(TM_Console* con, ref Avatar avatar, int mp,
                             int col, int startRow)
    {
        // Names are prefixed with the dice face (1..6) mapped to each part.
        static immutable string[6] names = [
            "1 L.Leg ",
            "2 R.Leg ",
            "3 L.Arm ",
            "4 R.Arm ",
            "5 Chest ",
            "6 Head  ",
        ];

        // Content width: name(8) + bar(5) + " N/5 HP"(7) = 20
        // Box: pad(1) + content(20) + border(1) = 22.
        // Panel is 9 rows tall: top border + 6 HP + 1 Magic + bottom border.
        enum boxW = 22;

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

            // Magic (MP) row
            locate(col, startRow + 1 + NUM_BODY_PARTS);
            bg(TM_colorGrey);
            fg(TM_colorWhite);
            print(" ");
            print("Magic   ");

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

            // Status list below each player label — label in dark red,
            // short rule explanation in dark grey next to it. P1 kisses
            // the left edge; P2 kisses the right edge (explanation sits
            // on the inner side of the label).
            foreach (i, s; playerStatuses(0))
            {
                int row = 6 + cast(int) i;
                locate(0, row);
                fg(TM_colorRed);
                print(s.label);
                if (s.explain.length)
                {
                    fg(TM_colorGrey);
                    print(" " ~ s.explain);
                }
            }
            foreach (i, s; playerStatuses(1))
            {
                int row = 6 + cast(int) i;
                int labelCol = CONSOLE_COLS - cast(int) s.label.length;
                if (s.explain.length)
                {
                    int explainCol = labelCol - 1 - cast(int) s.explain.length;
                    locate(explainCol, row);
                    fg(TM_colorGrey);
                    print(s.explain);
                }
                locate(labelCol, row);
                fg(TM_colorRed);
                print(s.label);
            }

            // Body part HP + MP panel for each player. Panel moved one row
            // up (35 instead of 36) to make room for the MP row.
            drawPlayerHP(con, players[0].avatar, players[0].mp, 0, 35);
            drawPlayerHP(con, players[1].avatar, players[1].mp, 56, 35);

            // Reroll indicator hugging each player label (8 cells wide):
            //   5-cell magenta bar (filled = pips, empty = remaining capacity)
            //   + space + pip count + ⌘
            //   Shows each player's persistent reroll pool. The active
            //   player's pool shrinks as they spend rerolls this turn.
            int p1Pips = players[0].rerolls;
            int p2Pips = players[1].rerolls;
            int p1LabelEnd = (activePlayer == 0) ? 16 : 8;
            int p2LabelStart = (activePlayer == 1) ? 64 : 72;
            enum int REROLL_BAR_MAX = MAX_REROLLS; // 5 cells

            void drawRerollIndicator(int startCol, int pips)
            {
                locate(startCol, 2);
                foreach (j; 0 .. REROLL_BAR_MAX)
                {
                    if (j < pips) { fg(TM_colorLMagenta); print("\u25A0"); }
                    else          { fg(TM_colorGrey);     print("\u25A1"); }
                }
                fg(TM_colorLMagenta);
                print(format(" %d\u2318", pips));
            }

            drawRerollIndicator(p1LabelEnd + 1, p1Pips);
            drawRerollIndicator(p2LabelStart - 9, p2Pips);

            // Nudges available to the active player this turn, shown
            // next to the active player's label with '+' markers (row 3,
            // mirroring the reroll pips on row 1).
            int nudgesLeft = players[activePlayer].nudgesRemainingThisTurn;
            if (nudgesLeft > 0)
            {
                int nudgeWidth = nudgesLeft * 2; // each "+1" is 2 cells
                if (activePlayer == 0)
                    locate(p1LabelEnd + 1, 3);
                else
                    locate(p2LabelStart - 1 - nudgeWidth, 3);
                fg(TM_colorLGreen);
                foreach (_; 0 .. nudgesLeft)
                    print("+1");
            }

            // "KEEP" tag above each kept die — only while rerolls remain.
            // Cell-aligned so its background lines up cleanly.
            if (phase == Phase.selecting && canRollMore())
            {
                float totalDiceW = NUM_DICE * DICE_SIZE + (NUM_DICE - 1) * DICE_GAP;
                float startX = (VIRTUAL_W - totalDiceW) / 2;
                foreach (i; 0 .. NUM_DICE)
                {
                    if (!players[activePlayer].dice.kept[i])
                        continue;
                    float dx = startX + i * (DICE_SIZE + DICE_GAP);
                    int col = cast(int)((dx + DICE_SIZE * 0.5f) / CELL_VIRTUAL + 0.5f) - 2;
                    locate(col, DICE_TAG_ROW_ABOVE);
                    fg(TM_colorRed);
                    print("KEEP");
                }
            }

            // " +1 " tag below each die — same cell alignment as "KEEP",
            // shown while the active player has a nudge available.
            if (phase == Phase.selecting && nudgesLeft > 0)
            {
                float totalDiceW = NUM_DICE * DICE_SIZE + (NUM_DICE - 1) * DICE_GAP;
                float startX = (VIRTUAL_W - totalDiceW) / 2;
                foreach (i; 0 .. NUM_DICE)
                {
                    float dx = startX + i * (DICE_SIZE + DICE_GAP);
                    int col = cast(int)((dx + DICE_SIZE * 0.5f) / CELL_VIRTUAL + 0.5f) - 2;
                    locate(col, DICE_TAG_ROW_BELOW);
                    fg(TM_colorLGreen);
                    print(" +1 ");
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
                    // Lines may carry CCL tags (e.g. <lred>...</lred>);
                    // strip them out for the centering width, then let
                    // cprint do the actual coloring on render.
                    int visibleLen = 0;
                    bool inTag = false;
                    foreach (ch; line)
                    {
                        if (ch == '<')      { inTag = true;  continue; }                        
                        if (!inTag)         visibleLen++;
                        if (ch == '>')      { inTag = false; continue; }
                    }
                    int col = (CONSOLE_COLS - visibleLen) / 2;
                    if (col < 0) col = 0;
                    locate(col, startRow + cast(int) i);
                    fg(TM_colorWhite);
                    cprint(line);
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
    /// Render the text inside one upgrade button. Idle = name centered;
    /// hovered = description (rows +1, +2) and cost (row +3), with row +0
    /// and row +4 left as margins. Description uses '\n' to split.
    void drawUpgradeButtonText(TM_Console* con, size_t i)
    {
        auto u = UPGRADES[i];
        Button btn = upgradeButton(i);
        // Hover is driven by pure bounds so the description shows even on
        // greyed (locked) or green (already-bought) buttons.
        bool hovered = btn.isHovered(mouseVX, mouseVY);
        // White reads well on every background (red/green/grey/blue); the
        // button rect itself carries the state signal via its color.
        auto color = TM_colorWhite;

        int btnCol = cast(int)(btn.x / CELL_VIRTUAL);
        int btnRow = cast(int)(btn.y / CELL_VIRTUAL);
        enum int BTN_W_COLS = 18;

        if (hovered)
        {
            string line1 = u.desc;
            string line2 = "";
            auto nl = u.desc.indexOf('\n');
            if (nl >= 0)
            {
                line1 = u.desc[0 .. nl];
                line2 = u.desc[nl + 1 .. $];
            }
            printCenteredAt(con, btnCol, btnRow + 1, BTN_W_COLS, line1, color);
            printCenteredAt(con, btnCol, btnRow + 2, BTN_W_COLS, line2, color);
            printCenteredAt(con, btnCol, btnRow + 3, BTN_W_COLS,
                            format("%d MP", u.costInMP), color);
        }
        else
        {
            printCenteredAt(con, btnCol, btnRow + 2, BTN_W_COLS, u.name, color);
        }
    }

    /// Print `text` horizontally centered inside a `widthCols`-wide span
    /// starting at `startCol`, on row `row`, in color `color`.
    static void printCenteredAt(TM_Console* con, int startCol, int row,
                                int widthCols, string text, int color)
    {
        int textLen = cast(int) text.length;
        int col = startCol + (widthCols - textLen) / 2;
        if (col < 0) col = 0;
        con.locate(col, row);
        con.fg(color);
        con.print(text);
    }

    void drawUpgradeText(TM_Console* con)
    {
        with (con)
        {
            // Title
            enum title = "UPGRADE";
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

            // Purchase toast — shows the last successful action on this
            // visit to the upgrade screen.
            if (upgradeToast.length > 0)
            {
                locate((CONSOLE_COLS - cast(int) upgradeToast.length) / 2, 9);
                fg(TM_colorGreen);
                print(upgradeToast);
            }

            // Buttons: name only when idle, description (rows 2-3) +
            // cost (row 4) when hovered. Description splits on '\n'.
            foreach (i; 0 .. UPGRADES.length)
                drawUpgradeButtonText(con, i);

            // Center "WARRIOR" base label — already taken.
            enum centerLabel = "WARRIOR";
            int cc, cr;
            centerTextInRect(TREE_CX - TREE_CENTER_W / 2,
                             TREE_CY - TREE_CENTER_H / 2,
                             TREE_CENTER_W, TREE_CENTER_H,
                             cast(int) centerLabel.length, cc, cr);
            locate(cc, cr);
            fg(TM_colorWhite);
            print(centerLabel);

            backButton().drawLabel(con);
        }
    }
}

