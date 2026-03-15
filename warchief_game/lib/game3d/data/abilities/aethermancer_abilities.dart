import 'package:vector_math/vector_math.dart';
import 'ability_types.dart';

/// Aethermancer abilities — Wind + Ley Line healing class
///
/// Channels both White (wind/air) and Blue (Ley Line arcane) mana into
/// healing, shielding, and support magic. Draws strength from the sky above
/// and the ley currents below.
class AethermancerAbilities {
  AethermancerAbilities._();

  // ==================== HEAL ABILITIES ====================

  /// Wind Mend — Wind-channeled single-target heal
  static final windMend = AbilityData(
    name: 'Wind Mend',
    description: 'Channel the wind to seal an ally\'s wounds',
    type: AbilityType.heal,
    cooldown: 4.0,
    duration: 0.5,
    range: 40.0,
    healAmount: 32.0,
    color: Vector3(0.8, 0.95, 1.0),
    impactColor: Vector3(0.9, 1.0, 1.0),
    impactSize: 1.0,
    castTime: 1.5,
    manaColor: ManaColor.white,
    manaCost: 15.0,
    category: 'aethermancer',
    damageSchool: DamageSchool.holy,
  );

  /// Ley Flow — Ley line regeneration HoT
  static final leyFlow = AbilityData(
    name: 'Ley Flow',
    description: 'Infuse an ally with ley line energy, restoring health over time',
    type: AbilityType.heal,
    cooldown: 6.0,
    duration: 8.0,
    range: 40.0,
    healAmount: 38.0,
    color: Vector3(0.5, 0.7, 1.0),
    impactColor: Vector3(0.6, 0.8, 1.0),
    impactSize: 0.8,
    statusEffect: StatusEffect.regen,
    dotTicks: 8,
    manaColor: ManaColor.blue,
    manaCost: 15.0,
    category: 'aethermancer',
    damageSchool: DamageSchool.holy,
  );

  /// Aether Circle — Blended wind + ley AoE heal
  static final aetherCircle = AbilityData(
    name: 'Aether Circle',
    description: 'Weave wind and ley energy into a circle that heals all nearby allies',
    type: AbilityType.heal,
    cooldown: 15.0,
    duration: 0.5,
    range: 40.0,
    healAmount: 18.0,
    color: Vector3(0.7, 0.85, 1.0),
    impactColor: Vector3(0.8, 0.9, 1.0),
    impactSize: 2.0,
    aoeRadius: 8.0,
    maxTargets: 5,
    manaColor: ManaColor.white,
    manaCost: 20.0,
    category: 'aethermancer',
    damageSchool: DamageSchool.holy,
  );

  // ==================== BUFF ABILITIES ====================

  /// Zephyr Ward — Wind barrier that grants haste
  static final zephyrWard = AbilityData(
    name: 'Zephyr Ward',
    description: 'Surround an ally with a wind ward, granting haste',
    type: AbilityType.buff,
    cooldown: 20.0,
    duration: 12.0,
    range: 40.0,
    color: Vector3(0.9, 0.95, 1.0),
    impactColor: Vector3(1.0, 1.0, 1.0),
    impactSize: 1.0,
    statusEffect: StatusEffect.haste,
    statusStrength: 1.20,
    manaColor: ManaColor.white,
    manaCost: 15.0,
    category: 'aethermancer',
    damageSchool: DamageSchool.holy,
  );

  /// Arcane Cleanse — Ley-powered debuff removal
  static final arcaneCleanse = AbilityData(
    name: 'Arcane Cleanse',
    description: 'Burn away harmful effects with ley line energy',
    type: AbilityType.buff,
    cooldown: 8.0,
    range: 40.0,
    color: Vector3(0.4, 0.6, 1.0),
    impactColor: Vector3(0.5, 0.7, 1.0),
    impactSize: 1.0,
    manaColor: ManaColor.blue,
    manaCost: 10.0,
    category: 'aethermancer',
    damageSchool: DamageSchool.arcane,
  );

  // ==================== MELEE ABILITIES ====================

