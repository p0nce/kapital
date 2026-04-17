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
            fg(TM_colorYellow);
            if (activePlayer == 0)
                fg(TM_colorYellow);
            else
                fg(TM_colorWhite);
            print("PLAYER 1");

            locate(45, 1);
            if (activePlayer == 1)
                fg(TM_colorYellow);
            else
                fg(TM_colorWhite);
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
