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

    /// Is this avatar still alive? An avatar loses when 3 or fewer body
    /// parts remain alive — i.e., they stay in the fight while more than
    /// 3 parts still have HP.
    bool isAlive()
    {
        int alive = 0;
        foreach (h; hp)
            if (h > 0) alive++;
        return alive > 3;
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
    /// cx, cy is the center of the chest area. s is a scale factor.
    /// `flash` marks body parts that should flash (damage animation);
    /// when `flashOn` is true, those parts render in bright white.
    /// `helmetLevel` draws a helmet when > 0. Level 2 (reinforced) renders
    /// a brighter dome plus a crest ridge to distinguish it from level 1.
    /// `hasShield` adds a heater shield wielded by the left arm.
    void draw(Canvas* c, float cx, float cy, float s = 1.0f,
              in bool[NUM_BODY_PARTS] flash = [false, false, false, false, false, false],
              bool flashOn = false,
              int helmetLevel = 0,
              bool hasShield = false)
    {
        float headRadius = 18.0f * s;
        float chestW = 40.0f * s;
        float chestH = 50.0f * s;
        float armW = 12.0f * s;
        float armH = 45.0f * s;
        float legW = 14.0f * s;
        float legH = 50.0f * s;

        float chestTop = cy - chestH / 2;
        float chestBot = cy + chestH / 2;

        Color partColor(BodyPart p)
        {
            if (flash[p] && flashOn)
                return rgba(255, 255, 255, 255);
            return hpColor(hp[p]);
        }

        // Head (centered above chest)
        if (hp[BodyPart.head] > 0)
        {
            float headCy = chestTop - headRadius - 4;
            c.save();
            c.fillStyle = partColor(BodyPart.head);
            c.beginPath();
            c.arc(cx, headCy, headRadius, 0, 6.2832f);
            c.fill();
            c.restore();

            // Helmet: a metallic dome over the top half of the head plus a
            // brim extending slightly past the temples. Level 2 is drawn in
            // a brighter steel and sprouts a longitudinal crest.
            if (helmetLevel > 0)
            {
                float helmetR = headRadius * 1.08f;
                float brimW = headRadius * 2.5f;
                float brimH = 4.0f * s;
                float brimY = headCy - headRadius * 0.1f;

                Color domeCol = (helmetLevel >= 2)
                    ? rgba(150, 160, 185, 255)
                    : rgba(85, 90, 110, 255);
                Color brimCol = (helmetLevel >= 2)
                    ? rgba(95, 100, 120, 255)
                    : rgba(55, 60, 75, 255);

                // Dome (top semicircle).
                c.save();
                c.fillStyle = domeCol;
                c.beginPath();
                c.moveTo(cx - helmetR, headCy);
                c.arc(cx, headCy, helmetR, 3.1416f, 6.2832f);
                c.closePath();
                c.fill();
                c.restore();

                // Brim.
                c.save();
                c.fillStyle = brimCol;
                c.beginPath();
                c.moveTo(cx - brimW / 2, brimY);
                c.lineTo(cx + brimW / 2, brimY);
                c.lineTo(cx + brimW / 2, brimY + brimH);
                c.lineTo(cx - brimW / 2, brimY + brimH);
                c.closePath();
                c.fill();
                c.restore();

                // Reinforced crest: a thin ridge running along the top of
                // the dome front-to-back.
                if (helmetLevel >= 2)
                {
                    float crestW = 4.0f * s;
                    float crestH = helmetR + 3.0f * s;
                    c.save();
                    c.fillStyle = rgba(210, 215, 225, 255);
                    c.beginPath();
                    c.moveTo(cx - crestW / 2, headCy - crestH);
                    c.lineTo(cx + crestW / 2, headCy - crestH);
                    c.lineTo(cx + crestW / 2, headCy);
                    c.lineTo(cx - crestW / 2, headCy);
                    c.closePath();
                    c.fill();
                    c.restore();
                }
            }
        }

        // Chest
        if (hp[BodyPart.chest] > 0)
        {
            c.save();
            c.fillStyle = partColor(BodyPart.chest);
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
            c.fillStyle = partColor(BodyPart.leftArm);
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
            c.fillStyle = partColor(BodyPart.rightArm);
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

            // Sword held in the right hand
            float handCx = ax + armW / 2;
            float handCy = ay + armH;
            drawSword(c, handCx, handCy, s);
        }

        // Left leg
        if (hp[BodyPart.leftLeg] > 0)
        {
            c.save();
            c.fillStyle = partColor(BodyPart.leftLeg);
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
            c.fillStyle = partColor(BodyPart.rightLeg);
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

        // Shield — 30% oversized heater held by the left arm, nudged one
        // console cell to the right and drawn last so it sits on top of
        // every other body part. `hasShield` is self-gated: it clears the
        // moment the left arm is destroyed.
        if (hasShield)
        {
            float shieldW = 28.0f * s * 1.3f;
            float shieldH = 42.0f * s * 1.3f;
            float armLeftX = cx - chestW / 2 - armW;
            float sRight = armLeftX + armW * 0.4f + 12.0f; // +1 console col
            float sLeft = sRight - shieldW;
            float sTop = chestTop + armH * 0.05f;
            float sBot = sTop + shieldH;
            float sMidY = sTop + shieldH * 0.65f;
            float sCenterX = (sLeft + sRight) / 2;

            // Heater face (wood).
            c.save();
            c.fillStyle = rgba(120, 70, 50, 255);
            c.beginPath();
            c.moveTo(sLeft, sTop);
            c.lineTo(sRight, sTop);
            c.lineTo(sRight, sMidY);
            c.lineTo(sCenterX, sBot);
            c.lineTo(sLeft, sMidY);
            c.closePath();
            c.fill();
            c.restore();

            // Steel rim along the top edge.
            c.save();
            c.fillStyle = rgba(90, 90, 100, 255);
            float rimH = 5.0f * s;
            c.beginPath();
            c.moveTo(sLeft, sTop);
            c.lineTo(sRight, sTop);
            c.lineTo(sRight, sTop + rimH);
            c.lineTo(sLeft, sTop + rimH);
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

/// Draw a simple sword (handle + guard + blade) with pommel at (hx, hy).
/// The sword points down-and-outward to the right.
private void drawSword(Canvas* c, float hx, float hy, float s)
{
    float handleW = 5.0f * s;
    float handleH = 14.0f * s;
    float guardW  = 22.0f * s;
    float guardH  = 4.0f * s;
    float bladeW  = 6.0f * s;
    float bladeH  = 55.0f * s;

    // Handle (brown), below the hand
    c.save();
    c.fillStyle = rgba(110, 70, 30, 255);
    float handleX = hx - handleW / 2;
    float handleY = hy;
    c.beginPath();
    c.moveTo(handleX, handleY);
    c.lineTo(handleX + handleW, handleY);
    c.lineTo(handleX + handleW, handleY + handleH);
    c.lineTo(handleX, handleY + handleH);
    c.closePath();
    c.fill();
    c.restore();

    // Cross-guard (dark grey)
    c.save();
    c.fillStyle = rgba(80, 80, 90, 255);
    float guardX = hx - guardW / 2;
    float guardY = handleY + handleH;
    c.beginPath();
    c.moveTo(guardX, guardY);
    c.lineTo(guardX + guardW, guardY);
    c.lineTo(guardX + guardW, guardY + guardH);
    c.lineTo(guardX, guardY + guardH);
    c.closePath();
    c.fill();
    c.restore();

    // Blade (silver), extends downward from the guard
    c.save();
    c.fillStyle = rgba(200, 205, 215, 255);
    float bladeX = hx - bladeW / 2;
    float bladeY = guardY + guardH;
    c.beginPath();
    c.moveTo(bladeX, bladeY);
    c.lineTo(bladeX + bladeW, bladeY);
    // Pointed tip
    c.lineTo(bladeX + bladeW / 2, bladeY + bladeH);
    c.closePath();
    c.fill();
    c.restore();
}

/// Returns a color based on current HP:
/// 5 (full) = light grey, 4 = grey, 3 = red, 2 = darker red, 1 = darkest red.
private Color hpColor(int currentHP)
{
    switch (currentHP)
    {
        case 5:  return rgba(200, 200, 210, 255); // light grey
        case 4:  return rgba(120, 120, 130, 255); // grey
        case 3:  return rgba(200,  45,  55, 255); // red
        case 2:  return rgba(140,  30,  40, 255); // darker red
        case 1:  return rgba( 90,  20,  25, 255); // darkest red
        default: return rgba( 40,  10,  15, 255); // (not normally drawn)
    }
}
