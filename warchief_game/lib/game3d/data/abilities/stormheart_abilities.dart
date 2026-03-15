import 'package:vector_math/vector_math.dart';
import 'ability_types.dart';

/// Stormheart abilities — Lightning warriors harnessing storm fury.
///
/// Combo chain: Volt Strike → Arc Punch → Chain Shock → Storm Surge → Thundergod Fist.
/// Fast combos with burst damage playstyle using White and dual White/Red mana.
class StormheartAbilities {
  StormheartAbilities._();

  /// Thunder Strike — Lightning-charged melee with bonus damage to stunned.
  static final thunderStrike = AbilityData(
    name: 'Thunder Strike',
    description: 'Strike with lightning-charged fists, dealing bonus damage to stunned targets.',
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
    comboPrimes: ['Chain Shock', 'Thundergod Fist'],
  );

  /// Storm Bolt — Lightning projectile that chains to 2 nearby enemies.
  static final stormBolt = AbilityData(
    name: 'Storm Bolt',
    description: 'Hurl a bolt of lightning that chains to up to 2 nearby enemies on impact.',
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
    comboPrimes: ['Chain Shock', 'Thunder Strike'],
  );

  /// Tempest Fury — +40% attack speed buff for 8 seconds.
  static final tempestFury = AbilityData(
    name: 'Tempest Fury',
    description: 'Channel the fury of the tempest, increasing attack speed by 40% for 8 seconds.',
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
    comboPrimes: ['Thunder Strike', 'Thundergod Fist'],
  );

  /// Eye of the Storm — 4s damage immunity + AoE slow.
  static final eyeOfTheStorm = AbilityData(
    name: 'Eye of the Storm',
    description: 'Become the calm center of a raging storm — immune to damage for 4 seconds while slowing nearby enemies.',
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
    comboPrimes: ['Arc Punch', 'Volt Strike'],
  );

  /// Blood Thunder — AoE lightning burst with stun.
  static final bloodThunder = AbilityData(
    name: 'Blood Thunder',
    description: 'Unleash a thunderous burst of blood-lightning, dealing 40 damage and stunning enemies for 2 seconds.',
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
    comboPrimes: ['Thunder Strike', 'Thundergod Fist'],
  );

  /// Avatar of Storms — Transform into a storm elemental for 20 seconds.
  static final avatarOfStorms = AbilityData(
    name: 'Avatar of Storms',
    description: 'Become a living storm — lightning aura damages nearby foes, +40% damage, immune to slow and root for 20 seconds.',
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
    comboPrimes: ['Thunder Strike', 'Thundergod Fist'],
  );

  /// Lightning Dash — Short-range teleport leaving a lightning trail.
  static final lightningDash = AbilityData(
    name: 'Lightning Dash',
    description: 'Blink forward in a flash of lightning, leaving a damaging trail behind.',
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
    comboPrimes: ['Volt Strike', 'Arc Punch'],
  );

  /// Static Charge — Mark target: next 3 hits deal +50% damage.
  static final staticCharge = AbilityData(
    name: 'Static Charge',
    description: 'Mark an enemy with static electricity — the next 3 hits against them deal +50% bonus damage.',
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
    comboPrimes: ['Thunder Strike', 'Thundergod Fist'],
  );

  /// Thunderclap — Melee AoE stun with lightning damage.
  static final thunderclap = AbilityData(
    name: 'Thunderclap',
    description: 'Slam the ground with thunder force, dealing 30 damage and stunning enemies within 4 yards for 3 seconds.',
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
    comboPrimes: ['Thunder Strike', 'Volt Strike'],
  );