  /// Gale Fist — Wind-infused palm strike
  static final galeFist = AbilityData(
    name: 'Gale Fist',
    description: 'Strike with a burst of concentrated wind',
    type: AbilityType.melee,
    damage: 10.0,
    cooldown: 1.0,
    range: 2.0,
    color: Vector3(0.8, 0.9, 1.0),
    impactColor: Vector3(0.9, 0.95, 1.0),
    impactSize: 0.5,
    category: 'aethermancer',
    damageSchool: DamageSchool.holy,
  );

  /// Ley Surge — Arcane-empowered strike that slows the target
  static final leySurge = AbilityData(
    name: 'Ley Surge',
    description: 'Channel ley line energy into a strike that slows the target',
    type: AbilityType.melee,
    damage: 20.0,
    cooldown: 6.0,
    range: 2.5,
    color: Vector3(0.4, 0.55, 1.0),
    impactColor: Vector3(0.5, 0.65, 1.0),
    impactSize: 0.7,
    statusEffect: StatusEffect.slow,
    statusDuration: 2.0,
    manaColor: ManaColor.blue,
    manaCost: 15.0,
    category: 'aethermancer',
    damageSchool: DamageSchool.arcane,
  );

  // ==================== RANGED ABILITIES ====================

  /// Ley Bolt — Arcane-charged bolt fired from ley line confluence
  ///
  /// Costs both Blue (primary, ley energy) and White (secondary, wind carry).
  static final leyBolt = AbilityData(
    name: 'Ley Bolt',
    description: 'Fire a bolt of condensed ley line energy at the target',
    type: AbilityType.ranged,
    damage: 28.0,
    cooldown: 3.0,
    range: 40.0,
    color: Vector3(0.5, 0.7, 1.0),
    impactColor: Vector3(0.6, 0.8, 1.0),
    impactSize: 0.6,
    projectileSpeed: 22.0,
    projectileSize: 0.25,
    manaColor: ManaColor.blue,
    manaCost: 12.0,
    secondaryManaColor: ManaColor.white,
    secondaryManaCost: 8.0,
    category: 'aethermancer',
    damageSchool: DamageSchool.arcane,
  );

  /// Tempest Lance — Wind-spear forged from converging sky and ley currents
  ///
  /// Pierces through targets and leaves them slowed. The 1.2 s cast time
  /// reflects the focused channeling of both wind and arcane into a single
  /// concentrated strike.
  static final tempestLance = AbilityData(
    name: 'Tempest Lance',
    description: 'Hurl a piercing lance of condensed wind and arcane power, slowing the target',
    type: AbilityType.ranged,
    damage: 40.0,
    cooldown: 8.0,
    range: 40.0,
    color: Vector3(0.88, 0.95, 1.0),
    impactColor: Vector3(1.0, 1.0, 1.0),
    impactSize: 0.8,
    projectileSpeed: 30.0,
    projectileSize: 0.2,
    piercing: true,
    castTime: 1.2,
    statusEffect: StatusEffect.slow,
    statusDuration: 2.5,
    statusStrength: 0.45,
    manaColor: ManaColor.white,
    manaCost: 20.0,
    secondaryManaColor: ManaColor.blue,
    secondaryManaCost: 12.0,
    category: 'aethermancer',
    damageSchool: DamageSchool.holy,
  );

  // ==================== RANGED CC ABILITIES ====================

  /// Aether Chill — Crystallised ley frost projectile that freezes the target.
  /// White (wind-cold carry) + Blue (ley arcane) dual mana.
  static final aetherChill = AbilityData(
    name: 'Aether Chill',
    description: 'Fire a shard of crystallised ley frost that freezes the target solid for 3 seconds.',
    type: AbilityType.ranged,
    damage: 22.0,
    cooldown: 16.0,
    range: 40.0,
    color: Vector3(0.55, 0.82, 1.0),
    impactColor: Vector3(0.70, 0.92, 1.0),
    impactSize: 0.7,
    projectileSpeed: 18.0,
    projectileSize: 0.22,
    statusEffect: StatusEffect.freeze,
    statusDuration: 3.0,
    castTime: 0.8,
    manaColor: ManaColor.white,
    manaCost: 18.0,
    secondaryManaColor: ManaColor.blue,
    secondaryManaCost: 12.0,
    category: 'aethermancer',
    damageSchool: DamageSchool.frost,
  );

