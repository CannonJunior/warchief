import 'package:vector_math/vector_math.dart';
import 'ability_types.dart';

/// Wind Walker abilities — White Mana martial arts with juggling combos.
///
/// Juggle chain: Dragon Ascent (launcher) → Aerial Pursuit → Tempest Crash (ground slam).
/// All abilities use White Mana and belong to the 'windwalker' category.
class WindWalkerAbilities {
  WindWalkerAbilities._();

  // ==================== MOVEMENT ABILITIES ====================

  /// Gale Step — Forward dash dealing damage along path.
  static final galeStep = AbilityData(
    name: 'Gale Step',
    description: 'Dash forward through enemies, dealing damage along the path.',
    type: AbilityType.melee,
    damage: 30.0,
    cooldown: 4.0,
    duration: 0.3,
    range: 8.0,
    color: Vector3(0.9, 0.95, 1.0),
    impactColor: Vector3(0.85, 0.9, 1.0),
    impactSize: 0.5,
    manaColor: ManaColor.white,
    manaCost: 10.0,
    category: 'windwalker',
    comboPrimes: ['Swift Jab', 'Gale Punch'],
  );

  /// Zephyr Roll — Evasive roll granting brief invulnerability.
  static final zephyrRoll = AbilityData(
    name: 'Zephyr Roll',
    description: 'Evasive roll granting brief invulnerability.',
    type: AbilityType.buff,
    cooldown: 5.0,
    duration: 0.4,
    range: 4.0,
    color: Vector3(0.85, 0.9, 1.0),
    impactColor: Vector3(0.8, 0.85, 1.0),
    impactSize: 0.4,
    statusEffect: StatusEffect.shield,
    statusDuration: 0.4,
    manaColor: ManaColor.white,
    manaCost: 8.0,
    category: 'windwalker',
    comboPrimes: ['Swift Jab', 'Gale Punch'],
  );

  /// Flying Serpent Strike — Long-range piercing dash.
  static final flyingSerpentStrike = AbilityData(
    name: 'Flying Serpent Strike',
    description: 'Dash forward at low altitude, damaging all enemies in path.',
    type: AbilityType.melee,
    damage: 45.0,
    cooldown: 10.0,
    duration: 0.5,
    range: 12.0,
    color: Vector3(0.75, 0.85, 1.0),
    impactColor: Vector3(0.7, 0.8, 1.0),
    impactSize: 0.7,
    piercing: true,
    manaColor: ManaColor.white,
    manaCost: 20.0,
    category: 'windwalker',
    comboPrimes: ['Tempest Crash'],
  );

  /// Take Flight — Toggle flight mode.
  static final takeFlight = AbilityData(
    name: 'Take Flight',
    description: 'Toggle flight mode — soar through the skies consuming White Mana.',
    type: AbilityType.buff,
    cooldown: 1.0,
    duration: 0.0,
    color: Vector3(0.95, 0.97, 1.0),
    impactColor: Vector3(0.9, 0.95, 1.0),
    impactSize: 0.8,
    manaColor: ManaColor.white,
    manaCost: 15.0,
    category: 'windwalker',
  );

  // ==================== JUGGLE CHAIN ====================
  // Dragon Ascent → Aerial Pursuit → Tempest Crash

  /// Dragon Ascent — Rising dragon fist that launches the target airborne.
  /// Juggle launcher: stuns and sends the target up, enabling aerial follow-ups.
  static final dragonAscent = AbilityData(
    name: 'Dragon Ascent',
    description:
        'Launch skyward with a rising dragon fist, hurling the target airborne '
        'and stunning them. Sets up Aerial Pursuit for the juggle combo.',
    type: AbilityType.melee,
    damage: 28.0,
    cooldown: 8.0,
    range: 2.0,
    color: Vector3(0.85, 0.95, 1.0),
    impactColor: Vector3(1.0, 0.98, 0.8),
    impactSize: 0.8,
    statusEffect: StatusEffect.stun,
    statusDuration: 1.5,
    knockbackForce: 3.0,
    windupTime: 0.25,
    windupMovementSpeed: 0.5,
    manaColor: ManaColor.white,
    manaCost: 18.0,
    category: 'windwalker',
    damageSchool: DamageSchool.physical,
    comboPrimes: ['Aerial Pursuit', 'Flying Serpent Strike'],
  );

