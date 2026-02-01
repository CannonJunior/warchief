import 'package:vector_math/vector_math.dart';
import 'dart:math' as math;

import '../state/game_state.dart';
import '../../models/ally.dart';
import 'ally_strategy.dart';

/// Formation types for ally positioning
enum FormationType {
  scattered,  // Default - each ally picks own position
  wedge,      // V-shape behind player
  line,       // Side-by-side facing enemy
  surround,   // Circle the enemy
  protect,    // Circle the player
}

/// Combat role based on ally's ability
enum CombatRole {
  melee,    // Sword users - get close, flank
  ranged,   // Fireball users - stay back, spread out
  support,  // Healers - stay safe, near allies
}

/// Tactical position assignment for an ally
class TacticalPosition {
  final Vector3 position;
  final double facingAngle;  // Angle to face (degrees)
  final CombatRole role;
  final double priority;      // Higher = more important to reach

  TacticalPosition({
    required this.position,
    required this.facingAngle,
    required this.role,
    this.priority = 1.0,
  });
}

/// Tactical Positioning System
///
/// Calculates optimal positions for allies based on:
/// - Current formation type
/// - Ally combat roles (melee/ranged/support)
/// - Enemy position
/// - Player position
/// - Other ally positions (avoid clumping)
class TacticalPositioning {
  TacticalPositioning._(); // Private constructor

  /// Minimum distance between allies to avoid clumping
  static const double minAllySpacing = 2.0;

  /// Get combat role for an ally based on ability
  static CombatRole getAllyRole(Ally ally) {
    switch (ally.abilityIndex) {
      case 0:
        return CombatRole.melee;
      case 1:
        return CombatRole.ranged;
      case 2:
        return CombatRole.support;
      default:
        return CombatRole.melee;
    }
  }

  /// Calculate tactical positions for all allies
  ///
  /// Returns a map of ally to their assigned tactical position
  static Map<Ally, TacticalPosition> calculatePositions(
    GameState gameState,
    FormationType formation,
  ) {
    final positions = <Ally, TacticalPosition>{};
    final allies = gameState.allies.where((a) => a.health > 0).toList();

    if (allies.isEmpty) return positions;

    final playerPos = gameState.playerTransform?.position ?? Vector3.zero();
    final monsterPos = gameState.monsterTransform?.position;
    final monsterAlive = gameState.monsterHealth > 0;

    // Calculate positions based on formation
    switch (formation) {
      case FormationType.scattered:
        _calculateScatteredPositions(positions, allies, playerPos, monsterPos, monsterAlive);
        break;
      case FormationType.wedge:
        _calculateWedgePositions(positions, allies, playerPos, monsterPos);
        break;
      case FormationType.line:
        _calculateLinePositions(positions, allies, playerPos, monsterPos);
        break;
      case FormationType.surround:
        _calculateSurroundPositions(positions, allies, playerPos, monsterPos, monsterAlive);
        break;
      case FormationType.protect:
        _calculateProtectPositions(positions, allies, playerPos);
        break;
    }

    return positions;
  }

  /// Scattered formation - role-based individual positioning
  static void _calculateScatteredPositions(
    Map<Ally, TacticalPosition> positions,
    List<Ally> allies,
    Vector3 playerPos,
    Vector3? monsterPos,
    bool monsterAlive,
  ) {
    for (final ally in allies) {
      final role = getAllyRole(ally);
      final strategy = ally.strategy;

      Vector3 targetPos;
      double facingAngle;

      if (monsterAlive && monsterPos != null) {
        // Combat positioning
        switch (role) {
          case CombatRole.melee:
            // Flank the monster - position to the side
            targetPos = _calculateFlankPosition(
              ally, allies, monsterPos, playerPos, strategy.preferredRange);
            break;
          case CombatRole.ranged:
            // Stay back at range
            targetPos = _calculateRangedPosition(
              ally, allies, monsterPos, playerPos, strategy.preferredRange);
            break;
          case CombatRole.support:
            // Stay between player and monster, closer to player
            targetPos = _calculateSupportPosition(
              ally, allies, monsterPos, playerPos, strategy.followDistance);
            break;
        }
        // Face the monster
        final toMonster = monsterPos - targetPos;
        facingAngle = math.atan2(-toMonster.x, -toMonster.z) * (180 / math.pi);
      } else {
        // Non-combat - stay near player
        targetPos = _calculateIdlePosition(ally, allies, playerPos, strategy.followDistance);
        facingAngle = 0;
      }

      positions[ally] = TacticalPosition(
        position: targetPos,
        facingAngle: facingAngle,
        role: role,
        priority: role == CombatRole.melee ? 1.2 : 1.0,
      );
    }
  }

