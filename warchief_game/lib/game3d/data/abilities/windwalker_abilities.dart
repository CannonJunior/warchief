import 'package:vector_math/vector_math.dart';
import 'ability_types.dart';

/// Wind Walker abilities — 10 White Mana abilities (5 movement, 5 non-movement)
///
/// All abilities use White Mana (wind energy) and belong to the 'windwalker'
/// category. Silver-white color theme with variations per ability.
class WindWalkerAbilities {
  WindWalkerAbilities._();

  // ==================== MOVEMENT ABILITIES (5) ====================

  /// Gale Step — Forward dash through enemies dealing damage along the path.
  /// 2 charges via short cooldown.
  static final galeStep = AbilityData(
    name: 'Gale Step',
    description: 'Dash forward through enemies, dealing damage along the path',
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
  );

  /// Zephyr Roll — Evasive roll granting brief invulnerability (i-frames).
  /// Moves player forward 4 units quickly.
  static final zephyrRoll = AbilityData(
    name: 'Zephyr Roll',
    description: 'Evasive roll granting brief invulnerability',
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
  );

  /// Tailwind Retreat — Backflip away from enemies, pushing nearby foes back.
  static final tailwindRetreat = AbilityData(
    name: 'Tailwind Retreat',
    description: 'Backflip away from enemies, pushing nearby foes back',
    type: AbilityType.utility,
    cooldown: 12.0,
    duration: 0.4,
    range: 5.0,
    color: Vector3(0.8, 0.88, 0.98),
    impactColor: Vector3(0.7, 0.8, 1.0),
    impactSize: 0.6,
    knockbackForce: 4.0,
    manaColor: ManaColor.white,
    manaCost: 12.0,
    category: 'windwalker',
  );

  /// Flying Serpent Strike — Long-range dash dealing damage to all in path.
  /// Higher damage and longer range than Gale Step.
  static final flyingSerpentStrike = AbilityData(
    name: 'Flying Serpent Strike',
    description: 'Dash forward at low altitude, damaging all enemies in path',
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
  );

