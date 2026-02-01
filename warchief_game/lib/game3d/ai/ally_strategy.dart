/// Ally Strategy System
///
/// Defines configurable strategies that control ally behavior weights
/// and decision-making preferences. Players can assign different strategies
/// to each ally to customize their playstyle.

/// Strategy types available for allies
enum AllyStrategyType {
  aggressive,  // Focus on dealing damage, close to enemy
  defensive,   // Protect self and player, stay safe
  balanced,    // Equal priority on all actions
  support,     // Prioritize healing and staying back
  berserker,   // All-out attack, ignore safety
}

/// Strategy configuration with behavior weights and parameters
class AllyStrategy {
  final AllyStrategyType type;
  final String name;
  final String description;

  // Behavior weights (1.0 = normal, >1 = prioritize, <1 = deprioritize)
  final double attackWeight;      // How eager to attack
  final double defenseWeight;     // How much to prioritize safety
  final double supportWeight;     // How much to help/heal
  final double followWeight;      // How closely to follow player

  // Distance preferences
  final double preferredRange;    // Ideal distance from enemy
  final double followDistance;    // Distance to maintain from player
  final double engageDistance;    // Distance to start attacking

  // Threshold parameters
  final double healThreshold;     // Health % to trigger self-heal
  final double retreatThreshold;  // Health % to retreat
  final double aggressiveThreshold; // Health % enemy must be below to chase

  // Behavior flags
  final bool allowMeleeIfRanged;  // Can ranged allies melee when close?
  final bool chaseEnemy;          // Will chase fleeing enemies?
  final bool protectPlayer;       // Stay near player when they're hurt?

  const AllyStrategy({
    required this.type,
    required this.name,
    required this.description,
    this.attackWeight = 1.0,
    this.defenseWeight = 1.0,
    this.supportWeight = 1.0,
    this.followWeight = 1.0,
    this.preferredRange = 5.0,
    this.followDistance = 4.0,
    this.engageDistance = 12.0,
    this.healThreshold = 0.4,
    this.retreatThreshold = 0.2,
    this.aggressiveThreshold = 0.3,
    this.allowMeleeIfRanged = false,
    this.chaseEnemy = true,
    this.protectPlayer = true,
  });

  /// Get color associated with this strategy (for UI)
  int get color {
    switch (type) {
      case AllyStrategyType.aggressive:
        return 0xFFFF4444; // Red
      case AllyStrategyType.defensive:
        return 0xFF4488FF; // Blue
      case AllyStrategyType.balanced:
        return 0xFF44FF44; // Green
      case AllyStrategyType.support:
        return 0xFFFFFF44; // Yellow
      case AllyStrategyType.berserker:
        return 0xFFFF8800; // Orange
    }
  }

  /// Get short label for UI display
  String get shortLabel {
    switch (type) {
      case AllyStrategyType.aggressive:
        return 'AGG';
      case AllyStrategyType.defensive:
        return 'DEF';
      case AllyStrategyType.balanced:
        return 'BAL';
      case AllyStrategyType.support:
        return 'SUP';
      case AllyStrategyType.berserker:
        return 'BER';
    }
  }
}

/// Pre-defined strategy configurations
class AllyStrategies {
  AllyStrategies._(); // Private constructor

  /// Aggressive - Focus on damage, get close to enemy
  static const aggressive = AllyStrategy(
    type: AllyStrategyType.aggressive,
    name: 'Aggressive',
    description: 'Prioritize dealing damage. Stays close to enemies.',
    attackWeight: 1.5,
    defenseWeight: 0.5,
    supportWeight: 0.5,
    followWeight: 0.3,
    preferredRange: 3.0,      // Get close
    followDistance: 6.0,      // Don't stick to player
    engageDistance: 15.0,     // Engage from further away
    healThreshold: 0.25,      // Only heal when very low
    retreatThreshold: 0.1,    // Rarely retreat
    aggressiveThreshold: 0.5, // Chase wounded enemies
    allowMeleeIfRanged: true, // Ranged can melee
    chaseEnemy: true,
    protectPlayer: false,
  );

