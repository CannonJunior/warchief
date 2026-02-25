part of 'game_state.dart';

// Math helpers for targeting (delegates to dart:math for accuracy + hardware speed)
double _gsqrt(double x) => x <= 0 ? 0.0 : math.sqrt(x);
double _gsin(double x) => math.sin(x);
double _gcos(double x) => math.cos(x);
double _gacos(double x) => math.acos(x.clamp(-1.0, 1.0));

/// Helper class for sorting target candidates
class _TargetCandidate {
  final String id;
  final double distance;
  final double angle; // Angle from player's facing direction

  _TargetCandidate(this.id, this.distance, this.angle);
}

extension GameStateTargetingExt on GameState {
  /// Get list of targetable friendlies (player + alive allies)
  List<String> getTargetableFriendlies() {
    final targets = <String>['player'];
    for (int i = 0; i < allies.length; i++) {
      if (allies[i].health > 0) targets.add('ally_$i');
    }
    return targets;
  }

  /// Cycle to next friendly target (Shift+Tab)
  void tabToNextFriendlyTarget() {
    final targets = getTargetableFriendlies();
    if (targets.isEmpty) return;
    _friendlyTabIndex++;
    if (_friendlyTabIndex >= targets.length) _friendlyTabIndex = 0;
    currentTargetId = targets[_friendlyTabIndex];
  }

  /// Rebuild the minion index from the full minions list (NOT the cached
  /// aliveMinions, which may be stale at spawn time).
  void rebuildMinionIndex() {
    _minionIndex.clear();
    for (final minion in minions) {
      if (minion.isAlive) {
        _minionIndex[minion.instanceId] = minion;
      }
    }
  }

  /// Active effects on the current target (boss, minion, ally, or player).
  /// Returns empty list if no target or target has no effects.
  List<ActiveEffect> get currentTargetActiveEffects {
    if (currentTargetId == null) return [];
    if (currentTargetId == 'boss') return monsterActiveEffects;
    if (currentTargetId == 'player') return playerActiveEffects;
    if (currentTargetId!.startsWith('ally_')) {
      final index = int.tryParse(currentTargetId!.substring(5));
      if (index != null && index < allies.length) return allies[index].activeEffects;
      return [];
    }
    // O(1) minion lookup by instance ID
    final minion = _minionIndex[currentTargetId];
    if (minion != null && minion.isAlive) return minion.activeEffects;
    return [];
  }

  /// Get the currently targeted entity
  /// Returns a map with 'type' ('boss', 'minion', or 'dummy') and the entity itself
  Map<String, dynamic>? getCurrentTarget() {
    if (currentTargetId == null) return null;

    if (currentTargetId == 'player') {
      return {
        'type': 'player',
        'entity': null,
        'id': 'player',
      };
    }

    if (currentTargetId == 'boss') {
      return {
        'type': 'boss',
        'entity': null, // Boss is accessed directly via gameState
        'id': 'boss',
      };
    }

    // Check for target dummy
    if (currentTargetId == TargetDummy.instanceId && targetDummy != null && targetDummy!.isSpawned) {
      return {
        'type': 'dummy',
        'entity': targetDummy,
        'id': TargetDummy.instanceId,
      };
    }

    // Check for ally target
    if (currentTargetId!.startsWith('ally_')) {
      final index = int.tryParse(currentTargetId!.substring(5));
      if (index != null && index < allies.length && allies[index].health > 0) {
        return {
          'type': 'ally',
          'entity': allies[index],
          'id': currentTargetId,
        };
      }
      // Ally is dead or invalid, clear it
      currentTargetId = null;
      return null;
    }

    // Find minion by instance ID
    final minion = minions.firstWhere(
      (m) => m.instanceId == currentTargetId && m.isAlive,
      orElse: () => minions.firstWhere((m) => false, orElse: () => minions.first),
    );

    if (minion.instanceId == currentTargetId && minion.isAlive) {
      return {
        'type': 'minion',
        'entity': minion,
        'id': currentTargetId,
      };
    }

    // Target is dead or invalid, clear it
    currentTargetId = null;
    return null;
  }

  /// Get the world position of the current target.
  /// Returns null if no target or target is dead/missing.
  Vector3? getCurrentTargetPosition() {
    if (currentTargetId == null) return null;

    if (currentTargetId == 'boss') {
      if (monsterTransform != null && monsterHealth > 0) {
        return monsterTransform!.position;
      }
      return null;
    }

    if (currentTargetId == TargetDummy.instanceId && targetDummy != null && targetDummy!.isSpawned) {
      return targetDummy!.transform.position;
    }

    if (currentTargetId!.startsWith('ally_')) {
      final index = int.tryParse(currentTargetId!.substring(5));
      if (index != null && index < allies.length && allies[index].health > 0) {
        return allies[index].transform.position;
      }
      return null;
    }

    // Check minions via O(1) index lookup
    final minion = _minionIndex[currentTargetId];
    if (minion != null && minion.isAlive) {
      return minion.transform.position;
    }

    return null;
  }