  /// Aerial Pursuit — Soar after the airborne target and strike mid-air.
  /// Best used immediately after Dragon Ascent.
  static final aerialPursuit = AbilityData(
    name: 'Aerial Pursuit',
    description:
        'Soar after the airborne target and strike in mid-air. '
        'Follow with Tempest Crash to complete the juggle finisher.',
    type: AbilityType.melee,
    damage: 35.0,
    cooldown: 10.0,
    range: 2.5,
    color: Vector3(0.78, 0.88, 1.0),
    impactColor: Vector3(0.9, 0.95, 1.0),
    impactSize: 0.75,
    manaColor: ManaColor.white,
    manaCost: 20.0,
    category: 'windwalker',
    damageSchool: DamageSchool.physical,
    comboPrimes: ['Tempest Crash'],
  );

  /// Tempest Crash — Slam the target into the ground with AoE impact.
  /// Juggle finisher: devastating if following Aerial Pursuit.
  static final tempestCrash = AbilityData(
    name: 'Tempest Crash',
    description:
        'Slam the target into the ground with devastating force, dealing AoE damage '
        'on impact and briefly stunning nearby enemies. The juggle finisher.',
    type: AbilityType.aoe,
    damage: 42.0,
    cooldown: 12.0,
    range: 2.0,
    color: Vector3(0.65, 0.78, 1.0),
    impactColor: Vector3(0.7, 0.82, 1.0),
    impactSize: 1.1,
    aoeRadius: 3.0,
    statusEffect: StatusEffect.stun,
    statusDuration: 0.8,
    windupTime: 0.3,
    windupMovementSpeed: 0.3,
    manaColor: ManaColor.white,
    manaCost: 25.0,
    category: 'windwalker',
    damageSchool: DamageSchool.physical,
    comboPrimes: ['Gale Step', 'Swift Jab'],
  );

  // ==================== NON-MOVEMENT ABILITIES ====================

  /// Cyclone Dive — AoE slam with stun.
  static final cycloneDive = AbilityData(
    name: 'Cyclone Dive',
    description: 'Leap upward then slam down, dealing AoE damage and stunning.',
    type: AbilityType.aoe,
    damage: 60.0,
    cooldown: 15.0,
    duration: 0.8,
    color: Vector3(0.7, 0.82, 1.0),
    impactColor: Vector3(0.6, 0.75, 1.0),
    impactSize: 1.2,
    aoeRadius: 3.0,
    statusEffect: StatusEffect.stun,
    statusDuration: 2.0,
    manaColor: ManaColor.white,
    manaCost: 25.0,
    category: 'windwalker',
    comboPrimes: ['Swift Jab', 'Stormfist Barrage'],
  );

  /// Wind Wall — Blocks projectiles for 4 seconds.
  static final windWall = AbilityData(
    name: 'Wind Wall',
    description: 'Summon a wall of wind that blocks incoming projectiles.',
    type: AbilityType.buff,
    cooldown: 20.0,
    duration: 4.0,
    color: Vector3(0.88, 0.92, 1.0),
    impactColor: Vector3(0.85, 0.9, 1.0),
    impactSize: 1.0,
    manaColor: ManaColor.white,
    manaCost: 20.0,
    category: 'windwalker',
  );

  /// Tempest Charge — Charge to target with knockback.
  static final tempestCharge = AbilityData(
    name: 'Tempest Charge',
    description: 'Charge to target with tempest force, knocking back enemies.',
    type: AbilityType.melee,
    damage: 35.0,
    cooldown: 8.0,
    duration: 0.4,
    range: 10.0,
    color: Vector3(0.78, 0.86, 1.0),
    impactColor: Vector3(0.7, 0.82, 1.0),
    impactSize: 0.7,
    knockbackForce: 4.0,
    manaColor: ManaColor.white,
    manaCost: 15.0,
    category: 'windwalker',
    comboPrimes: ['Dragon Ascent', 'Cyclone Kick'],
  );

  /// Healing Gale — Heal over time.
  static final healingGale = AbilityData(
    name: 'Healing Gale',
    description: 'Soothing winds restore health over time.',
    type: AbilityType.heal,
    cooldown: 18.0,
    duration: 4.0,
    healAmount: 40.0,
    color: Vector3(0.82, 0.95, 0.88),
    impactColor: Vector3(0.8, 0.95, 0.85),
    impactSize: 0.8,
    manaColor: ManaColor.white,
    manaCost: 22.0,
    category: 'windwalker',
  );

