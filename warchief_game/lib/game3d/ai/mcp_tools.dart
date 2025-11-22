import 'package:vector_math/vector_math.dart';
import 'dart:math' as math;
import '../state/game_state.dart';
import '../state/game_config.dart';
import '../utils/movement_prediction.dart';
import '../utils/bezier_path.dart';

/// MCP Tool Response - Result from an MCP tool execution
class MCPToolResponse {
  final String action;
  final Map<String, dynamic> parameters;
  final double confidence; // 0.0 to 1.0
  final String reasoning;

  MCPToolResponse({
    required this.action,
    this.parameters = const {},
    this.confidence = 1.0,
    this.reasoning = '',
  });
}

/// AI Context - Information available to AI tools
class AIContext {
  final Vector3 selfPosition;
  final Vector3? playerPosition;
  final Vector3? playerVelocity;
  final double distanceToPlayer;
  final double selfHealth;
  final double selfMaxHealth;
  final double playerHealth;
  final List<AllyContext> allies;
  final Map<String, double> abilityCooldowns;
  final double? currentSpeed;
  final Vector3? currentVelocity;

  AIContext({
    required this.selfPosition,
    this.playerPosition,
    this.playerVelocity,
    required this.distanceToPlayer,
    required this.selfHealth,
    required this.selfMaxHealth,
    required this.playerHealth,
    this.allies = const [],
    this.abilityCooldowns = const {},
    this.currentSpeed,
    this.currentVelocity,
  });
}

/// Ally Context - Information about allies
class AllyContext {
  final Vector3 position;
  final double health;
  final double distanceToSelf;

  AllyContext({
    required this.position,
    required this.health,
    required this.distanceToSelf,
  });
}

/// MCP Tools - AI decision-making tools with different response times
///
/// This class provides different "tools" that the AI can use to make decisions:
/// - Tactical tools: Fast, reactive decisions (< 100ms)
/// - Strategic tools: Slower, thoughtful planning (1-2s)
/// - Movement tools: Pathfinding and positioning
/// - Combat tools: Targeting and ability selection
class MCPTools {
  MCPTools._(); // Private constructor

  // ==================== TACTICAL TOOLS (REAL-TIME) ====================

  /// Rapid threat assessment - Immediate danger response
  ///
  /// Used for quick reactions to incoming threats
  static MCPToolResponse assessThreat(AIContext context) {
    // Critical health check
    final healthPercent = context.selfHealth / context.selfMaxHealth;

    if (healthPercent < 0.3) {
      return MCPToolResponse(
        action: 'RETREAT_URGENT',
        parameters: {'reason': 'critical_health'},
        confidence: 0.95,
        reasoning: 'Health below 30%, immediate retreat required',
      );
    }

    // Close-range threat
    if (context.distanceToPlayer < 2.0) {
      return MCPToolResponse(
        action: 'MELEE_DEFENSE',
        parameters: {'distance': context.distanceToPlayer},
        confidence: 0.85,
        reasoning: 'Player in melee range, defensive posture',
      );
    }

    // No immediate threat
    return MCPToolResponse(
      action: 'CONTINUE',
      confidence: 0.7,
      reasoning: 'No immediate threats detected',
    );
  }

  /// Quick ability selection based on current state
  static MCPToolResponse selectQuickAbility(AIContext context) {
    // Check available abilities
    final abilities = <String>[];

    context.abilityCooldowns.forEach((ability, cooldown) {
      if (cooldown <= 0) {
        abilities.add(ability);
      }
    });

    if (abilities.isEmpty) {
      return MCPToolResponse(
        action: 'WAIT',
        reasoning: 'All abilities on cooldown',
      );
    }

    // Range-based ability selection
    if (context.distanceToPlayer < 3.0 && abilities.contains('ability1')) {
      return MCPToolResponse(
        action: 'USE_ABILITY',
        parameters: {'ability': 'ability1'},
        confidence: 0.9,
        reasoning: 'Melee range - use ability 1',
      );
    }

    if (context.distanceToPlayer > 5.0 && abilities.contains('ability2')) {
      return MCPToolResponse(
        action: 'USE_ABILITY',
        parameters: {'ability': 'ability2'},
        confidence: 0.85,
        reasoning: 'Long range - use ability 2',
      );
    }

    return MCPToolResponse(
      action: 'HOLD',
      reasoning: 'No optimal ability for current range',
    );
  }

  // ==================== STRATEGIC TOOLS (PLANNING) ====================

  /// Comprehensive combat strategy analysis
  static MCPToolResponse planCombatStrategy(AIContext context) {
    final healthPercent = context.selfHealth / context.selfMaxHealth;
    final playerHealthPercent = context.playerHealth / 100.0; // Assuming max 100

    // Defensive strategy if low health
    if (healthPercent < 0.5) {
      return MCPToolResponse(
        action: 'DEFENSIVE_STRATEGY',
        parameters: {
          'preferredRange': 'medium',
          'priority': 'survival',
          'useHealingAbilities': true,
        },
        confidence: 0.9,
        reasoning: 'Low health: Prioritize defense and healing',
      );
    }

    // Aggressive strategy if player is low health
    if (playerHealthPercent < 0.4 && healthPercent > 0.6) {
      return MCPToolResponse(
        action: 'AGGRESSIVE_STRATEGY',
        parameters: {
          'preferredRange': 'close',
          'priority': 'pressure',
          'useAllAbilities': true,
        },
        confidence: 0.95,
        reasoning: 'Player low health, we have advantage: Press the attack',
      );
    }

    // Balanced strategy
    return MCPToolResponse(
      action: 'BALANCED_STRATEGY',
      parameters: {
        'preferredRange': 'medium',
        'priority': 'opportunistic',
      },
      confidence: 0.75,
      reasoning: 'Both combatants healthy: Balanced approach',
    );
  }

