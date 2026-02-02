import 'package:vector_math/vector_math.dart';

/// Ability type enumeration
enum AbilityType {
  melee,      // Close-range physical attacks
  ranged,     // Projectile-based attacks
  heal,       // Health restoration
  buff,       // Positive effects on self/allies
  debuff,     // Negative effects on enemies
  aoe,        // Area of effect damage
  dot,        // Damage over time
  channeled,  // Requires standing still to cast
  summon,     // Creates temporary units
  utility,    // Non-combat abilities (movement, vision, etc.)
}

/// Status effect type enumeration
enum StatusEffect {
  none,
  burn,       // Fire damage over time
  freeze,     // Movement slow/stop
  poison,     // Nature damage over time
  stun,       // Cannot act
  slow,       // Reduced movement speed
  bleed,      // Physical damage over time
  blind,      // Reduced accuracy/vision
  root,       // Cannot move but can act
  silence,    // Cannot use abilities
  haste,      // Increased movement/attack speed
  shield,     // Damage absorption
  regen,      // Health over time
  strength,   // Increased damage
  weakness,   // Reduced damage output
}

/// Ability data class containing all parameters for an ability
///
/// All ability parameters (name, damage, cooldown, color, etc.) are defined
/// using this class for easy tuning and maintenance.
class AbilityData {
  final String name;
  final String description;
  final AbilityType type;
  final double damage;
  final double cooldown;
  final double duration;
  final double range;
  final Vector3 color;
  final Vector3 impactColor;
  final double impactSize;
  final double projectileSpeed;
  final double projectileSize;
  final double healAmount;

  // Extended properties for advanced abilities
  final StatusEffect statusEffect;
  final double statusDuration;
  final double statusStrength;
  final double aoeRadius;
  final int dotTicks;
  final double knockbackForce;
  final bool piercing;
  final int maxTargets;
  final double castTime;
  final String category;

  const AbilityData({
    required this.name,
    required this.description,
    required this.type,
    this.damage = 0.0,
    required this.cooldown,
    this.duration = 0.0,
    this.range = 0.0,
    required this.color,
    required this.impactColor,
    this.impactSize = 0.5,
    this.projectileSpeed = 0.0,
    this.projectileSize = 0.0,
    this.healAmount = 0.0,
    // Extended property defaults
    this.statusEffect = StatusEffect.none,
    this.statusDuration = 0.0,
    this.statusStrength = 0.0,
    this.aoeRadius = 0.0,
    this.dotTicks = 0,
    this.knockbackForce = 0.0,
    this.piercing = false,
    this.maxTargets = 1,
    this.castTime = 0.0,
    this.category = 'general',
  });
}
