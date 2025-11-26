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

/// Centralized ability configuration
///
/// All ability parameters (name, damage, cooldown, color, etc.) are defined
/// in this single file for easy tuning and maintenance.
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

/// All game abilities defined in one place
class AbilitiesConfig {
  AbilitiesConfig._(); // Private constructor

  // ==================== PLAYER ABILITIES ====================

  /// Player Ability 1: Sword (Melee Attack)
  static final playerSword = AbilityData(
    name: 'Sword',
    description: 'A swift melee attack that damages nearby enemies',
    type: AbilityType.melee,
    damage: 25.0,
    cooldown: 1.5,
    duration: 0.3,
    range: 2.0,
    color: Vector3(0.7, 0.7, 0.8), // Gray metallic
    impactColor: Vector3(0.8, 0.8, 0.9), // Silver
    impactSize: 0.5,
  );

  /// Player Ability 2: Fireball (Ranged Projectile)
  static final playerFireball = AbilityData(
    name: 'Fireball',
    description: 'Launches a blazing projectile at enemies',
    type: AbilityType.ranged,
    damage: 20.0,
    cooldown: 3.0,
    range: 50.0, // Max travel distance
    color: Vector3(1.0, 0.4, 0.0), // Orange
    impactColor: Vector3(1.0, 0.5, 0.0), // Orange-yellow
    impactSize: 0.8,
    projectileSpeed: 10.0,
    projectileSize: 0.4,
  );

  /// Player Ability 3: Heal (Self Heal)
  static final playerHeal = AbilityData(
    name: 'Heal',
    description: 'Restores health over time',
    type: AbilityType.heal,
    cooldown: 10.0,
    duration: 1.0,
    healAmount: 20.0,
    color: Vector3(0.5, 1.0, 0.3), // Green/yellow
    impactColor: Vector3(0.3, 1.0, 0.5), // Green glow
    impactSize: 1.5,
  );

  // ==================== MONSTER ABILITIES ====================

  /// Monster Ability 1: Dark Strike (Melee Sword Attack)
  static final monsterDarkStrike = AbilityData(
    name: 'Dark Strike',
    description: 'A devastating melee attack with a giant shadow sword',
    type: AbilityType.melee,
    damage: 15.0,
    cooldown: 2.0,
    duration: 0.4,
    range: 3.0,
    color: Vector3(0.4, 0.1, 0.5), // Dark purple sword
    impactColor: Vector3(0.6, 0.2, 0.8), // Purple impact
    impactSize: 0.6,
  );

  /// Monster Ability 2: Shadow Bolt (Ranged Projectile)
  static final monsterShadowBolt = AbilityData(
    name: 'Shadow Bolt',
    description: 'Fires a bolt of dark energy',
    type: AbilityType.ranged,
    damage: 12.0,
    cooldown: 4.0,
    range: 50.0,
    color: Vector3(0.5, 0.0, 0.5), // Purple projectile
    impactColor: Vector3(0.5, 0.0, 0.5), // Purple impact
    impactSize: 0.5,
    projectileSpeed: 6.0,
    projectileSize: 0.5,
  );

  /// Monster Ability 3: Dark Healing
  static final monsterDarkHeal = AbilityData(
    name: 'Dark Heal',
    description: 'Channels dark energy to restore health',
    type: AbilityType.heal,
    cooldown: 8.0,
    duration: 0.5,
    healAmount: 25.0,
    color: Vector3(0.3, 0.0, 0.3), // Dark purple
    impactColor: Vector3(0.5, 0.1, 0.5), // Purple glow
    impactSize: 1.2,
  );

  // ==================== ALLY ABILITIES ====================
  // Allies use variants of player abilities

  /// Ally Sword Attack
  static final allySword = AbilityData(
    name: 'Ally Sword',
    description: 'Ally melee attack',
    type: AbilityType.melee,
    damage: 10.0,
    cooldown: 5.0,
    duration: 0.3,
    range: 2.0,
    color: Vector3(0.6, 0.8, 1.0), // Light blue
    impactColor: Vector3(0.7, 0.9, 1.0), // Cyan
    impactSize: 0.5,
  );

