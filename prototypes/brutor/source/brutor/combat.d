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