  /// Sovereign of the Sky — Enhanced flight speed + mana cost reduction.
  static final sovereignOfTheSky = AbilityData(
    name: 'Sovereign of the Sky',
    description: 'Become one with the wind — enhanced flight speed and reduced mana costs.',
    type: AbilityType.buff,
    cooldown: 90.0,
    duration: 12.0,
    color: Vector3(1.0, 0.97, 0.85),
    impactColor: Vector3(1.0, 0.95, 0.8),
    impactSize: 1.5,
    manaColor: ManaColor.white,
    manaCost: 40.0,
    category: 'windwalker',
    comboPrimes: ['Dragon Ascent', 'Swift Jab'],
  );

  /// Wind Warp — Dash forward; doubles flight speed if airborne.
  static final windWarp = AbilityData(
    name: 'Wind Warp',
    description: 'Warp through the wind — dash forward on ground, or double flight speed while airborne.',
    type: AbilityType.melee,
    cooldown: 10.0,
    duration: 0.3,
    range: 8.0,
    color: Vector3(0.85, 0.93, 1.0),
    impactColor: Vector3(0.8, 0.9, 1.0),
    impactSize: 0.5,
    manaColor: ManaColor.white,
    manaCost: 12.0,
    category: 'windwalker',
    comboPrimes: ['Dragon Ascent', 'Stormfist Barrage'],
  );

  // ==================== MELEE COMBO CHAIN ====================

  /// Zephyr Palm — Quick palm strike, combo opener.
  static final zephyrPalm = AbilityData(
    name: 'Zephyr Palm',
    description: 'Swift wind-charged palm strike — quick combo opener.',
    type: AbilityType.melee,
    damage: 14.0,
    cooldown: 2.5,
    range: 2.0,
    color: Vector3(0.9, 0.95, 1.0),
    impactColor: Vector3(0.85, 0.9, 1.0),
    impactSize: 0.4,
    manaColor: ManaColor.white,
    manaCost: 8.0,
    category: 'windwalker',
    comboPrimes: ['Dragon Ascent', 'Stormfist Barrage'],
  );

  /// Cyclone Kick — Spinning kick with knockback.
  static final cycloneKick = AbilityData(
    name: 'Cyclone Kick',
    description: 'Spinning wind-powered kick that knocks enemies away.',
    type: AbilityType.melee,
    damage: 22.0,
    cooldown: 5.0,
    range: 3.0,
    color: Vector3(0.8, 0.88, 1.0),
    impactColor: Vector3(0.75, 0.85, 1.0),
    impactSize: 0.6,
    knockbackForce: 2.5,
    manaColor: ManaColor.white,
    manaCost: 12.0,
    category: 'windwalker',
    comboPrimes: ['Dragon Ascent', 'Stormfist Barrage'],
  );

  /// Stormfist Barrage — Triple-punch finisher with stun.
  static final stormfistBarrage = AbilityData(
    name: 'Stormfist Barrage',
    description: 'Three-hit punch barrage that stuns on impact.',
    type: AbilityType.melee,
    damage: 30.0,
    cooldown: 7.0,
    range: 2.5,
    color: Vector3(0.7, 0.82, 1.0),
    impactColor: Vector3(0.65, 0.78, 1.0),
    impactSize: 0.7,
    statusEffect: StatusEffect.stun,
    statusDuration: 1.0,
    windupTime: 0.5,
    windupMovementSpeed: 0.4,
    manaColor: ManaColor.white,
    manaCost: 18.0,
    category: 'windwalker',
    comboPrimes: ['Flying Serpent Strike'],
  );

  // ==================== BASIC NO-MANA MELEE ====================

  /// Swift Jab — Quick manaless jab.
  static final swiftJab = AbilityData(
    name: 'Swift Jab',
    description: 'A quick, manaless jab.',
    type: AbilityType.melee,
    damage: 12.0,
    cooldown: 1.0,
    range: 2.0,
    color: Vector3(0.8, 0.9, 1.0),
    impactColor: Vector3(0.9, 1.0, 1.0),
    impactSize: 0.4,
    category: 'windwalker',
    comboPrimes: ['Gale Punch', 'Zephyr Palm'],
  );

  /// Gale Punch — Wind-enhanced punch.
  static final galePunch = AbilityData(
    name: 'Gale Punch',
    description: 'A forceful wind-enhanced punch.',
    type: AbilityType.melee,
    damage: 14.0,
    cooldown: 1.0,
    range: 2.5,
    color: Vector3(0.7, 0.9, 1.0),
    impactColor: Vector3(0.8, 1.0, 1.0),
    impactSize: 0.5,
    category: 'windwalker',
    comboPrimes: ['Cyclone Kick', 'Zephyr Palm'],
  );