  /// Get XZ-plane distance from active character to current target
  /// Returns null if no target or no active character position
  double? getDistanceToCurrentTarget() {
    if (currentTargetId == null || activeTransform == null) return null;

    final playerPos = activeTransform!.position;

    if (currentTargetId == 'boss') {
      if (monsterTransform != null && monsterHealth > 0) {
        final dx = monsterTransform!.position.x - playerPos.x;
        final dz = monsterTransform!.position.z - playerPos.z;
        return _gsqrt(dx * dx + dz * dz);
      }
      return null;
    }

    if (currentTargetId == TargetDummy.instanceId && targetDummy != null && targetDummy!.isSpawned) {
      return targetDummy!.distanceToXZ(playerPos);
    }

    // Check allies
    if (currentTargetId!.startsWith('ally_')) {
      final index = int.tryParse(currentTargetId!.substring(5));
      if (index != null && index < allies.length && allies[index].health > 0) {
        final dx = allies[index].transform.position.x - playerPos.x;
        final dz = allies[index].transform.position.z - playerPos.z;
        return _gsqrt(dx * dx + dz * dz);
      }
      return null;
    }

    // Check minions
    for (final minion in aliveMinions) {
      if (minion.instanceId == currentTargetId) {
        final dx = minion.transform.position.x - playerPos.x;
        final dz = minion.transform.position.z - playerPos.z;
        return _gsqrt(dx * dx + dz * dz);
      }
    }

    return null;
  }

  /// Get target's current target (target of target)
  String? getTargetOfTarget() {
    final target = getCurrentTarget();
    if (target == null) return null;

    if (target['type'] == 'boss') {
      // Boss always targets player (for now)
      return 'player';
    } else if (target['type'] == 'minion') {
      final minion = target['entity'] as Monster;
      return minion.targetId ?? 'none';
    } else if (target['type'] == 'ally') {
      // Allies always "target" player for simplicity
      return 'player';
    } else if (target['type'] == 'dummy') {
      // Dummy doesn't target anyone
      return 'none';
    }

    return null;
  }

  /// Set the current target by ID
  void setTarget(String? targetId) {
    currentTargetId = targetId;
    if (targetId != null) {
      addConsoleLog('Target set: $targetId');
      // Update tab index to match
      final index = _targetableEnemyIds.indexOf(targetId);
      if (index >= 0) {
        _tabTargetIndex = index;
      }
    }
  }

  /// Clear current target
  void clearTarget() {
    if (currentTargetId != null) {
      addConsoleLog('Target cleared');
    }
    currentTargetId = null;
    _tabTargetIndex = -1;
  }

  /// Get ordered list of targetable enemies (for tab targeting).
  ///
  /// Sorting tiers (WoW-inspired):
  ///  1. Melee range (≤ _meleeRange) — sorted by distance (nearest first)
  ///  2. Front cone (≤ 60°) — sorted by angle, then distance
  ///  3. Everything else within max range — sorted by distance
  ///
  /// Enemies beyond _tabTargetMaxRange are excluded entirely.
  List<String> getTargetableEnemies(double playerX, double playerZ, double playerRotation) {
    final now = DateTime.now().millisecondsSinceEpoch / 1000.0;

    // Cache for 0.1 seconds (fast refresh for responsive melee targeting)
    if (_targetableEnemyIds.isNotEmpty && now - _targetListCacheTime < 0.1) {
      return _targetableEnemyIds;
    }

    final targets = <_TargetCandidate>[];
    final playerFacingRad = playerRotation * math.pi / 180.0;
    final playerFacingX = -_gsin(playerFacingRad);
    final playerFacingZ = -_gcos(playerFacingRad);

    // Add target dummy if spawned
    if (targetDummy != null && targetDummy!.isSpawned) {
      final dx = targetDummy!.position.x - playerX;
      final dz = targetDummy!.position.z - playerZ;
      final dist = _gsqrt(dx * dx + dz * dz);
      if (dist <= GameState._tabTargetMaxRange) {
        final angle = _calculateAngleToTarget(dx, dz, playerFacingX, playerFacingZ, dist);
        targets.add(_TargetCandidate(TargetDummy.instanceId, dist, angle));
      }
    }

    // Add boss if alive
    if (monsterHealth > 0 && monsterTransform != null) {
      final dx = monsterTransform!.position.x - playerX;
      final dz = monsterTransform!.position.z - playerZ;
      final dist = _gsqrt(dx * dx + dz * dz);
      if (dist <= GameState._tabTargetMaxRange) {
        final angle = _calculateAngleToTarget(dx, dz, playerFacingX, playerFacingZ, dist);
        targets.add(_TargetCandidate('boss', dist, angle));
      }
    }

    // Add alive minions
    for (final minion in aliveMinions) {
      final dx = minion.transform.position.x - playerX;
      final dz = minion.transform.position.z - playerZ;
      final dist = _gsqrt(dx * dx + dz * dz);
      if (dist <= GameState._tabTargetMaxRange) {
        final angle = _calculateAngleToTarget(dx, dz, playerFacingX, playerFacingZ, dist);
        targets.add(_TargetCandidate(minion.instanceId, dist, angle));
      }
    }

    // Reason: Three-tier sort — melee range first (nearest), then front cone
    // (by angle), then everything else (by distance). This mirrors WoW's
    // behavior where tab always grabs the closest hittable enemy for melee.
    targets.sort((a, b) {
      final aInMelee = a.distance <= GameState._meleeRange;
      final bInMelee = b.distance <= GameState._meleeRange;

      // Tier 1: melee-range enemies always come first, sorted by distance
      if (aInMelee && !bInMelee) return -1;
      if (!aInMelee && bInMelee) return 1;
      if (aInMelee && bInMelee) {
        return a.distance.compareTo(b.distance);
      }

      // Tier 2: front-cone enemies (within 60°) come next
      final aInCone = a.angle < 60;
      final bInCone = b.angle < 60;

      if (aInCone && !bInCone) return -1;
      if (!aInCone && bInCone) return 1;

      // Within cone: sort by angle first, break ties with distance
      if (aInCone && bInCone) {
        final angleCmp = a.angle.compareTo(b.angle);
        if (angleCmp != 0) return angleCmp;
        return a.distance.compareTo(b.distance);
      }

      // Tier 3: behind the player — just sort by distance
      return a.distance.compareTo(b.distance);
    });

    _targetableEnemyIds = targets.map((t) => t.id).toList();
    _targetListCacheTime = now;

    return _targetableEnemyIds;
  }