  /// Wedge formation - V-shape behind player
  static void _calculateWedgePositions(
    Map<Ally, TacticalPosition> positions,
    List<Ally> allies,
    Vector3 playerPos,
    Vector3? monsterPos,
  ) {
    // Direction player is facing (toward monster or default forward)
    Vector3 forward;
    if (monsterPos != null) {
      forward = (monsterPos - playerPos).normalized();
    } else {
      forward = Vector3(0, 0, -1);
    }

    // Perpendicular direction for spreading
    final right = Vector3(-forward.z, 0, forward.x);

    final spacing = 2.5;
    final backDistance = 3.0;

    for (int i = 0; i < allies.length; i++) {
      final ally = allies[i];
      final role = getAllyRole(ally);

      // Alternate left and right, increasing distance
      final side = (i % 2 == 0) ? 1.0 : -1.0;
      final row = (i ~/ 2) + 1;

      final offset = -forward * (backDistance + row * 1.5) + right * (side * spacing * row);
      final targetPos = playerPos + offset;

      // Face forward (toward monster direction)
      final facingAngle = math.atan2(-forward.x, -forward.z) * (180 / math.pi);

      positions[ally] = TacticalPosition(
        position: targetPos,
        facingAngle: facingAngle,
        role: role,
      );
    }
  }

  /// Line formation - side by side facing enemy
  static void _calculateLinePositions(
    Map<Ally, TacticalPosition> positions,
    List<Ally> allies,
    Vector3 playerPos,
    Vector3? monsterPos,
  ) {
    Vector3 forward;
    if (monsterPos != null) {
      forward = (monsterPos - playerPos).normalized();
    } else {
      forward = Vector3(0, 0, -1);
    }

    final right = Vector3(-forward.z, 0, forward.x);
    final spacing = 2.0;
    final lineDistance = 2.0; // Distance behind player

    // Sort allies by role: melee in front
    final sortedAllies = List<Ally>.from(allies);
    sortedAllies.sort((a, b) {
      final roleA = getAllyRole(a);
      final roleB = getAllyRole(b);
      if (roleA == CombatRole.melee && roleB != CombatRole.melee) return -1;
      if (roleA != CombatRole.melee && roleB == CombatRole.melee) return 1;
      return 0;
    });

    final centerOffset = (sortedAllies.length - 1) / 2.0;

    for (int i = 0; i < sortedAllies.length; i++) {
      final ally = sortedAllies[i];
      final role = getAllyRole(ally);

      // Spread along the line
      final sideOffset = (i - centerOffset) * spacing;
      final rowOffset = role == CombatRole.melee ? 0.0 : -2.0; // Ranged/support behind

      final offset = -forward * (lineDistance + rowOffset) + right * sideOffset;
      final targetPos = playerPos + offset;

      final facingAngle = math.atan2(-forward.x, -forward.z) * (180 / math.pi);

      positions[ally] = TacticalPosition(
        position: targetPos,
        facingAngle: facingAngle,
        role: role,
      );
    }
  }