  /// Conduit — Channel lightning to target: 40 damage over 5 seconds.
  static final conduit = AbilityData(
    name: 'Conduit',
    description: 'Channel a continuous stream of lightning into a target, dealing 40 damage over 5 seconds — you cannot move while channeling.',
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

  // ==================== MELEE COMBO CHAIN ====================
  // Volt Strike → Arc Punch → Chain Shock → Storm Surge → Thundergod Fist

  /// Chain Shock — Chain punch with brief stun.
  static final chainShock = AbilityData(
    name: 'Chain Shock',
    description: 'Rapid chain punches charged with lightning, briefly stunning the target.',
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
    comboPrimes: ['Thundergod Fist', 'Storm Surge'],
  );

  /// Storm Surge — Lightning dash-punch gap-closer.
  static final stormSurge = AbilityData(
    name: 'Storm Surge',
    description: 'Surge forward in a burst of lightning to close the gap.',
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
    comboPrimes: ['Thundergod Fist', 'Thunder Strike'],
  );

  /// Thundergod Fist — Dual-mana finisher with windup, stun, and knockback.
  static final thundergodFist = AbilityData(
    name: 'Thundergod Fist',
    description: 'Channel the fury of the storm into a devastating fist strike.',
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
    comboPrimes: ['Blood Thunder', 'Thunderclap'],
  );

  /// Volt Strike — Free lightning-infused strike, combo starter.
  static final voltStrike = AbilityData(
    name: 'Volt Strike',
    description: 'A quick, manaless lightning-infused strike. Opens the Stormheart combo chain.',
    type: AbilityType.melee,
    damage: 13.0,
    cooldown: 1.0,
    range: 2.0,
    color: Vector3(1.0, 1.0, 0.3),
    impactColor: Vector3(1.0, 1.0, 0.5),
    impactSize: 0.4,
    category: 'stormheart',
    damageSchool: DamageSchool.lightning,
    comboPrimes: ['Chain Shock', 'Arc Punch'],
  );

  /// Arc Punch — Crackling electrical punch.
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
    comboPrimes: ['Storm Surge', 'Chain Shock'],
  );

  /// Lightning Brand — Permanent lightning vulnerability.
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
    comboPrimes: ['Thunder Strike', 'Thundergod Fist'],
  );

  // ==================== CHAIN COMBO PRIMER ====================

  /// Thunderstorm Strike — Activates chain-combo mode.
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
    comboPrimes: ['Volt Strike', 'Chain Shock'],
  );

  /// Static Discharge — Interrupts spellcasting for 3s.
  static final staticDischarge = AbilityData(
    name: 'Static Discharge',
    description: 'Release a burst of focused static electricity, interrupting the target\'s spellcasting for 3 seconds.',
    type: AbilityType.melee,
    damage: 14.0,
    cooldown: 12.0,
    range: 2.5,
    color: Vector3(0.7, 0.85, 1.0),
    impactColor: Vector3(0.9, 0.95, 1.0),
    impactSize: 0.5,
    statusEffect: StatusEffect.interrupt,
    statusDuration: 3.0,
    manaColor: ManaColor.white,
    manaCost: 12.0,
    category: 'stormheart',
    damageSchool: DamageSchool.lightning,
    comboPrimes: ['Thundergod Fist', 'Thunder Strike'],
  );

  /// Storm Hardened — Self-buff granting health regeneration.
  static final stormHardened = AbilityData(
    name: 'Storm Hardened',
    description: 'Temper yourself against the storm, gaining sustained health regeneration.',
    type: AbilityType.buff,
    cooldown: 5.0,
    duration: 3600.0,
    color: Vector3(0.6, 0.7, 1.0),
    impactColor: Vector3(0.7, 0.8, 1.0),
    impactSize: 1.2,
    statusEffect: StatusEffect.regen,
    statusStrength: 3.0,
    manaColor: ManaColor.white,
    manaCost: 25.0,
    category: 'stormheart',
  );

  /// All stormheart abilities as a list.
  /// Ordered short→long cooldown; slots 11-15 hold the longest cooldowns.
  /// Cut: thunderStrike, thunderclap, conduit, lightningBrand (redundant/overlapping).
  static List<AbilityData> get all => [
    voltStrike,          //  1  1.0s  free basic, combo starter
    arcPunch,            //  2  1.0s  free basic, combo 2
    chainShock,          //  3  4.0s  combo 3, brief stun
    stormHardened,       //  4  5.0s  regen aura
    stormSurge,          //  5  6.0s  combo 4, gap closer
    lightningDash,       //  6  6.0s  blink mobility
    stormBolt,           //  7  7.0s  ranged chain lightning
    staticCharge,        //  8  8.0s  debuff amplifier
    tempestFury,         //  9 10.0s  attack speed buff
    thundergodFist,      // 10 10.0s  combo finisher, stun + knockback
    thunderstormStrike,  // 11 10.0s  chain combo primer
    staticDischarge,     // 12 12.0s  interrupt
    bloodThunder,        // 13 18.0s  CC AoE stun
    eyeOfTheStorm,       // 14 35.0s  damage immunity buff
    avatarOfStorms,      // 15 120.0s ultimate transform
  ];
}
