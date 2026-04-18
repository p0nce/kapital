module brutor.combat;

import brutor.dice;
import brutor.avatar;
import turtle;
import std.format : format;

/// A single damage action to apply to an avatar
struct DamageAction
{
    enum Type
    {
        flatDamage,  // subtract amount from HP
    }

    Type type;
    BodyPart target;
    int amount;
}

/// Human-readable body part names (used in previews).
string bodyPartName(BodyPart part)
{
    final switch (part)
    {
        case BodyPart.leftLeg:  return "Left Leg";
        case BodyPart.rightLeg: return "Right Leg";
        case BodyPart.leftArm:  return "Left Arm";
        case BodyPart.rightArm: return "Right Arm";
        case BodyPart.chest:    return "Chest";
        case BodyPart.head:     return "Head";
    }
}

/// True when the combos describe a straight (1-2-3-4-5 or 2-3-4-5-6).
/// A straight deals no damage — it awards one Tech point instead.
bool isStraight(Combo[] combos)
{
    return combos.length == 1 && combos[0].type == ComboType.straight;
}

/// True when the combos describe a full house: one three-of-a-kind plus
/// one pair, exactly. Callers use this to apply bespoke damage (3 + 2).
bool isFullHouse(Combo[] combos)
{
    if (combos.length != 2)
        return false;
    return (combos[0].type == ComboType.threeOfAKind && combos[1].type == ComboType.pair)
        || (combos[0].type == ComboType.pair && combos[1].type == ComboType.threeOfAKind);
}

/// Combined description of what a turn's dice will do: the deterministic
/// damage actions (for the matched body parts) and the human-readable
/// preview lines.
struct DamageDescription
{
    DamageAction[] actions;
    string[] previewLines;
}

/// Single source of truth for combo → damage mapping and its description.
DamageDescription describeDamage(Combo[] combos)
{
    DamageDescription out_;

    // Straight: no damage, just a preview line. GameState raises a parry
    // wall on the active player when the turn resolves.
    if (isStraight(combos))
    {
        out_.previewLines ~= "Straight \u2192 Parry (block opponent's next turn).";
        return out_;
    }

    // Full house is resolved by GameState (needs opponent HP to count
    // how many of the two targeted parts are still alive). No damage is
    // emitted here — GameState adds its own preview line.
    if (isFullHouse(combos))
        return out_;

    foreach (combo; combos)
    {
        int face = cast(int) combo.target + 1;
        string bp = bodyPartName(combo.target);

        final switch (combo.type)
        {
            case ComboType.single:
            case ComboType.straight:
                // Handled elsewhere (straight is detected above).
                break;

            case ComboType.pair:
                out_.actions ~= DamageAction(DamageAction.Type.flatDamage, combo.target, 1);
                out_.previewLines ~= format("Pair of %d \u2192 1 damage to %s.", face, bp);
                break;

            case ComboType.threeOfAKind:
                out_.actions ~= DamageAction(DamageAction.Type.flatDamage, combo.target, 2);
                out_.previewLines ~= format("Three of a kind of %d \u2192 2 damage to %s.", face, bp);
                break;

            case ComboType.fourOfAKind:
                out_.actions ~= DamageAction(DamageAction.Type.flatDamage, combo.target, 3);
                out_.previewLines ~= format("Four of a kind of %d \u2192 3 damage to %s.", face, bp);
                break;

            case ComboType.yahtzee:
                out_.actions ~= DamageAction(DamageAction.Type.flatDamage, combo.target, 5);
                out_.previewLines ~= format("Yahtzee of %d \u2192 5 damage to %s.", face, bp);
                break;
        }
    }

    return out_;
}

/// Resolve dice combos into damage actions that will actually be applied.
DamageAction[] resolveDamage(Combo[] combos)
{
    return describeDamage(combos).actions;
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
        }
    }
}