  /// Analyze positioning opportunities
  static MCPToolResponse analyzepositioning(AIContext context) {
    // Check ally positioning for flanking opportunities
    if (context.allies.length > 0) {
      final closestAlly = context.allies.reduce((a, b) =>
        a.distanceToSelf < b.distanceToSelf ? a : b
      );

      if (closestAlly.distanceToSelf < 8.0) {
        return MCPToolResponse(
          action: 'COORDINATE_ATTACK',
          parameters: {'allyPosition': closestAlly.position},
          confidence: 0.8,
          reasoning: 'Ally nearby: Coordinate for flanking',
        );
      }
    }

    // Analyze optimal combat range
    final optimalRange = _calculateOptimalRange(context);
    final currentInOptimal = (context.distanceToPlayer - optimalRange).abs() < 2.0;

    if (!currentInOptimal) {
      return MCPToolResponse(
        action: 'REPOSITION',
        parameters: {
          'targetRange': optimalRange,
          'urgency': 'medium',
        },
        confidence: 0.7,
        reasoning: 'Not at optimal range: Reposition to $optimalRange units',
      );
    }

    return MCPToolResponse(
      action: 'MAINTAIN_POSITION',
      confidence: 0.8,
      reasoning: 'Currently at optimal range',
    );
  }

  // ==================== MOVEMENT TOOLS ====================

  /// Calculate intercept path to predicted player position
  static BezierPath? calculateInterceptPath({
    required Vector3 currentPosition,
    required Vector3 targetPosition,
    required Vector3? targetVelocity,
    required Vector3? currentVelocity,
    required double interceptorSpeed,
  }) {
    // Predict where player will be
    Vector3 predictedPosition = targetPosition;

    if (targetVelocity != null && targetVelocity.length > 0.01) {
      // Calculate time to reach target
      final distanceToTarget = (targetPosition - currentPosition).length;
      final timeToReach = distanceToTarget / interceptorSpeed;

      // Predict player position at intercept time
      predictedPosition = targetPosition + targetVelocity * timeToReach;
    }

    // Create smooth Bezier path for interception
    return BezierPath.interception(
      start: currentPosition,
      target: predictedPosition,
      velocity: currentVelocity,
    );
  }

  /// Calculate strafing path (circle around target)
  static BezierPath calculateStrafePath({
    required Vector3 currentPosition,
    required Vector3 targetPosition,
    required double radius,
    required bool clockwise,
  }) {
    final toTarget = targetPosition - currentPosition;
    final currentAngle = math.atan2(toTarget.x, toTarget.z);

    // Calculate strafe angle (90 degrees perpendicular)
    final strafeAngle = currentAngle + (clockwise ? math.pi / 2 : -math.pi / 2);

    // Create arc path around target
    final control1 = currentPosition +
      Vector3(math.sin(strafeAngle), 0, math.cos(strafeAngle)) * 2.0;

    final endAngle = currentAngle + (clockwise ? math.pi / 4 : -math.pi / 4);
    final endPosition = targetPosition +
      Vector3(math.sin(endAngle), 0, math.cos(endAngle)) * radius;

    return BezierPath.cubic(
      start: currentPosition,
      control1: control1,
      control2: endPosition + Vector3(0, 0, 1),
      end: endPosition,
    );
  }

  // ==================== COMBAT TOOLS ====================

  /// Evaluate ability effectiveness at current range and state
  static Map<String, double> evaluateAbilityEffectiveness(AIContext context) {
    final effectiveness = <String, double>{};

    // Ability 1 (Melee) - most effective at close range
    effectiveness['ability1'] = _evaluateMeleeEffectiveness(context.distanceToPlayer);

    // Ability 2 (Ranged) - most effective at medium-long range
    effectiveness['ability2'] = _evaluateRangedEffectiveness(context.distanceToPlayer);

    // Ability 3 (Utility/Heal) - based on health
    effectiveness['ability3'] = _evaluateUtilityEffectiveness(context.selfHealth, context.selfMaxHealth);

    return effectiveness;
  }

  // ==================== HELPER FUNCTIONS ====================

  static double _calculateOptimalRange(AIContext context) {
    // Analyze available abilities and health to determine best range
    final healthPercent = context.selfHealth / context.selfMaxHealth;

    if (healthPercent < 0.5) {
      return 8.0; // Maintain distance if low health
    }

    if (healthPercent > 0.7) {
      return 4.0; // Close in if healthy
    }

    return 6.0; // Medium range default
  }

  static double _evaluateMeleeEffectiveness(double distance) {
    // Melee is most effective at close range (< 3.0)
    if (distance < 3.0) return 0.9;
    if (distance < 5.0) return 0.4;
    return 0.1;
  }

  static double _evaluateRangedEffectiveness(double distance) {
    // Ranged is most effective at medium-long range (5.0 - 12.0)
    if (distance < 3.0) return 0.3;
    if (distance < 8.0) return 0.9;
    if (distance < 15.0) return 0.7;
    return 0.4;
  }

  static double _evaluateUtilityEffectiveness(double health, double maxHealth) {
    final healthPercent = health / maxHealth;
    // Utility/heal is more effective when health is low
    if (healthPercent < 0.3) return 0.95;
    if (healthPercent < 0.5) return 0.7;
    if (healthPercent < 0.7) return 0.4;
    return 0.1;
  }
}
