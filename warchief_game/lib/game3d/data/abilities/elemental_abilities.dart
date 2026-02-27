import 'package:vector_math/vector_math.dart';
import 'ability_types.dart';

/// Elemental abilities - Advanced elemental attacks
class ElementalAbilities {
  ElementalAbilities._();

  /// Ice Lance - Piercing ice projectile
  static final iceLance = AbilityData(
    name: 'Ice Lance',
    description: 'Sharp ice projectile that pierces through enemies',
    type: AbilityType.ranged,
    damage: 18.0,
    cooldown: 3.0,
    range: 40.0,
    color: Vector3(0.7, 0.9, 1.0),
    impactColor: Vector3(0.8, 1.0, 1.0),
    impactSize: 0.4,
    projectileSpeed: 18.0,
    projectileSize: 0.2,
    piercing: true,
    maxTargets: 3,
    category: 'elemental',
    damageSchool: DamageSchool.frost,
  );

  /// Flame Wave - Line AoE fire attack
  static final flameWave = AbilityData(
    name: 'Flame Wave',
    description: 'Sends a wave of fire in a line',
    type: AbilityType.aoe,
    damage: 30.0,
    cooldown: 7.0,
    duration: 0.6,
    range: 12.0,
    color: Vector3(1.0, 0.5, 0.1),
    impactColor: Vector3(1.0, 0.6, 0.2),
    impactSize: 0.8,
    aoeRadius: 2.0,
    statusEffect: StatusEffect.burn,
    statusDuration: 2.0,
    category: 'elemental',
    damageSchool: DamageSchool.fire,
  );

  /// Earthquake - Ground AoE with stun
  static final earthquake = AbilityData(
    name: 'Earthquake',
    description: 'Shakes the ground, damaging and stunning enemies',
    type: AbilityType.channeled,
    damage: 15.0,
    cooldown: 25.0,
    duration: 3.0,
    range: 15.0,
    color: Vector3(0.6, 0.4, 0.2),
    impactColor: Vector3(0.7, 0.5, 0.3),
    impactSize: 1.5,
    aoeRadius: 8.0,
    dotTicks: 6,
    statusEffect: StatusEffect.stun,
    statusDuration: 0.5,
    castTime: 1.0,
    channelEffect: ChannelEffect.earthquake,
    category: 'elemental',
    damageSchool: DamageSchool.nature,
  );

  // ==================== MELEE ABILITIES ====================

  /// Frostbite Slash — Ice-enchanted blade that slows
  static final frostbiteSlash = AbilityData(
    name: 'Frostbite Slash',
    description: 'Slash with an ice-enchanted blade, chilling the target',
    type: AbilityType.melee,
    damage: 18.0,
    cooldown: 1.0,
    range: 2.5,
    color: Vector3(0.6, 0.85, 1.0),
    impactColor: Vector3(0.7, 0.9, 1.0),
    impactSize: 0.5,
    statusEffect: StatusEffect.slow,
    statusDuration: 2.0,
    category: 'elemental',
    damageSchool: DamageSchool.frost,
  );

  /// Magma Strike — Molten fist slam with burn
  static final magmaStrike = AbilityData(
    name: 'Magma Strike',
    description: 'Slam with a molten fist, searing the target with lingering flames',
    type: AbilityType.melee,
    damage: 28.0,
    cooldown: 7.0,
    range: 2.5,
    color: Vector3(1.0, 0.4, 0.1),
    impactColor: Vector3(1.0, 0.5, 0.2),
    impactSize: 0.7,
    statusEffect: StatusEffect.burn,
    statusDuration: 3.0,
    category: 'elemental',
    damageSchool: DamageSchool.fire,
  );

  /// Elemental Rend — Fiery strike that permanently exposes target
  static final elementalRend = AbilityData(
    name: 'Elemental Rend',
    description: 'A fiery strike that permanently exposes the target to fire damage.',
    type: AbilityType.melee,
    damage: 10.0,
    cooldown: 12.0,
    range: 2.5,
    color: Vector3(1.0, 0.4, 0.1),
    impactColor: Vector3(1.0, 0.5, 0.2),
    impactSize: 0.6,
    category: 'elemental',
    damageSchool: DamageSchool.fire,
    appliesPermanentVulnerability: true,
  );

  // ==================== CHAIN COMBO PRIMER ====================

  /// Elemental Chain — Activates chain-combo mode for elementals.
  /// Land 7 consecutive elemental strikes within 7 seconds to fire the chain combo.
  static final elementalChain = AbilityData(
    name: 'Elemental Chain',
    description: 'Chain elemental forces through your blows — activate chain-combo mode. '
        'Land 7 elemental hits within 7 seconds to trigger a red mana surge and elemental AoE.',
    type: AbilityType.melee,
    damage: 20.0,
    cooldown: 10.0,
    range: 2.5,
    color: Vector3(0.9, 0.45, 0.12),
    impactColor: Vector3(1.0, 0.58, 0.22),
    impactSize: 0.65,
    manaColor: ManaColor.red,
    manaCost: 20.0,
    damageSchool: DamageSchool.fire,
    category: 'elemental',
    enablesComboChain: true,
  );

  /// All elemental abilities as a list
  static List<AbilityData> get all => [
    iceLance, flameWave, earthquake,
    frostbiteSlash, magmaStrike, elementalRend, elementalChain,
  ];
}
