import 'package:vector_math/vector_math.dart';
import 'ability_types.dart';

/// Greenseer abilities — Druidic oracle-healers who see through nature's eyes.
///
/// Primary healer archetype channeling life force through green mana.
/// Focus on single-target heals, HoTs, AoE healing, and protective buffs.
/// 10 abilities using primarily Green mana with one dual-mana (Green + White).
class GreenseerAbilities {
  GreenseerAbilities._();

  /// Life Thread — Single-target heal with 1.5s cast time.
  /// Core healing spell for sustained throughput.
  static final lifeThread = AbilityData(
    name: 'Life Thread',
    description: 'Weave a thread of life force into an ally, restoring 35 HP over a 1.5 second cast',
    type: AbilityType.heal,
    cooldown: 4.0,
    range: 40.0,
    healAmount: 35.0,
    color: Vector3(0.3, 0.85, 0.4),
    impactColor: Vector3(0.4, 0.95, 0.5),
    impactSize: 0.8,
    castTime: 1.5,
    manaColor: ManaColor.green,
    manaCost: 15.0,
    category: 'greenseer',
  );

  /// Spirit Bloom — AoE heal for up to 5 allies within 6 yards.
  /// Burst AoE healing for grouped allies.
  static final spiritBloom = AbilityData(
    name: 'Spirit Bloom',
    description: 'Cause spirit flowers to bloom, healing up to 5 allies within 6 yards for 20 HP each',
    type: AbilityType.heal,
    cooldown: 12.0,
    healAmount: 20.0,
    color: Vector3(0.4, 0.9, 0.5),
    impactColor: Vector3(0.5, 1.0, 0.6),
    impactSize: 1.4,
    aoeRadius: 6.0,
    maxTargets: 5,
    manaColor: ManaColor.green,
    manaCost: 25.0,
    category: 'greenseer',
  );

  /// Verdant Embrace — HoT that heals 30 HP over 9 seconds.
  /// Efficient heal-over-time for sustained recovery.
  static final verdantEmbrace = AbilityData(
    name: 'Verdant Embrace',
    description: 'Embrace an ally with verdant energy that strengthens and heals 30 HP over 9 seconds',
    type: AbilityType.heal,
    cooldown: 8.0,
    healAmount: 30.0,
    color: Vector3(0.35, 0.8, 0.35),
    impactColor: Vector3(0.45, 0.9, 0.45),
    impactSize: 0.8,
    statusEffect: StatusEffect.regen,
    statusDuration: 9.0,
    dotTicks: 3,
    manaColor: ManaColor.green,
    manaCost: 20.0,
    category: 'greenseer',
  );

  /// Soul Shield — Absorb 80 damage on a target ally for 15 seconds.
  /// Powerful protective barrier for incoming burst damage.
  static final soulShield = AbilityData(
    name: 'Soul Shield',
    description: 'Conjure a luminous soul barrier on an ally that absorbs 80 damage for 15 seconds',
    type: AbilityType.buff,
    cooldown: 30.0,
    range: 40.0,
    color: Vector3(0.5, 0.9, 0.6),
    impactColor: Vector3(0.6, 1.0, 0.7),
    impactSize: 1.0,
    statusEffect: StatusEffect.shield,
    statusStrength: 80.0,
    statusDuration: 15.0,
    manaColor: ManaColor.green,
    manaCost: 35.0,
    category: 'greenseer',
  );

  /// Nature's Grace — Target receives +40% healing for 12 seconds.
  /// Amplify healing on a priority target before big heals.
  static final naturesGrace = AbilityData(
    name: "Nature's Grace",
    description: 'Bless an ally with nature\'s grace, increasing all healing received by 40% for 12 seconds',
    type: AbilityType.buff,
    cooldown: 10.0,
    range: 40.0,
    color: Vector3(0.45, 0.85, 0.5),
    impactColor: Vector3(0.55, 0.95, 0.6),
    impactSize: 0.8,
    statusEffect: StatusEffect.regen,
    statusStrength: 1.4,
    statusDuration: 12.0,
    manaColor: ManaColor.green,
    manaCost: 20.0,
    category: 'greenseer',
  );