  /// Ally Fireball
  static final allyFireball = AbilityData(
    name: 'Ally Fireball',
    description: 'Ally ranged projectile',
    type: AbilityType.ranged,
    damage: 15.0,
    cooldown: 5.0,
    range: 50.0,
    color: Vector3(1.0, 0.4, 0.0), // Orange
    impactColor: Vector3(1.0, 0.4, 0.0), // Orange
    impactSize: 0.6,
    projectileSpeed: 8.0,
    projectileSize: 0.3,
  );

  /// Ally Self Heal
  static final allyHeal = AbilityData(
    name: 'Ally Heal',
    description: 'Ally self-healing ability',
    type: AbilityType.heal,
    cooldown: 5.0,
    duration: 0.5,
    healAmount: 15.0,
    color: Vector3(0.5, 1.0, 0.3), // Green
    impactColor: Vector3(0.3, 1.0, 0.5), // Green glow
    impactSize: 1.0,
  );

  // ==================== HELPER METHODS ====================

  /// Get player ability by index (0=Sword, 1=Fireball, 2=Heal)
  static AbilityData getPlayerAbility(int index) {
    switch (index) {
      case 0:
        return playerSword;
      case 1:
        return playerFireball;
      case 2:
        return playerHeal;
      default:
        return playerSword;
    }
  }

  /// Get monster ability by index (0=DarkStrike, 1=ShadowBolt, 2=DarkHeal)
  static AbilityData getMonsterAbility(int index) {
    switch (index) {
      case 0:
        return monsterDarkStrike;
      case 1:
        return monsterShadowBolt;
      case 2:
        return monsterDarkHeal;
      default:
        return monsterDarkStrike;
    }
  }

  /// Get ally ability by index (0=Sword, 1=Fireball, 2=Heal)
  static AbilityData getAllyAbility(int index) {
    switch (index) {
      case 0:
        return allySword;
      case 1:
        return allyFireball;
      case 2:
        return allyHeal;
      default:
        return allySword;
    }
  }

  /// List of all player abilities for UI display
  static List<AbilityData> get playerAbilities => [
    playerSword,
    playerFireball,
    playerHeal,
  ];

  /// List of all monster abilities
  static List<AbilityData> get monsterAbilities => [
    monsterDarkStrike,
    monsterShadowBolt,
    monsterDarkHeal,
  ];

  /// List of all ally abilities
  static List<AbilityData> get allyAbilities => [
    allySword,
    allyFireball,
    allyHeal,
  ];

  // ============================================================
  // POTENTIAL FUTURE ABILITIES (Not yet assigned to any unit)
  // ============================================================
  // These abilities are available for future units and characters.
  // To assign an ability to a unit, reference it in the appropriate
  // system file (ability_system.dart, ai_system.dart, etc.)

  // ==================== WARRIOR/TANK ABILITIES ====================

  /// Shield Bash - Melee stun attack
  static final shieldBash = AbilityData(
    name: 'Shield Bash',
    description: 'Strikes enemy with shield, stunning them briefly',
    type: AbilityType.melee,
    damage: 10.0,
    cooldown: 6.0,
    duration: 0.3,
    range: 1.5,
    color: Vector3(0.6, 0.6, 0.7), // Steel gray
    impactColor: Vector3(1.0, 1.0, 0.5), // Yellow flash
    impactSize: 0.6,
    statusEffect: StatusEffect.stun,
    statusDuration: 1.5,
    category: 'warrior',
  );

  /// Whirlwind - Spinning AoE attack
  static final whirlwind = AbilityData(
    name: 'Whirlwind',
    description: 'Spins with weapon extended, damaging all nearby enemies',
    type: AbilityType.aoe,
    damage: 18.0,
    cooldown: 8.0,
    duration: 1.0,
    range: 3.0,
    color: Vector3(0.8, 0.8, 0.8), // Silver
    impactColor: Vector3(0.9, 0.9, 0.9), // White
    impactSize: 0.4,
    aoeRadius: 3.0,
    maxTargets: 5,
    category: 'warrior',
  );

