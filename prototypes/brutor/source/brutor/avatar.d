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