  /// Take Flight — Toggle flight mode on/off. Core flight ability.
  /// 1s cooldown prevents spam, 15 white mana initial + 3/sec drain.
  static final takeFlight = AbilityData(
    name: 'Take Flight',
    description: 'Toggle flight mode — soar through the skies consuming White Mana',
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

  // ==================== NON-MOVEMENT ABILITIES (5) ====================

  /// Cyclone Dive — AoE slam from above. Leap up then slam down
  /// dealing damage + stun at center.
  static final cycloneDive = AbilityData(
    name: 'Cyclone Dive',
    description: 'Leap upward then slam down, dealing AoE damage and stunning',
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
  );

  /// Wind Wall — Blocks projectiles in front of player for 4 seconds.
  static final windWall = AbilityData(
    name: 'Wind Wall',
    description: 'Summon a wall of wind that blocks incoming projectiles',
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

  /// Tempest Charge — Charge to target dealing damage + knockback along path.
  static final tempestCharge = AbilityData(
    name: 'Tempest Charge',
    description: 'Charge to target with tempest force, knocking back enemies',
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
  );

  /// Healing Gale — Heal self for 40 HP over time.
  static final healingGale = AbilityData(
    name: 'Healing Gale',
    description: 'Soothing winds restore health over time',
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

  /// Sovereign of the Sky — 12-second buff: enhanced flight speed (+50%),
  /// all wind abilities -30% mana cost.
  static final sovereignOfTheSky = AbilityData(
    name: 'Sovereign of the Sky',
    description: 'Become one with the wind — enhanced flight speed and reduced mana costs',
    type: AbilityType.buff,
    cooldown: 90.0,
    duration: 12.0,
    color: Vector3(1.0, 0.97, 0.85),
    impactColor: Vector3(1.0, 0.95, 0.8),
    impactSize: 1.5,
    manaColor: ManaColor.white,
    manaCost: 40.0,
    category: 'windwalker',
  );

  // ==================== ADDITIONAL ABILITIES (4) ====================

  /// Wind Affinity — Doubles white mana regen rate for 15 seconds.
  static final windAffinity = AbilityData(
    name: 'Wind Affinity',
    description: 'Attune to the wind — doubles white mana regeneration for 15 seconds',
    type: AbilityType.buff,
    cooldown: 60.0,
    duration: 15.0,
    color: Vector3(0.8, 0.92, 1.0),
    impactColor: Vector3(0.75, 0.88, 1.0),
    impactSize: 0.6,
    manaColor: ManaColor.white,
    manaCost: 15.0,
    category: 'windwalker',
  );

  /// Silent Mind — Fully restores white mana; next white ability is free and instant.
  static final silentMind = AbilityData(
    name: 'Silent Mind',
    description: 'Clear your mind — fully restore white mana; next white ability costs 0 and casts instantly',
    type: AbilityType.buff,
    cooldown: 120.0,
    duration: 0.0,
    color: Vector3(0.95, 0.98, 1.0),
    impactColor: Vector3(0.9, 0.95, 1.0),
    impactSize: 0.8,
    manaColor: ManaColor.white,
    manaCost: 0.0,
    category: 'windwalker',
  );

  /// Windshear — 90-degree cone AoE (40 yards). Lifts targets: enemies take
  /// 10 damage + knockdown, friendlies are healed for 10 HP.
  static final windshear = AbilityData(
    name: 'Windshear',
    description: 'Unleash a shearing gust in a cone — enemies take damage and are knocked down, allies are healed',
    type: AbilityType.aoe,
    damage: 10.0,
    cooldown: 240.0,
    duration: 0.0,
    color: Vector3(0.7, 0.85, 1.0),
    impactColor: Vector3(0.65, 0.8, 1.0),
    impactSize: 1.0,
    aoeRadius: 40.0,
    healAmount: 10.0,
    statusEffect: StatusEffect.stun,
    statusDuration: 2.0,
    manaColor: ManaColor.white,
    manaCost: 35.0,
    category: 'windwalker',
  );

  /// Wind Warp — Dash forward on ground; if flying, doubles flight speed for 5s.
  static final windWarp = AbilityData(
    name: 'Wind Warp',
    description: 'Warp through the wind — dash forward on ground, or double flight speed for 5 seconds while airborne',
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
  );

  // ==================== MELEE COMBO ABILITIES ====================
  // Combo: Zephyr Palm -> Cyclone Kick -> Stormfist Barrage

  /// Zephyr Palm — Quick palm strike, combo starter
  static final zephyrPalm = AbilityData(
    name: 'Zephyr Palm',
    description: 'Swift wind-charged palm strike — quick combo opener',
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
  );

  /// Cyclone Kick — Spinning kick with knockback displacement
  static final cycloneKick = AbilityData(
    name: 'Cyclone Kick',
    description: 'Spinning wind-powered kick that knocks enemies away',
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
  );

  /// Stormfist Barrage — Triple-punch finisher with windup and stun
  static final stormfistBarrage = AbilityData(
    name: 'Stormfist Barrage',
    description: 'Channel the storm into a three-hit punch barrage that stuns on impact',
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
  );

  // ==================== BASIC NO-MANA MELEE ====================

  /// Basic no-mana melee: quick jab
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
  );

  /// Basic no-mana melee: wind punch
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
  );

  /// Medium-cooldown permanent physical vulnerability
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
  );

  // ==================== CHAIN COMBO PRIMER ====================

  /// Gale Fury — Activates chain-combo mode for windwalkers.
  /// Land 7 consecutive windwalker strikes within 7 seconds to fire the chain combo.
  static final galeFury = AbilityData(
    name: 'Gale Fury',
    description: 'Unleash the fury of the gale — activate chain-combo mode. '
        'Land 7 windwalker strikes within 7 seconds to trigger a powerful haste surge.',
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
  );

  /// All Wind Walker abilities as a list
  static List<AbilityData> get all => [
    galeStep,
    zephyrRoll,
    tailwindRetreat,
    flyingSerpentStrike,
    takeFlight,
    cycloneDive,
    windWall,
    tempestCharge,
    healingGale,
    sovereignOfTheSky,
    windAffinity,
    silentMind,
    windshear,
    windWarp,
    zephyrPalm,
    cycloneKick,
    stormfistBarrage,
    swiftJab,
    galePunch,
    pressurePoint,
    galeFury,
  ];
}