  /// Calculate angle (in degrees) between player facing and target direction
  double _calculateAngleToTarget(double dx, double dz, double facingX, double facingZ, double dist) {
    if (dist < 0.001) return 0;
    final targetDirX = dx / dist;
    final targetDirZ = dz / dist;
    final dot = facingX * targetDirX + facingZ * targetDirZ;
    final clampedDot = dot.clamp(-1.0, 1.0);
    return _gacos(clampedDot) * 180.0 / math.pi;
  }

  /// Tab to next target (WoW-style).
  ///
  /// First press with no target selects the highest-priority enemy (index 0).
  /// Subsequent presses cycle through the sorted list.
  /// Invalidates the cache so the list is always fresh on key press.
  void tabToNextTarget(double playerX, double playerZ, double playerRotation, {bool reverse = false}) {
    // Reason: Invalidate cache on each key press so the sort reflects current
    // positions and facing direction, not a stale snapshot.
    _targetListCacheTime = 0.0;

    final targets = getTargetableEnemies(playerX, playerZ, playerRotation);
    if (targets.isEmpty) {
      clearTarget();
      return;
    }

    // Reason: If no current target, first tab picks the best target (index 0)
    // rather than incrementing past it.
    if (currentTargetId == null || !targets.contains(currentTargetId)) {
      _tabTargetIndex = 0;
    } else {
      // Find where the current target sits in the freshly-sorted list
      final currentIdx = targets.indexOf(currentTargetId!);
      if (reverse) {
        _tabTargetIndex = currentIdx - 1;
        if (_tabTargetIndex < 0) _tabTargetIndex = targets.length - 1;
      } else {
        _tabTargetIndex = currentIdx + 1;
        if (_tabTargetIndex >= targets.length) _tabTargetIndex = 0;
      }
    }

    currentTargetId = targets[_tabTargetIndex];
  }

  /// Validate current target — auto-acquire next nearest enemy if target dies.
  void validateTarget() {
    if (currentTargetId == null) return;

    if (currentTargetId == 'player') {
      return;
    }

    bool targetDead = false;

    if (currentTargetId == 'boss') {
      if (monsterHealth <= 0) targetDead = true;
    } else if (currentTargetId == TargetDummy.instanceId) {
      if (targetDummy == null || !targetDummy!.isSpawned) targetDead = true;
    } else if (currentTargetId!.startsWith('ally_')) {
      final index = int.tryParse(currentTargetId!.substring(5));
      if (index == null || index >= allies.length || allies[index].health <= 0) {
        clearTarget();
        return;
      }
    } else {
      final minion = minions.where((m) => m.instanceId == currentTargetId).firstOrNull;
      if (minion == null || !minion.isAlive) targetDead = true;
    }

    // Reason: When an enemy target dies, auto-acquire the next nearest enemy
    // so melee players can keep swinging without manual re-targeting.
    if (targetDead) {
      clearTarget();
      if (activeTransform != null) {
        final pos = activeTransform!.position;
        // Invalidate cache so we get a fresh sort
        _targetListCacheTime = 0.0;
        final targets = getTargetableEnemies(pos.x, pos.z, activeRotation);
        if (targets.isNotEmpty) {
          _tabTargetIndex = 0;
          currentTargetId = targets[0];
        }
      }
    }
  }
}