  /// Surround formation - circle the enemy
  static void _calculateSurroundPositions(
    Map<Ally, TacticalPosition> positions,
    List<Ally> allies,
    Vector3 playerPos,
    Vector3? monsterPos,
    bool monsterAlive,
  ) {
    if (!monsterAlive || monsterPos == null) {
      // Fall back to protect formation if no enemy
      _calculateProtectPositions(positions, allies, playerPos);
      return;
    }

    final surroundRadius = 4.0;
    final angleStep = (2 * math.pi) / (allies.length + 1); // +1 to leave gap for player

    // Player's angle relative to monster
    final toPlayer = playerPos - monsterPos;
    final playerAngle = math.atan2(toPlayer.x, toPlayer.z);

    for (int i = 0; i < allies.length; i++) {
      final ally = allies[i];
      final role = getAllyRole(ally);

      // Distribute around monster, offset from player's position
      final angle = playerAngle + angleStep * (i + 1);

      // Adjust radius based on role
      double radius = surroundRadius;
      if (role == CombatRole.melee) {
        radius = 2.5; // Melee gets closer
      } else if (role == CombatRole.ranged) {
        radius = 6.0; // Ranged stays back
      }

      final targetPos = Vector3(
        monsterPos.x + math.sin(angle) * radius,
        monsterPos.y,
        monsterPos.z + math.cos(angle) * radius,
      );

      // Face the monster
      final facingAngle = angle * (180 / math.pi) + 180;

      positions[ally] = TacticalPosition(
        position: targetPos,
        facingAngle: facingAngle,
        role: role,
        priority: role == CombatRole.melee ? 1.3 : 1.0,
      );
    }
  }

  /// Protect formation - circle the player
  static void _calculateProtectPositions(
    Map<Ally, TacticalPosition> positions,
    List<Ally> allies,
    Vector3 playerPos,
  ) {
    final protectRadius = 3.0;
    final angleStep = (2 * math.pi) / allies.length;

    for (int i = 0; i < allies.length; i++) {
      final ally = allies[i];
      final role = getAllyRole(ally);

      final angle = angleStep * i;

      final targetPos = Vector3(
        playerPos.x + math.sin(angle) * protectRadius,
        playerPos.y,
        playerPos.z + math.cos(angle) * protectRadius,
      );

      // Face outward
      final facingAngle = angle * (180 / math.pi);

      positions[ally] = TacticalPosition(
        position: targetPos,
        facingAngle: facingAngle,
        role: role,
      );
    }
  }

  // ==================== HELPER METHODS ====================

  /// Calculate flank position for melee ally
  static Vector3 _calculateFlankPosition(
    Ally ally,
    List<Ally> allies,
    Vector3 monsterPos,
    Vector3 playerPos,
    double preferredRange,
  ) {
    // Find angle from monster to player
    final toPlayer = playerPos - monsterPos;
    final playerAngle = math.atan2(toPlayer.x, toPlayer.z);

    // Count melee allies to spread them out
    final meleeAllies = allies.where((a) => getAllyRole(a) == CombatRole.melee).toList();
    final meleeIndex = meleeAllies.indexOf(ally);
    final meleeCount = meleeAllies.length;

    // Spread melee allies around the flank (90-180 degrees from player)
    double flankAngle;
    if (meleeCount == 1) {
      flankAngle = playerAngle + math.pi * 0.6; // Single melee flanks one side
    } else {
      // Multiple melee spread around
      final spread = math.pi * 0.8; // 144 degree spread
      final startAngle = playerAngle + math.pi * 0.4;
      flankAngle = startAngle + (spread / (meleeCount - 1)) * meleeIndex;
    }

    return Vector3(
      monsterPos.x + math.sin(flankAngle) * preferredRange,
      monsterPos.y,
      monsterPos.z + math.cos(flankAngle) * preferredRange,
    );
  }