  // ==================== DUAL-MANA HEAL ABILITIES ====================

  /// Aetheric Mending — Healing drawn equally from sky and ley
  ///
  /// Costs Blue and White mana in equal measure, blending wind and arcane
  /// energy into a clean, powerful restoration.
  static final aethericMending = AbilityData(
    name: 'Aetheric Mending',
    description: 'Weave wind and ley energy into a powerful restoration',
    type: AbilityType.heal,
    cooldown: 5.0,
    range: 40.0,
    healAmount: 35.0,
    color: Vector3(0.72, 0.88, 1.0),
    impactColor: Vector3(0.82, 0.94, 1.0),
    impactSize: 1.1,
    castTime: 1.0,
    manaColor: ManaColor.blue,
    manaCost: 14.0,
    secondaryManaColor: ManaColor.white,
    secondaryManaCost: 14.0,
    category: 'aethermancer',
    damageSchool: DamageSchool.holy,
  );

  /// Aether Aegis — Heal + absorb shield woven from converging sky and earth
  ///
  /// Costs both mana types; applies a damage-absorbing shield on the target
  /// that expires after [statusDuration] seconds even if not fully consumed.
  static final aetherAegis = AbilityData(
    name: 'Aether Aegis',
    description: 'Restore health and weave an aetheric shield that absorbs '
        '45 damage. The shield expires after 10 seconds if not consumed.',
    type: AbilityType.heal,
    cooldown: 18.0,
    range: 40.0,
    healAmount: 20.0,
    color: Vector3(0.75, 0.9, 1.0),
    impactColor: Vector3(0.85, 0.95, 1.0),
    impactSize: 1.3,
    statusEffect: StatusEffect.shield,
    statusStrength: 45.0,
    statusDuration: 10.0,
    manaColor: ManaColor.white,
    manaCost: 20.0,
    secondaryManaColor: ManaColor.blue,
    secondaryManaCost: 20.0,
    category: 'aethermancer',
    damageSchool: DamageSchool.holy,
  );

  // ==================== CHAIN COMBO PRIMER ====================

  /// Aether Surge — Activates chain-combo mode for the Aethermancer.
  /// Land 7 consecutive Aethermancer strikes within 7 seconds to fire the chain combo.
  static final aetherSurge = AbilityData(
    name: 'Aether Surge',
    description: 'Merge wind and ley power into a surging force — activate chain-combo mode. '
        'Land 7 strikes within 7 seconds to unleash a wave of aetheric restoration.',
    type: AbilityType.melee,
    damage: 12.0,
    cooldown: 10.0,
    range: 2.0,
    color: Vector3(0.65, 0.8, 1.0),
    impactColor: Vector3(0.75, 0.9, 1.0),
    impactSize: 0.7,
    manaColor: ManaColor.blue,
    manaCost: 20.0,
    damageSchool: DamageSchool.arcane,
    category: 'aethermancer',
    enablesComboChain: true,
  );

  /// Aether Flow — Party-wide haste buff for all friendly units
  static final aetherFlow = AbilityData(
    name: 'Aether Flow',
    description: 'Suffuse all allies with flowing aetheric currents, accelerating'
        ' their movement and casting for a full hour.',
    type: AbilityType.buff,
    cooldown: 5.0,
    duration: 3600.0,
    range: 100.0,
    color: Vector3(0.7, 0.85, 1.0),
    impactColor: Vector3(0.8, 0.9, 1.0),
    impactSize: 1.6,
    statusEffect: StatusEffect.haste,
    statusStrength: 0.20,
    manaColor: ManaColor.white,
    manaCost: 40.0,
    category: 'aethermancer',
    isPartyBuff: true,
  );

  /// All Aethermancer abilities as a list
  static List<AbilityData> get all => [
    windMend, leyFlow, aetherCircle, zephyrWard, arcaneCleanse,
    galeFist, leySurge, aetherSurge,
    leyBolt, tempestLance, aetherChill,
    aethericMending, aetherAegis, aetherFlow,
  ];
}