  /// Defensive - Stay safe, protect self and player
  static const defensive = AllyStrategy(
    type: AllyStrategyType.defensive,
    name: 'Defensive',
    description: 'Prioritize survival. Stays near player for protection.',
    attackWeight: 0.6,
    defenseWeight: 1.5,
    supportWeight: 1.2,
    followWeight: 1.3,
    preferredRange: 8.0,      // Keep distance
    followDistance: 3.0,      // Stay close to player
    engageDistance: 8.0,      // Only attack when close
    healThreshold: 0.6,       // Heal early
    retreatThreshold: 0.35,   // Retreat when hurt
    aggressiveThreshold: 0.1, // Don't chase
    allowMeleeIfRanged: false,
    chaseEnemy: false,
    protectPlayer: true,
  );

  /// Balanced - Equal priority on all actions
  static const balanced = AllyStrategy(
    type: AllyStrategyType.balanced,
    name: 'Balanced',
    description: 'Well-rounded behavior. Adapts to the situation.',
    attackWeight: 1.0,
    defenseWeight: 1.0,
    supportWeight: 1.0,
    followWeight: 1.0,
    preferredRange: 5.0,
    followDistance: 4.0,
    engageDistance: 10.0,
    healThreshold: 0.4,
    retreatThreshold: 0.2,
    aggressiveThreshold: 0.3,
    allowMeleeIfRanged: false,
    chaseEnemy: true,
    protectPlayer: true,
  );

  /// Support - Focus on healing, stay back
  static const support = AllyStrategy(
    type: AllyStrategyType.support,
    name: 'Support',
    description: 'Prioritize healing and staying safe. Ranged attacks only.',
    attackWeight: 0.4,
    defenseWeight: 1.3,
    supportWeight: 2.0,
    followWeight: 1.2,
    preferredRange: 10.0,     // Stay far back
    followDistance: 5.0,      // Near but not too close
    engageDistance: 12.0,
    healThreshold: 0.7,       // Heal very early
    retreatThreshold: 0.4,    // Retreat early
    aggressiveThreshold: 0.0, // Never chase
    allowMeleeIfRanged: false,
    chaseEnemy: false,
    protectPlayer: true,
  );

  /// Berserker - All-out attack, ignore safety
  static const berserker = AllyStrategy(
    type: AllyStrategyType.berserker,
    name: 'Berserker',
    description: 'Relentless aggression. Never retreats, rarely heals.',
    attackWeight: 2.0,
    defenseWeight: 0.2,
    supportWeight: 0.2,
    followWeight: 0.1,
    preferredRange: 2.0,      // In their face
    followDistance: 10.0,     // Independent
    engageDistance: 20.0,     // Engage from anywhere
    healThreshold: 0.1,       // Almost never heal
    retreatThreshold: 0.0,    // Never retreat
    aggressiveThreshold: 1.0, // Always chase
    allowMeleeIfRanged: true,
    chaseEnemy: true,
    protectPlayer: false,
  );

  /// Get strategy by type
  static AllyStrategy getStrategy(AllyStrategyType type) {
    switch (type) {
      case AllyStrategyType.aggressive:
        return aggressive;
      case AllyStrategyType.defensive:
        return defensive;
      case AllyStrategyType.balanced:
        return balanced;
      case AllyStrategyType.support:
        return support;
      case AllyStrategyType.berserker:
        return berserker;
    }
  }

  /// List of all strategies for UI display
  static List<AllyStrategy> get allStrategies => [
    balanced,     // Default first
    aggressive,
    defensive,
    support,
    berserker,
  ];

  /// Get strategy names for dropdown
  static List<String> get strategyNames =>
      allStrategies.map((s) => s.name).toList();
}