  /// Charge - Rush forward and knockback
  static final charge = AbilityData(
    name: 'Charge',
    description: 'Rushes toward enemy, knocking them back on impact',
    type: AbilityType.melee,
    damage: 15.0,
    cooldown: 10.0,
    duration: 0.5,
    range: 8.0,
    color: Vector3(0.9, 0.7, 0.3), // Gold
    impactColor: Vector3(1.0, 0.8, 0.4), // Bright gold
    impactSize: 0.8,
    knockbackForce: 5.0,
    category: 'warrior',
  );

  /// Taunt - Forces enemies to attack you
  static final taunt = AbilityData(
    name: 'Taunt',
    description: 'Forces nearby enemies to focus attacks on you',
    type: AbilityType.debuff,
    cooldown: 12.0,
    duration: 4.0,
    range: 6.0,
    color: Vector3(1.0, 0.3, 0.3), // Red
    impactColor: Vector3(1.0, 0.2, 0.2), // Dark red
    impactSize: 1.0,
    aoeRadius: 6.0,
    maxTargets: 3,
    category: 'warrior',
  );

  /// Fortify - Defensive shield buff
  static final fortify = AbilityData(
    name: 'Fortify',
    description: 'Raises shield to absorb incoming damage',
    type: AbilityType.buff,
    cooldown: 15.0,
    duration: 5.0,
    color: Vector3(0.4, 0.6, 0.9), // Blue steel
    impactColor: Vector3(0.5, 0.7, 1.0), // Light blue
    impactSize: 1.2,
    statusEffect: StatusEffect.shield,
    statusStrength: 50.0, // Absorbs 50 damage
    category: 'warrior',
  );

  // ==================== MAGE/ELEMENTAL ABILITIES ====================

  /// Frost Bolt - Ice projectile with slow
  static final frostBolt = AbilityData(
    name: 'Frost Bolt',
    description: 'Launches icy projectile that slows enemies',
    type: AbilityType.ranged,
    damage: 15.0,
    cooldown: 2.5,
    range: 40.0,
    color: Vector3(0.5, 0.8, 1.0), // Ice blue
    impactColor: Vector3(0.7, 0.9, 1.0), // Light blue
    impactSize: 0.5,
    projectileSpeed: 12.0,
    projectileSize: 0.3,
    statusEffect: StatusEffect.slow,
    statusDuration: 3.0,
    statusStrength: 0.5, // 50% slow
    category: 'mage',
  );

  /// Blizzard - Channeled AoE ice storm
  static final blizzard = AbilityData(
    name: 'Blizzard',
    description: 'Summons ice storm that damages and slows enemies in area',
    type: AbilityType.channeled,
    damage: 8.0,
    cooldown: 20.0,
    duration: 4.0,
    range: 30.0,
    color: Vector3(0.6, 0.8, 1.0), // Ice blue
    impactColor: Vector3(0.8, 0.9, 1.0), // White-blue
    impactSize: 0.3,
    aoeRadius: 5.0,
    dotTicks: 8,
    statusEffect: StatusEffect.slow,
    statusDuration: 1.0,
    castTime: 1.0,
    category: 'mage',
  );

  /// Lightning Bolt - Fast high damage projectile
  static final lightningBolt = AbilityData(
    name: 'Lightning Bolt',
    description: 'Hurls a bolt of lightning at the target',
    type: AbilityType.ranged,
    damage: 30.0,
    cooldown: 4.0,
    range: 35.0,
    color: Vector3(1.0, 1.0, 0.3), // Yellow
    impactColor: Vector3(1.0, 1.0, 0.5), // Bright yellow
    impactSize: 0.6,
    projectileSpeed: 25.0,
    projectileSize: 0.2,
    castTime: 1.5,
    category: 'mage',
  );

  /// Chain Lightning - Bounces between targets
  static final chainLightning = AbilityData(
    name: 'Chain Lightning',
    description: 'Lightning that jumps between multiple enemies',
    type: AbilityType.ranged,
    damage: 20.0,
    cooldown: 8.0,
    range: 30.0,
    color: Vector3(0.8, 0.8, 1.0), // Electric blue
    impactColor: Vector3(0.9, 0.9, 1.0), // White-blue
    impactSize: 0.4,
    projectileSpeed: 30.0,
    projectileSize: 0.15,
    maxTargets: 4,
    category: 'mage',
  );

