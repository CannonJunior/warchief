import 'package:vector_math/vector_math.dart';
import 'ability_types.dart';

/// Stormheart abilities — Lightning warriors harnessing storm fury.
///
/// Fast combos with burst damage playstyle: chain lightning strikes,
/// stuns, and storm transformations. 10 abilities using White mana
/// with several dual-mana (White + Red) combos for heavy burst.
class StormheartAbilities {
  StormheartAbilities._();

  /// Thunder Strike — Lightning-charged melee with bonus damage to stunned.
  /// Dual-mana (White + Red) for electrified close-range assault.
  static final thunderStrike = AbilityData(
    name: 'Thunder Strike',
    description: 'Strike with lightning-charged fists, dealing bonus damage to stunned targets',
    type: AbilityType.melee,
    damage: 25.0,
    cooldown: 5.0,
    range: 3.0,
    color: Vector3(0.7, 0.8, 1.0),
    impactColor: Vector3(0.9, 0.95, 1.0),
    impactSize: 0.6,
    windupTime: 0.3,
    windupMovementSpeed: 0.6,
    manaColor: ManaColor.white,
    manaCost: 15.0,
    secondaryManaColor: ManaColor.red,
    secondaryManaCost: 10.0,
    category: 'stormheart',
    damageSchool: DamageSchool.lightning,
  );

  /// Storm Bolt — Lightning projectile that chains to 2 nearby enemies.
  /// Fast-moving bolt with chain lightning effect.
  static final stormBolt = AbilityData(
    name: 'Storm Bolt',
    description: 'Hurl a bolt of lightning that chains to up to 2 nearby enemies on impact',
    type: AbilityType.ranged,
    damage: 20.0,
    cooldown: 7.0,
    range: 35.0,
    color: Vector3(0.6, 0.7, 1.0),
    impactColor: Vector3(0.8, 0.85, 1.0),
    impactSize: 0.5,
    projectileSpeed: 20.0,
    projectileSize: 0.25,
    maxTargets: 3,
    manaColor: ManaColor.white,
    manaCost: 20.0,
    category: 'stormheart',
    damageSchool: DamageSchool.lightning,
  );

  /// Tempest Fury — +40% attack speed buff for 8 seconds.
  /// Channel storm energy to accelerate combat rhythm.
  static final tempestFury = AbilityData(
    name: 'Tempest Fury',
    description: 'Channel the fury of the tempest, increasing attack speed by 40% for 8 seconds',
    type: AbilityType.buff,
    cooldown: 10.0,
    color: Vector3(0.75, 0.85, 1.0),
    impactColor: Vector3(0.85, 0.9, 1.0),
    impactSize: 1.0,
    statusEffect: StatusEffect.haste,
    statusStrength: 1.4,
    statusDuration: 8.0,
    manaColor: ManaColor.white,
    manaCost: 15.0,
    category: 'stormheart',
    damageSchool: DamageSchool.lightning,
  );

  /// Eye of the Storm — 4s damage immunity + AoE slow around caster.
  /// Dual-mana (White + Red) defensive ultimate with crowd control.
  static final eyeOfTheStorm = AbilityData(
    name: 'Eye of the Storm',
    description: 'Become the calm center of a raging storm — immune to damage for 4 seconds while slowing nearby enemies',
    type: AbilityType.buff,
    cooldown: 35.0,
    duration: 4.0,
    color: Vector3(0.9, 0.92, 1.0),
    impactColor: Vector3(0.95, 0.97, 1.0),
    impactSize: 1.3,
    statusEffect: StatusEffect.shield,
    statusStrength: 999.0,
    statusDuration: 4.0,
    aoeRadius: 6.0,
    manaColor: ManaColor.white,
    manaCost: 30.0,
    secondaryManaColor: ManaColor.red,
    secondaryManaCost: 15.0,
    category: 'stormheart',
    damageSchool: DamageSchool.lightning,
  );

  /// Blood Thunder — AoE lightning burst with stun.
  /// Dual-mana (Red + White) for devastating area stun.
  static final bloodThunder = AbilityData(
    name: 'Blood Thunder',
    description: 'Unleash a thunderous burst of blood-lightning, dealing 40 damage and stunning enemies for 2 seconds',
    type: AbilityType.aoe,
    damage: 40.0,
    cooldown: 18.0,
    color: Vector3(0.6, 0.4, 0.9),
    impactColor: Vector3(0.7, 0.5, 1.0),
    impactSize: 1.2,
    aoeRadius: 5.0,
    statusEffect: StatusEffect.stun,
    statusDuration: 2.0,
    manaColor: ManaColor.red,
    manaCost: 25.0,
    secondaryManaColor: ManaColor.white,
    secondaryManaCost: 15.0,
    category: 'stormheart',
    damageSchool: DamageSchool.lightning,
  );

