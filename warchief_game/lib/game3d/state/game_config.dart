import 'package:vector_math/vector_math.dart';

/// Game configuration constants
///
/// Centralized configuration for all game parameters including
/// terrain, player, monster, ally, and ability settings.
class GameConfig {
  GameConfig._(); // Private constructor to prevent instantiation

  // ==================== TERRAIN CONFIGURATION ====================

  /// Size of the terrain grid (20x20 tiles)
  static const int terrainGridSize = 20;

  /// Size of each terrain tile
  static const double terrainTileSize = 1.0;

  // ==================== PLAYER CONFIGURATION ====================

  /// Player movement speed (units per second)
  static const double playerSpeed = 5.0;

  /// Player rotation speed (degrees per second)
  static const double playerRotationSpeed = 180.0;

  /// Player mesh size
  static const double playerSize = 0.5;

  /// Player starting position
  static final Vector3 playerStartPosition = Vector3(10, 0.5, 2);

  /// Player starting rotation (degrees)
  static const double playerStartRotation = 0.0;

  /// Player direction indicator size
  static const double playerDirectionIndicatorSize = 0.5;

  // ==================== MONSTER CONFIGURATION ====================

  /// Monster maximum health
  static const double monsterMaxHealth = 100.0;

  /// Monster mesh size
  static const double monsterSize = 1.2;

  /// Monster starting position
  static final Vector3 monsterStartPosition = Vector3(18, 0.6, 18);

  /// Monster starting rotation (degrees)
  static const double monsterStartRotation = 180.0;

  /// Monster direction indicator size
  static const double monsterDirectionIndicatorSize = 0.5;

  /// Monster AI decision interval (seconds)
  static const double monsterAiInterval = 2.0;

  /// Monster movement threshold distance for AI decisions
  static const double monsterMoveThresholdMin = 5.0;
  static const double monsterMoveThresholdMax = 12.0;

  /// Monster heal threshold (percentage of max health)
  static const double monsterHealThreshold = 50.0;

  // ==================== MONSTER ABILITIES ====================

  /// Monster Ability 1: Dark Strike (Melee)
  static const double monsterAbility1CooldownMax = 2.0;
  static const double monsterAbility1Damage = 15.0;

  /// Monster Ability 2: Shadow Bolt (Ranged Projectile)
  static const double monsterAbility2CooldownMax = 4.0;
  static const double monsterAbility2ProjectileSize = 0.5;
  static const double monsterAbility2Damage = 12.0;
  static final Vector3 monsterAbility2ImpactColor = Vector3(0.5, 0.0, 0.5); // Purple

  /// Monster Ability 3: Dark Healing
  static const double monsterAbility3CooldownMax = 8.0;
  static const double monsterAbility3HealAmount = 25.0;

  // ==================== ALLY CONFIGURATION ====================

  /// Ally maximum health
  static const double allyMaxHealth = 50.0;

  /// Ally mesh size (relative to player)
  static const double allySize = 0.8;

  /// Ally ability cooldown
  static const double allyAbilityCooldownMax = 5.0;

  /// Ally AI decision interval (seconds)
  static const double allyAiInterval = 3.0;

  /// Ally movement threshold distance for AI decisions
  static const double allyMoveThreshold = 10.0;

  /// Ally sword damage
  static const double allySwordDamage = 10.0;

  /// Ally fireball damage
  static const double allyFireballDamage = 15.0;

  /// Ally heal amount (self-heal)
  static const double allyHealAmount = 15.0;

  /// Ally fireball size
  static const double allyFireballSize = 0.3;

  // ==================== PLAYER ABILITIES ====================

  /// Ability 1: Sword (Melee)
  static const double ability1CooldownMax = 1.5; // 1.5 seconds
  static const double ability1Duration = 0.3; // Sword visible for 0.3 seconds
  static const double ability1Range = 2.0; // Hit detection range
  static const double ability1Damage = 25.0; // Sword damage per hit
  static final Vector3 ability1ImpactColor = Vector3(0.8, 0.8, 0.9); // Silver/gray impact
  static const double ability1ImpactSize = 0.5;

  /// Ability 2: Fireball (Ranged Projectile)
  static const double ability2CooldownMax = 3.0; // 3 seconds
  static const double ability2ProjectileSpeed = 10.0; // units per second
  static const double ability2ProjectileSize = 0.4;
  static const double ability2Damage = 20.0;
  static final Vector3 ability2ProjectileColor = Vector3(1.0, 0.4, 0.0); // Orange

  /// Ability 3: Heal
  static const double ability3CooldownMax = 10.0; // 10 seconds
  static const double ability3HealAmount = 20.0;

  // ==================== PROJECTILE CONFIGURATION ====================

  /// Default projectile lifetime (seconds)
  static const double projectileLifetime = 5.0;

  /// Collision detection threshold (distance in units)
  static const double collisionThreshold = 1.0;

  // ==================== VISUAL EFFECTS CONFIGURATION ====================

  /// Impact effect default size
  static const double impactEffectSize = 0.6;

  /// Impact effect duration (seconds)
  static const double impactEffectDuration = 0.3;

  /// Impact effect growth scale multiplier
  static const double impactEffectGrowthScale = 1.5; // Grows to 2.5x size

  /// Fireball impact size
  static const double fireballImpactSize = 0.8;

  /// Fireball impact color
  static final Vector3 fireballImpactColor = Vector3(1.0, 0.5, 0.0);

  /// Ally fireball impact size
  static const double allyFireballImpactSize = 0.6;

  /// Ally fireball impact color
  static final Vector3 allyFireballImpactColor = Vector3(1.0, 0.4, 0.0);

  /// Ally sword impact size
  static const double allySwordImpactSize = 0.5;

  /// Monster projectile impact size
  static const double monsterProjectileImpactSize = 0.5;

  // ==================== PHYSICS CONFIGURATION ====================

  /// Gravity strength (affects jump/fall physics)
  static const double gravity = 20.0;

  /// Jump velocity (units per second)
  static const double jumpVelocity = 10.0;

  /// Ground level (Y coordinate)
  static const double groundLevel = 0.5;
}