  /// Meteor - Massive AoE fire damage
  static final meteor = AbilityData(
    name: 'Meteor',
    description: 'Calls down a meteor dealing massive AoE fire damage',
    type: AbilityType.aoe,
    damage: 50.0,
    cooldown: 30.0,
    duration: 0.5,
    range: 40.0,
    color: Vector3(1.0, 0.3, 0.0), // Orange-red
    impactColor: Vector3(1.0, 0.5, 0.2), // Fiery orange
    impactSize: 2.0,
    aoeRadius: 4.0,
    statusEffect: StatusEffect.burn,
    statusDuration: 3.0,
    castTime: 2.0,
    category: 'mage',
  );

  /// Arcane Shield - Magic damage absorption
  static final arcaneShield = AbilityData(
    name: 'Arcane Shield',
    description: 'Creates a magical barrier absorbing damage',
    type: AbilityType.buff,
    cooldown: 25.0,
    duration: 8.0,
    color: Vector3(0.6, 0.3, 0.9), // Purple
    impactColor: Vector3(0.7, 0.4, 1.0), // Bright purple
    impactSize: 1.5,
    statusEffect: StatusEffect.shield,
    statusStrength: 40.0,
    category: 'mage',
  );

  /// Teleport - Short range blink
  static final teleport = AbilityData(
    name: 'Teleport',
    description: 'Instantly teleports short distance',
    type: AbilityType.utility,
    cooldown: 15.0,
    range: 10.0,
    color: Vector3(0.5, 0.2, 0.8), // Purple
    impactColor: Vector3(0.6, 0.3, 0.9), // Violet
    impactSize: 0.8,
    category: 'mage',
  );

  // ==================== ROGUE/ASSASSIN ABILITIES ====================

  /// Backstab - High damage from behind
  static final backstab = AbilityData(
    name: 'Backstab',
    description: 'Devastating attack from behind dealing extra damage',
    type: AbilityType.melee,
    damage: 40.0,
    cooldown: 6.0,
    duration: 0.2,
    range: 1.5,
    color: Vector3(0.3, 0.3, 0.3), // Dark gray
    impactColor: Vector3(0.8, 0.2, 0.2), // Blood red
    impactSize: 0.5,
    category: 'rogue',
  );

  /// Poison Blade - Attack that applies poison DoT
  static final poisonBlade = AbilityData(
    name: 'Poison Blade',
    description: 'Coats weapon in poison, dealing damage over time',
    type: AbilityType.melee,
    damage: 12.0,
    cooldown: 8.0,
    duration: 0.25,
    range: 2.0,
    color: Vector3(0.2, 0.8, 0.2), // Green
    impactColor: Vector3(0.3, 0.9, 0.3), // Bright green
    impactSize: 0.4,
    statusEffect: StatusEffect.poison,
    statusDuration: 6.0,
    dotTicks: 6,
    category: 'rogue',
  );

  /// Smoke Bomb - AoE blind effect
  static final smokeBomb = AbilityData(
    name: 'Smoke Bomb',
    description: 'Throws smoke bomb blinding enemies in area',
    type: AbilityType.debuff,
    cooldown: 18.0,
    duration: 3.0,
    range: 15.0,
    color: Vector3(0.4, 0.4, 0.4), // Gray
    impactColor: Vector3(0.5, 0.5, 0.5), // Light gray
    impactSize: 1.5,
    aoeRadius: 4.0,
    statusEffect: StatusEffect.blind,
    statusDuration: 3.0,
    category: 'rogue',
  );