  /// Avatar of Storms — Transform into a storm elemental.
  /// Dual-mana (White + Red) ultimate: lightning aura, +40% damage,
  /// immune to slow/root for 20 seconds.
  static final avatarOfStorms = AbilityData(
    name: 'Avatar of Storms',
    description: 'Become a living storm — lightning aura damages nearby foes, +40% damage, immune to slow and root for 20 seconds',
    type: AbilityType.summon,
    damage: 5.0,
    cooldown: 120.0,
    duration: 20.0,
    color: Vector3(0.5, 0.6, 1.0),
    impactColor: Vector3(0.7, 0.75, 1.0),
    impactSize: 1.5,
    statusEffect: StatusEffect.strength,
    statusStrength: 1.4,
    statusDuration: 20.0,
    manaColor: ManaColor.white,
    manaCost: 50.0,
    secondaryManaColor: ManaColor.red,
    secondaryManaCost: 30.0,
    category: 'stormheart',
    damageSchool: DamageSchool.lightning,
  );

  /// Lightning Dash — Short-range teleport leaving a lightning trail.
  /// Quick repositioning tool that deals damage where you pass.
  static final lightningDash = AbilityData(
    name: 'Lightning Dash',
    description: 'Blink forward in a flash of lightning, leaving a damaging trail behind',
    type: AbilityType.utility,
    damage: 10.0,
    cooldown: 6.0,
    range: 8.0,
    color: Vector3(0.85, 0.9, 1.0),
    impactColor: Vector3(0.9, 0.95, 1.0),
    impactSize: 0.5,
    manaColor: ManaColor.white,
    manaCost: 10.0,
    category: 'stormheart',
    damageSchool: DamageSchool.lightning,
  );

  /// Static Charge — Mark an enemy so the next 3 hits deal +50% damage.
  /// Debuff that amplifies follow-up burst from allies or self.
  static final staticCharge = AbilityData(
    name: 'Static Charge',
    description: 'Mark an enemy with static electricity — the next 3 hits against them deal +50% bonus damage',
    type: AbilityType.debuff,
    cooldown: 8.0,
    range: 30.0,
    color: Vector3(0.7, 0.75, 1.0),
    impactColor: Vector3(0.8, 0.85, 1.0),
    impactSize: 0.6,
    statusEffect: StatusEffect.weakness,
    statusStrength: 0.5,
    statusDuration: 10.0,
    manaColor: ManaColor.white,
    manaCost: 15.0,
    category: 'stormheart',
    damageSchool: DamageSchool.lightning,
  );

  /// Thunderclap — Melee AoE stun with lightning damage.
  /// Dual-mana (Red + White) for close-range crowd control burst.
  static final thunderclap = AbilityData(
    name: 'Thunderclap',
    description: 'Slam the ground with thunder force, dealing 30 damage and stunning enemies within 4 yards for 3 seconds',
    type: AbilityType.aoe,
    damage: 30.0,
    cooldown: 15.0,
    color: Vector3(0.65, 0.5, 0.95),
    impactColor: Vector3(0.75, 0.6, 1.0),
    impactSize: 1.0,
    aoeRadius: 4.0,
    statusEffect: StatusEffect.stun,
    statusDuration: 3.0,
    manaColor: ManaColor.red,
    manaCost: 20.0,
    secondaryManaColor: ManaColor.white,
    secondaryManaCost: 10.0,
    category: 'stormheart',
    damageSchool: DamageSchool.lightning,
  );

  /// Conduit — Channel lightning to a target: 8 dps for 5 seconds.
  /// Dual-mana (White + Red) sustained damage, self-rooted while channeling.
  static final conduit = AbilityData(
    name: 'Conduit',
    description: 'Channel a continuous stream of lightning into a target, dealing 40 damage over 5 seconds — you cannot move while channeling',
    type: AbilityType.channeled,
    damage: 40.0,
    cooldown: 20.0,
    duration: 5.0,
    range: 25.0,
    color: Vector3(0.55, 0.65, 1.0),
    impactColor: Vector3(0.7, 0.78, 1.0),
    impactSize: 0.6,
    castTime: 5.0,
    requiresStationary: true,
    channelEffect: ChannelEffect.conduit,
    manaColor: ManaColor.white,
    manaCost: 25.0,
    secondaryManaColor: ManaColor.red,
    secondaryManaCost: 15.0,
    category: 'stormheart',
    damageSchool: DamageSchool.lightning,
  );

  // ==================== MELEE COMBO ABILITIES ====================
  // Combo: Spark Jab -> Chain Shock -> Storm Surge -> Thundergod Fist

  /// Spark Jab — Lightning-fast jab, combo starter
  static final sparkJab = AbilityData(
    name: 'Spark Jab',
    description: 'Lightning-quick electrified jab — fast combo opener',
    type: AbilityType.melee,
    damage: 14.0,
    cooldown: 2.5,
    range: 2.0,
    color: Vector3(0.75, 0.85, 1.0),
    impactColor: Vector3(0.85, 0.9, 1.0),
    impactSize: 0.4,
    manaColor: ManaColor.white,
    manaCost: 8.0,
    category: 'stormheart',
    damageSchool: DamageSchool.lightning,
  );

