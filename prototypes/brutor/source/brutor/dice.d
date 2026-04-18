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
    straight,     // 1-2-3-4-5 or 2-3-4-5-6 - no damage, +1 Tech point
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

    /// Roll all un-kept, non-frozen dice. `frozen` lets the caller pin
    /// specific indices in place (e.g., leg-debuff rerolls).
    void roll(in bool[NUM_DICE] frozen = [false, false, false, false, false])
    {
        foreach (i; 0 .. NUM_DICE)
        {
            if (!kept[i] && !frozen[i])
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
    /// A full house returns TWO combos (threeOfAKind + pair). A straight
    /// (1-2-3-4-5 or 2-3-4-5-6) returns a single straight combo.
    Combo[] analyze()
    {
        // Count occurrences of each face value
        int[7] counts = 0; // index 0 unused, 1-6 for dice faces
        foreach (v; values)
            counts[v]++;

        // Straight detection: five distinct consecutive values.
        bool lowStraight  = counts[1] == 1 && counts[2] == 1 && counts[3] == 1 &&
                            counts[4] == 1 && counts[5] == 1;
        bool highStraight = counts[2] == 1 && counts[3] == 1 && counts[4] == 1 &&
                            counts[5] == 1 && counts[6] == 1;
        if (lowStraight || highStraight)
        {
            // No body part target — use a placeholder; consumers ignore it.
            return [Combo(ComboType.straight, BodyPart.leftLeg)];
        }

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