  /// Fan of Knives - Throws daggers in all directions
  static final fanOfKnives = AbilityData(
    name: 'Fan of Knives',
    description: 'Throws daggers in all directions hitting nearby enemies',
    type: AbilityType.aoe,
    damage: 15.0,
    cooldown: 10.0,
    duration: 0.3,
    range: 6.0,
    color: Vector3(0.7, 0.7, 0.7), // Silver
    impactColor: Vector3(0.8, 0.8, 0.8), // Light gray
    impactSize: 0.3,
    aoeRadius: 6.0,
    maxTargets: 8,
    category: 'rogue',
  );

  /// Shadow Step - Teleport behind target
  static final shadowStep = AbilityData(
    name: 'Shadow Step',
    description: 'Teleports behind the target enemy',
    type: AbilityType.utility,
    cooldown: 20.0,
    range: 20.0,
    color: Vector3(0.2, 0.1, 0.3), // Dark purple
    impactColor: Vector3(0.3, 0.2, 0.4), // Shadow purple
    impactSize: 0.6,
    category: 'rogue',
  );

  // ==================== HEALER/SUPPORT ABILITIES ====================

  /// Holy Light - Single target heal
  static final holyLight = AbilityData(
    name: 'Holy Light',
    description: 'Powerful healing spell for a single target',
    type: AbilityType.heal,
    cooldown: 4.0,
    duration: 0.5,
    range: 30.0,
    healAmount: 35.0,
    color: Vector3(1.0, 1.0, 0.6), // Golden yellow
    impactColor: Vector3(1.0, 1.0, 0.8), // Bright gold
    impactSize: 1.0,
    castTime: 1.5,
    category: 'healer',
  );

  /// Rejuvenation - Heal over time
  static final rejuvenation = AbilityData(
    name: 'Rejuvenation',
    description: 'Restores health gradually over time',
    type: AbilityType.heal,
    cooldown: 6.0,
    duration: 8.0,
    range: 30.0,
    healAmount: 40.0, // Total over duration
    color: Vector3(0.4, 1.0, 0.4), // Green
    impactColor: Vector3(0.5, 1.0, 0.5), // Bright green
    impactSize: 0.8,
    statusEffect: StatusEffect.regen,
    dotTicks: 8,
    category: 'healer',
  );

  /// Circle of Healing - AoE heal
  static final circleOfHealing = AbilityData(
    name: 'Circle of Healing',
    description: 'Heals all allies in a radius',
    type: AbilityType.heal,
    cooldown: 15.0,
    duration: 0.5,
    range: 25.0,
    healAmount: 20.0,
    color: Vector3(0.8, 1.0, 0.5), // Yellow-green
    impactColor: Vector3(0.9, 1.0, 0.6), // Bright yellow-green
    impactSize: 1.8,
    aoeRadius: 8.0,
    maxTargets: 5,
    category: 'healer',
  );

  /// Blessing of Strength - Damage buff
  static final blessingOfStrength = AbilityData(
    name: 'Blessing of Strength',
    description: 'Increases ally damage output',
    type: AbilityType.buff,
    cooldown: 20.0,
    duration: 15.0,
    range: 30.0,
    color: Vector3(1.0, 0.6, 0.2), // Orange
    impactColor: Vector3(1.0, 0.7, 0.3), // Bright orange
    impactSize: 1.0,
    statusEffect: StatusEffect.strength,
    statusStrength: 1.25, // 25% damage increase
    category: 'healer',
  );

  /// Purify - Removes debuffs
  static final purify = AbilityData(
    name: 'Purify',
    description: 'Removes harmful effects from ally',
    type: AbilityType.buff,
    cooldown: 8.0,
    range: 30.0,
    color: Vector3(1.0, 1.0, 1.0), // White
    impactColor: Vector3(1.0, 1.0, 0.9), // Bright white
    impactSize: 1.0,
    category: 'healer',
  );

  // ==================== NATURE/DRUID ABILITIES ====================

  /// Entangling Roots - Root enemies in place
  static final entanglingRoots = AbilityData(
    name: 'Entangling Roots',
    description: 'Roots enemy in place, preventing movement',
    type: AbilityType.debuff,
    damage: 5.0,
    cooldown: 12.0,
    duration: 4.0,
    range: 25.0,
    color: Vector3(0.4, 0.6, 0.2), // Brown-green
    impactColor: Vector3(0.5, 0.7, 0.3), // Forest green
    impactSize: 0.8,
    statusEffect: StatusEffect.root,
    statusDuration: 4.0,
    category: 'nature',
  );