  /// Ethereal Form — Transform into luminous spirit seer.
  /// +80% heal power, green mana regen broadcast to allies, cannot attack.
  /// Lasts 20 seconds.
  static final etherealForm = AbilityData(
    name: 'Ethereal Form',
    description: 'Transform into a luminous spirit seer — +80% healing power and broadcast green mana regen to nearby allies, but cannot attack for 20 seconds',
    type: AbilityType.summon,
    cooldown: 120.0,
    duration: 20.0,
    color: Vector3(0.5, 1.0, 0.6),
    impactColor: Vector3(0.6, 1.0, 0.7),
    impactSize: 1.5,
    statusEffect: StatusEffect.regen,
    statusStrength: 1.8,
    statusDuration: 20.0,
    manaColor: ManaColor.green,
    manaCost: 60.0,
    category: 'greenseer',
  );

  /// Cleansing Rain — Remove all debuffs from allies in 6 radius.
  /// Dual-mana (Green + White) purification effect.
  static final cleansingRain = AbilityData(
    name: 'Cleansing Rain',
    description: 'Call down a rain of purifying dew that cleanses all debuffs from allies within 6 yards',
    type: AbilityType.utility,
    cooldown: 15.0,
    color: Vector3(0.6, 0.95, 0.75),
    impactColor: Vector3(0.7, 1.0, 0.85),
    impactSize: 1.2,
    aoeRadius: 6.0,
    maxTargets: 5,
    manaColor: ManaColor.green,
    manaCost: 25.0,
    secondaryManaColor: ManaColor.white,
    secondaryManaCost: 10.0,
    category: 'greenseer',
  );

  /// Rejuvenating Roots — Place a healing zone: 80 HP total over 10 seconds.
  /// Persistent ground-targeted AoE heal.
  static final rejuvenatingRoots = AbilityData(
    name: 'Rejuvenating Roots',
    description: 'Summon roots at a location that pulse with healing energy, restoring 80 HP over 10 seconds to allies in the area',
    type: AbilityType.heal,
    cooldown: 6.0,
    duration: 10.0,
    healAmount: 80.0,
    color: Vector3(0.3, 0.7, 0.3),
    impactColor: Vector3(0.4, 0.8, 0.4),
    impactSize: 1.0,
    aoeRadius: 4.0,
    manaColor: ManaColor.green,
    manaCost: 15.0,
    category: 'greenseer',
  );

  /// Harmony — Link two allies: damage split 50/50 for 12 seconds.
  /// Protective bond that distributes incoming damage between targets.
  static final harmony = AbilityData(
    name: 'Harmony',
    description: 'Link two allies in harmony — damage taken by either is split equally between them for 12 seconds',
    type: AbilityType.buff,
    cooldown: 20.0,
    duration: 12.0,
    range: 40.0,
    color: Vector3(0.55, 0.9, 0.55),
    impactColor: Vector3(0.65, 1.0, 0.65),
    impactSize: 0.8,
    maxTargets: 2,
    manaColor: ManaColor.green,
    manaCost: 30.0,
    category: 'greenseer',
  );

  /// Awakening — Massive single-target heal (80 HP) with 2.0s cast.
  /// Emergency heal for critical situations.
  static final awakening = AbilityData(
    name: 'Awakening',
    description: 'Channel the full force of nature into a single ally, restoring 80 HP over a 2 second cast',
    type: AbilityType.heal,
    cooldown: 25.0,
    range: 40.0,
    healAmount: 80.0,
    color: Vector3(0.4, 1.0, 0.5),
    impactColor: Vector3(0.5, 1.0, 0.6),
    impactSize: 1.2,
    castTime: 2.0,
    manaColor: ManaColor.green,
    manaCost: 50.0,
    category: 'greenseer',
  );

  /// All greenseer abilities as a list
  static List<AbilityData> get all => [
    lifeThread,
    spiritBloom,
    verdantEmbrace,
    soulShield,
    naturesGrace,
    etherealForm,
    cleansingRain,
    rejuvenatingRoots,
    harmony,
    awakening,
  ];
}
