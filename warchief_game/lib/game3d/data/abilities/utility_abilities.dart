import 'package:vector_math/vector_math.dart';
import 'ability_types.dart';

/// Utility abilities - Movement and team buffs
class UtilityAbilities {
  UtilityAbilities._();

  /// Sprint - Movement speed buff
  static final sprint = AbilityData(
    name: 'Sprint',
    description: 'Greatly increases movement speed temporarily',
    type: AbilityType.buff,
    cooldown: 30.0,
    duration: 8.0,
    color: Vector3(0.9, 0.9, 0.3),
    impactColor: Vector3(1.0, 1.0, 0.5),
    impactSize: 0.6,
    statusEffect: StatusEffect.haste,
    statusStrength: 1.5,
    category: 'utility',
  );

  /// Battle Shout - AoE damage buff for allies
  static final battleShout = AbilityData(
    name: 'Battle Shout',
    description: 'Boosts damage of all nearby allies',
    type: AbilityType.buff,
    cooldown: 45.0,
    duration: 20.0,
    color: Vector3(1.0, 0.4, 0.2),
    impactColor: Vector3(1.0, 0.5, 0.3),
    impactSize: 1.5,
    aoeRadius: 10.0,
    statusEffect: StatusEffect.strength,
    statusStrength: 1.15,
    maxTargets: 5,
    category: 'utility',
  );

  // ==================== MELEE ABILITIES ====================

  /// Quick Slash — Basic fast slash
  static final quickSlash = AbilityData(
    name: 'Quick Slash',
    description: 'A swift, efficient slash — nothing fancy, just fast',
    type: AbilityType.melee,
    damage: 10.0,
    cooldown: 1.0,
    range: 2.0,
    color: Vector3(0.8, 0.8, 0.8),
    impactColor: Vector3(0.9, 0.9, 0.9),
    impactSize: 0.4,
    category: 'utility',
  );

  /// Shoulder Charge — Short charge with knockback and movement
  static final shoulderCharge = AbilityData(
    name: 'Shoulder Charge',
    description: 'Charge forward and slam into the target, knocking them back',
    type: AbilityType.melee,
    damage: 18.0,
    cooldown: 5.0,
    range: 5.0,
    color: Vector3(0.85, 0.75, 0.4),
    impactColor: Vector3(0.95, 0.85, 0.5),
    impactSize: 0.6,
    knockbackForce: 2.0,
    category: 'utility',
  );

  /// Weak Point — Calculated strike that permanently exposes physical weakness
  static final weakPoint = AbilityData(
    name: 'Weak Point',
    description: 'A calculated strike that permanently exposes the target\'s physical weakness.',
    type: AbilityType.melee,
    damage: 10.0,
    cooldown: 12.0,
    range: 2.5,
    color: Vector3(0.6, 0.6, 0.5),
    impactColor: Vector3(0.7, 0.7, 0.6),
    impactSize: 0.6,
    category: 'utility',
    appliesPermanentVulnerability: true,
  );

  /// All utility abilities as a list
  static List<AbilityData> get all => [
    sprint, battleShout,
    quickSlash, shoulderCharge, weakPoint,
  ];
}