  /// Calculate position for ranged ally
  static Vector3 _calculateRangedPosition(
    Ally ally,
    List<Ally> allies,
    Vector3 monsterPos,
    Vector3 playerPos,
    double preferredRange,
  ) {
    // Ranged allies stay behind or to the side of player
    final toMonster = monsterPos - playerPos;
    final toMonsterNorm = toMonster.normalized();

    // Count ranged allies to spread them
    final rangedAllies = allies.where((a) => getAllyRole(a) == CombatRole.ranged).toList();
    final rangedIndex = rangedAllies.indexOf(ally);
    final rangedCount = rangedAllies.length;

    // Perpendicular spread
    final right = Vector3(-toMonsterNorm.z, 0, toMonsterNorm.x);
    final spread = (rangedIndex - (rangedCount - 1) / 2) * 3.0;

    // Position behind player at preferred range from monster
    final backOffset = -toMonsterNorm * 2.0;
    final sideOffset = right * spread;

    return playerPos + backOffset + sideOffset;
  }

  /// Calculate position for support ally
  static Vector3 _calculateSupportPosition(
    Ally ally,
    List<Ally> allies,
    Vector3 monsterPos,
    Vector3 playerPos,
    double followDistance,
  ) {
    // Support stays between player and allies, biased toward player
    final toMonster = (monsterPos - playerPos).normalized();

    // Position slightly behind and to the side of player
    final right = Vector3(-toMonster.z, 0, toMonster.x);

    // Count support allies
    final supportAllies = allies.where((a) => getAllyRole(a) == CombatRole.support).toList();
    final supportIndex = supportAllies.indexOf(ally);
    final spread = (supportIndex % 2 == 0) ? 2.0 : -2.0;

    return playerPos - toMonster * followDistance + right * spread;
  }

  /// Calculate idle position near player
  static Vector3 _calculateIdlePosition(
    Ally ally,
    List<Ally> allies,
    Vector3 playerPos,
    double followDistance,
  ) {
    final allyIndex = allies.indexOf(ally);
    final angle = (allyIndex * 2 * math.pi / allies.length);

    return Vector3(
      playerPos.x + math.sin(angle) * followDistance,
      playerPos.y,
      playerPos.z + math.cos(angle) * followDistance,
    );
  }

  /// Get terrain height at position (helper to integrate with terrain system)
  static double getTerrainHeight(GameState gameState, double x, double z) {
    if (gameState.infiniteTerrainManager != null) {
      return gameState.infiniteTerrainManager!.getTerrainHeight(x, z);
    }
    return gameState.groundLevel;
  }

  /// Apply terrain height to a tactical position
  static Vector3 applyTerrainHeight(GameState gameState, Vector3 position) {
    final height = getTerrainHeight(gameState, position.x, position.z);
    return Vector3(position.x, height, position.z);
  }
}

/// Extension to get formation display info
extension FormationTypeExtension on FormationType {
  String get name {
    switch (this) {
      case FormationType.scattered:
        return 'Scattered';
      case FormationType.wedge:
        return 'Wedge';
      case FormationType.line:
        return 'Line';
      case FormationType.surround:
        return 'Surround';
      case FormationType.protect:
        return 'Protect';
    }
  }

  String get shortLabel {
    switch (this) {
      case FormationType.scattered:
        return 'SCT';
      case FormationType.wedge:
        return 'WDG';
      case FormationType.line:
        return 'LIN';
      case FormationType.surround:
        return 'SUR';
      case FormationType.protect:
        return 'PRT';
    }
  }

  String get description {
    switch (this) {
      case FormationType.scattered:
        return 'Allies position based on their role';
      case FormationType.wedge:
        return 'V-shape behind player';
      case FormationType.line:
        return 'Side by side facing enemy';
      case FormationType.surround:
        return 'Circle the enemy';
      case FormationType.protect:
        return 'Circle the player';
    }
  }

  int get color {
    switch (this) {
      case FormationType.scattered:
        return 0xFF888888; // Gray
      case FormationType.wedge:
        return 0xFFFF8844; // Orange
      case FormationType.line:
        return 0xFF44FF44; // Green
      case FormationType.surround:
        return 0xFFFF4444; // Red
      case FormationType.protect:
        return 0xFF4488FF; // Blue
    }
  }
}