  /// Chain Shock — Chain punch with brief stun
  static final chainShock = AbilityData(
    name: 'Chain Shock',
    description: 'Rapid chain punches charged with lightning, briefly stunning the target',
    type: AbilityType.melee,
    damage: 18.0,
    cooldown: 4.0,
    range: 3.0,
    color: Vector3(0.7, 0.8, 1.0),
    impactColor: Vector3(0.8, 0.88, 1.0),
    impactSize: 0.5,
    statusEffect: StatusEffect.stun,
    statusDuration: 0.5,
    manaColor: ManaColor.white,
    manaCost: 12.0,
    category: 'stormheart',
    damageSchool: DamageSchool.lightning,
  );

  /// Storm Surge — Lightning dash-punch gap-closer
  static final stormSurge = AbilityData(
    name: 'Storm Surge',
    description: 'Surge forward in a burst of lightning to close the gap',
    type: AbilityType.melee,
    damage: 22.0,
    cooldown: 6.0,
    range: 6.0,
    color: Vector3(0.6, 0.75, 1.0),
    impactColor: Vector3(0.7, 0.82, 1.0),
    impactSize: 0.5,
    manaColor: ManaColor.white,
    manaCost: 15.0,
    category: 'stormheart',
    damageSchool: DamageSchool.lightning,
  );

  /// Thundergod Fist — Dual-mana finisher with windup, stun, and knockback
  static final thundergodFist = AbilityData(
    name: 'Thundergod Fist',
    description: 'Channel the fury of the storm into a devastating fist strike',
    type: AbilityType.melee,
    damage: 40.0,
    cooldown: 10.0,
    range: 2.5,
    color: Vector3(0.5, 0.6, 1.0),
    impactColor: Vector3(0.7, 0.75, 1.0),
    impactSize: 0.9,
    statusEffect: StatusEffect.stun,
    statusDuration: 1.0,
    knockbackForce: 2.5,
    windupTime: 0.7,
    windupMovementSpeed: 0.3,
    manaColor: ManaColor.white,
    manaCost: 20.0,
    secondaryManaColor: ManaColor.red,
    secondaryManaCost: 12.0,
    category: 'stormheart',
    damageSchool: DamageSchool.lightning,
  );

  /// Basic no-mana melee: lightning jab
  static final voltStrike = AbilityData(
    name: 'Volt Strike',
    description: 'A quick, manaless lightning-infused strike.',
    type: AbilityType.melee,
    damage: 13.0,
    cooldown: 1.0,
    range: 2.0,
    color: Vector3(1.0, 1.0, 0.3),
    impactColor: Vector3(1.0, 1.0, 0.5),
    impactSize: 0.4,
    category: 'stormheart',
    damageSchool: DamageSchool.lightning,
  );

  /// Basic no-mana melee: arc punch
  static final arcPunch = AbilityData(
    name: 'Arc Punch',
    description: 'A crackling electrical punch.',
    type: AbilityType.melee,
    damage: 15.0,
    cooldown: 1.0,
    range: 2.5,
    color: Vector3(0.9, 0.9, 0.2),
    impactColor: Vector3(1.0, 1.0, 0.4),
    impactSize: 0.5,
    category: 'stormheart',
    damageSchool: DamageSchool.lightning,
  );

  /// Medium-cooldown permanent lightning vulnerability
  static final lightningBrand = AbilityData(
    name: 'Lightning Brand',
    description: 'A searing lightning strike that permanently exposes the target to electrical damage.',
    type: AbilityType.melee,
    damage: 10.0,
    cooldown: 12.0,
    range: 2.5,
    color: Vector3(1.0, 1.0, 0.0),
    impactColor: Vector3(1.0, 1.0, 0.3),
    impactSize: 0.6,
    category: 'stormheart',
    damageSchool: DamageSchool.lightning,
    appliesPermanentVulnerability: true,
  );

  // ==================== CHAIN COMBO PRIMER ====================

  /// Thunderstorm Strike — Activates chain-combo mode for stormhearts.
  /// Land 7 consecutive stormheart strikes within 7 seconds to fire the chain combo.
  static final thunderstormStrike = AbilityData(
    name: 'Thunderstorm Strike',
    description: 'Channel storm fury through your fists — activate chain-combo mode. '
        'Land 7 stormheart hits within 7 seconds to trigger a devastating lightning AoE burst.',
    type: AbilityType.melee,
    damage: 22.0,
    cooldown: 10.0,
    range: 2.5,
    color: Vector3(0.65, 0.78, 1.0),
    impactColor: Vector3(0.8, 0.9, 1.0),
    impactSize: 0.65,
    manaColor: ManaColor.white,
    manaCost: 15.0,
    secondaryManaColor: ManaColor.red,
    secondaryManaCost: 10.0,
    damageSchool: DamageSchool.lightning,
    category: 'stormheart',
    enablesComboChain: true,
  );

  /// All stormheart abilities as a list
  static List<AbilityData> get all => [
    thunderStrike,
    stormBolt,
    tempestFury,
    eyeOfTheStorm,
    bloodThunder,
    avatarOfStorms,
    lightningDash,
    staticCharge,
    thunderclap,
    conduit,
    sparkJab,
    chainShock,
    stormSurge,
    thundergodFist,
    voltStrike,
    arcPunch,
    lightningBrand,
    thunderstormStrike,
  ];
}