  /// Thorns - Reflect damage buff
  static final thorns = AbilityData(
    name: 'Thorns',
    description: 'Attackers take damage when hitting the target',
    type: AbilityType.buff,
    cooldown: 30.0,
    duration: 20.0,
    damage: 5.0, // Damage reflected per hit
    color: Vector3(0.3, 0.5, 0.2), // Dark green
    impactColor: Vector3(0.4, 0.6, 0.3), // Green
    impactSize: 1.0,
    category: 'nature',
  );

  /// Nature's Wrath - AoE nature damage
  static final naturesWrath = AbilityData(
    name: "Nature's Wrath",
    description: 'Unleashes the fury of nature on enemies',
    type: AbilityType.aoe,
    damage: 25.0,
    cooldown: 14.0,
    duration: 0.8,
    range: 20.0,
    color: Vector3(0.5, 0.8, 0.3), // Bright green
    impactColor: Vector3(0.6, 0.9, 0.4), // Light green
    impactSize: 1.2,
    aoeRadius: 5.0,
    category: 'nature',
  );

  // ==================== NECROMANCER/DARK ABILITIES ====================

  /// Life Drain - Damage and heal
  static final lifeDrain = AbilityData(
    name: 'Life Drain',
    description: 'Drains life from enemy, healing self',
    type: AbilityType.channeled,
    damage: 6.0,
    cooldown: 10.0,
    duration: 3.0,
    range: 20.0,
    healAmount: 4.0, // Per tick
    color: Vector3(0.5, 0.0, 0.2), // Dark red
    impactColor: Vector3(0.6, 0.1, 0.3), // Blood red
    impactSize: 0.5,
    dotTicks: 6,
    category: 'necromancer',
  );

  /// Curse of Weakness - Reduce enemy damage
  static final curseOfWeakness = AbilityData(
    name: 'Curse of Weakness',
    description: 'Curses enemy, reducing their damage output',
    type: AbilityType.debuff,
    cooldown: 16.0,
    duration: 10.0,
    range: 30.0,
    color: Vector3(0.3, 0.0, 0.3), // Dark purple
    impactColor: Vector3(0.4, 0.1, 0.4), // Purple
    impactSize: 0.8,
    statusEffect: StatusEffect.weakness,
    statusStrength: 0.75, // 25% damage reduction
    category: 'necromancer',
  );

  /// Fear - Makes enemy flee
  static final fear = AbilityData(
    name: 'Fear',
    description: 'Terrifies enemy, causing them to flee',
    type: AbilityType.debuff,
    cooldown: 20.0,
    duration: 4.0,
    range: 20.0,
    color: Vector3(0.2, 0.0, 0.2), // Dark purple
    impactColor: Vector3(0.3, 0.0, 0.3), // Violet
    impactSize: 0.7,
    statusEffect: StatusEffect.stun, // Using stun as fear equivalent
    statusDuration: 4.0,
    category: 'necromancer',
  );

  /// Summon Skeleton - Creates temporary ally
  static final summonSkeleton = AbilityData(
    name: 'Summon Skeleton',
    description: 'Raises a skeleton warrior to fight for you',
    type: AbilityType.summon,
    cooldown: 25.0,
    duration: 30.0, // Skeleton lasts 30 seconds
    color: Vector3(0.8, 0.8, 0.7), // Bone white
    impactColor: Vector3(0.9, 0.9, 0.8), // Off-white
    impactSize: 1.0,
    category: 'necromancer',
  );

  // ==================== ELEMENTAL RANGED ABILITIES ====================

  /// Ice Lance - Piercing ice projectile
  static final iceLance = AbilityData(
    name: 'Ice Lance',
    description: 'Sharp ice projectile that pierces through enemies',
    type: AbilityType.ranged,
    damage: 18.0,
    cooldown: 3.0,
    range: 45.0,
    color: Vector3(0.7, 0.9, 1.0), // Light blue
    impactColor: Vector3(0.8, 1.0, 1.0), // White-blue
    impactSize: 0.4,
    projectileSpeed: 18.0,
    projectileSize: 0.2,
    piercing: true,
    maxTargets: 3,
    category: 'elemental',
  );