  /// Pressure Point — Applies permanent physical vulnerability.
  static final pressurePoint = AbilityData(
    name: 'Pressure Point',
    description: 'A precise strike that permanently exposes the target\'s physical weakness.',
    type: AbilityType.melee,
    damage: 10.0,
    cooldown: 12.0,
    range: 2.5,
    color: Vector3(0.9, 0.8, 0.7),
    impactColor: Vector3(1.0, 0.9, 0.8),
    impactSize: 0.6,
    category: 'windwalker',
    appliesPermanentVulnerability: true,
    comboPrimes: ['Swift Jab', 'Gale Punch'],
  );

  // ==================== CHAIN COMBO PRIMER ====================

  /// Gale Fury — Activates chain-combo mode.
  static final galeFury = AbilityData(
    name: 'Gale Fury',
    description: 'Unleash the fury of the gale — activate chain-combo mode. '
        'Land 7 windwalker strikes within 7 seconds to trigger a haste surge.',
    type: AbilityType.melee,
    damage: 18.0,
    cooldown: 10.0,
    range: 2.0,
    color: Vector3(0.8, 0.92, 1.0),
    impactColor: Vector3(0.7, 0.85, 1.0),
    impactSize: 0.5,
    manaColor: ManaColor.white,
    manaCost: 15.0,
    category: 'windwalker',
    enablesComboChain: true,
    comboPrimes: ['Swift Jab', 'Dragon Ascent'],
  );

  /// Seal Palm — Interrupts target spellcasting for 3s.
  static final sealPalm = AbilityData(
    name: 'Seal Palm',
    description: 'A precise palm strike that interrupts the target\'s spellcasting for 3 seconds.',
    type: AbilityType.melee,
    damage: 11.0,
    cooldown: 8.0,
    range: 2.0,
    color: Vector3(0.85, 0.90, 1.0),
    impactColor: Vector3(0.95, 0.98, 1.0),
    impactSize: 0.4,
    statusEffect: StatusEffect.interrupt,
    statusDuration: 3.0,
    manaColor: ManaColor.white,
    manaCost: 8.0,
    category: 'windwalker',
    damageSchool: DamageSchool.physical,
    comboPrimes: ['Swift Jab', 'Zephyr Palm'],
  );

  /// Gale Stride — Aura granting haste to nearby allies.
  static final galeStride = AbilityData(
    name: 'Gale Stride',
    description: 'The windwalker becomes a living vortex of wind energy, '
        'granting all nearby allies the speed of gale-force winds.',
    type: AbilityType.buff,
    cooldown: 5.0,
    duration: 3600.0,
    color: Vector3(0.9, 0.95, 1.0),
    impactColor: Vector3(1.0, 1.0, 1.0),
    impactSize: 1.4,
    statusEffect: StatusEffect.haste,
    statusStrength: 0.20,
    manaColor: ManaColor.white,
    manaCost: 30.0,
    category: 'windwalker',
    isAura: true,
    auraRange: 10.0,
  );

  /// All Wind Walker abilities as a list.
  /// Ordered short→long cooldown; slots 11-15 hold the longest cooldowns.
  /// Cut: zephyrPalm, tempestCharge, healingGale, windWarp, stormfistBarrage,
  ///      pressurePoint, cycloneDive (redundant/overlapping).
  static List<AbilityData> get all => [
    swiftJab,            //  1  1.0s  free basic
    galePunch,           //  2  1.0s  free basic
    takeFlight,          //  3  1.0s  unique flight toggle
    galeStep,            //  4  4.0s  dash
    zephyrRoll,          //  5  5.0s  evasive buff
    cycloneKick,         //  6  5.0s  knockback kick
    galeStride,          //  7  5.0s  haste aura
    sealPalm,            //  8  8.0s  interrupt
    dragonAscent,        //  9  8.0s  CC stun + juggle launcher
    galeFury,            // 10 10.0s  chain combo primer
    aerialPursuit,       // 11 10.0s  juggle mid
    flyingSerpentStrike, // 12 10.0s  piercing dash
    tempestCrash,        // 13 12.0s  juggle finisher AoE
    windWall,            // 14 20.0s  projectile block
    sovereignOfTheSky,   // 15 90.0s  ultimate buff
  ];
}