  /// Flame Wave - Line AoE fire attack
  static final flameWave = AbilityData(
    name: 'Flame Wave',
    description: 'Sends a wave of fire in a line',
    type: AbilityType.aoe,
    damage: 22.0,
    cooldown: 7.0,
    duration: 0.6,
    range: 12.0,
    color: Vector3(1.0, 0.5, 0.1), // Orange-red
    impactColor: Vector3(1.0, 0.6, 0.2), // Flame orange
    impactSize: 0.8,
    aoeRadius: 2.0,
    statusEffect: StatusEffect.burn,
    statusDuration: 2.0,
    category: 'elemental',
  );

  /// Earthquake - Ground AoE with stun
  static final earthquake = AbilityData(
    name: 'Earthquake',
    description: 'Shakes the ground, damaging and stunning enemies',
    type: AbilityType.channeled,
    damage: 10.0,
    cooldown: 25.0,
    duration: 3.0,
    range: 15.0,
    color: Vector3(0.6, 0.4, 0.2), // Brown
    impactColor: Vector3(0.7, 0.5, 0.3), // Tan
    impactSize: 1.5,
    aoeRadius: 8.0,
    dotTicks: 6,
    statusEffect: StatusEffect.stun,
    statusDuration: 0.5,
    castTime: 1.0,
    category: 'elemental',
  );

  // ==================== UTILITY/MOVEMENT ABILITIES ====================

  /// Sprint - Movement speed buff
  static final sprint = AbilityData(
    name: 'Sprint',
    description: 'Greatly increases movement speed temporarily',
    type: AbilityType.buff,
    cooldown: 30.0,
    duration: 8.0,
    color: Vector3(0.9, 0.9, 0.3), // Yellow
    impactColor: Vector3(1.0, 1.0, 0.5), // Bright yellow
    impactSize: 0.6,
    statusEffect: StatusEffect.haste,
    statusStrength: 1.5, // 50% speed increase
    category: 'utility',
  );

  /// Battle Shout - AoE damage buff for allies
  static final battleShout = AbilityData(
    name: 'Battle Shout',
    description: 'Boosts damage of all nearby allies',
    type: AbilityType.buff,
    cooldown: 45.0,
    duration: 20.0,
    color: Vector3(1.0, 0.4, 0.2), // Red-orange
    impactColor: Vector3(1.0, 0.5, 0.3), // Orange
    impactSize: 1.5,
    aoeRadius: 10.0,
    statusEffect: StatusEffect.strength,
    statusStrength: 1.15, // 15% damage increase
    maxTargets: 5,
    category: 'utility',
  );

  // ==================== LISTS OF POTENTIAL ABILITIES ====================

  /// All potential future abilities (not yet assigned)
  static List<AbilityData> get potentialAbilities => [
    // Warrior
    shieldBash, whirlwind, charge, taunt, fortify,
    // Mage
    frostBolt, blizzard, lightningBolt, chainLightning, meteor, arcaneShield, teleport,
    // Rogue
    backstab, poisonBlade, smokeBomb, fanOfKnives, shadowStep,
    // Healer
    holyLight, rejuvenation, circleOfHealing, blessingOfStrength, purify,
    // Nature
    entanglingRoots, thorns, naturesWrath,
    // Necromancer
    lifeDrain, curseOfWeakness, fear, summonSkeleton,
    // Elemental
    iceLance, flameWave, earthquake,
    // Utility
    sprint, battleShout,
  ];

  /// Get abilities by category
  static List<AbilityData> getAbilitiesByCategory(String category) {
    return potentialAbilities.where((a) => a.category == category).toList();
  }

  /// All ability categories
  static List<String> get categories => [
    'warrior',
    'mage',
    'rogue',
    'healer',
    'nature',
    'necromancer',
    'elemental',
    'utility',
  ];
}
