import 'dart:math' as math;
import 'wind_state.dart';
import 'wind_config.dart';
import 'game_state.dart';

// ==================== DATA CLASSES ====================

/// Public snapshot of one active dust devil, consumed by the particle renderer.
class DustDevilData {
  final double x;
  final double z;

  /// Terrain height at the devil's feet (updated each frame).
  final double baseY;

  /// Cumulative spin angle for particle helix positioning.
  final double angularPhase;

  /// Current intensity [0..1], ramped up/down at life boundaries.
  final double intensity;

  const DustDevilData({
    required this.x,
    required this.z,
    required this.baseY,
    required this.angularPhase,
    required this.intensity,
  });
}

// ==================== INTERNAL STATE ====================

class _DustDevil {
  double x;
  double z;
  double baseY = 0.0;
  double travelDx;
  double travelDz;
  double age;
  double maxAge;
  double angularPhase;

  _DustDevil({
    required this.x,
    required this.z,
    required this.travelDx,
    required this.travelDz,
    required this.maxAge,
    required this.angularPhase,
  }) : age = 0.0;

  /// Smooth ramp-up for first 1.5 s, full intensity for middle, ramp-down for last 1.5 s.
  double get intensity {
    const ramp = 1.5;
    if (age < ramp) return (age / ramp).clamp(0.0, 1.0);
    if (age > maxAge - ramp) return ((maxAge - age) / ramp).clamp(0.0, 1.0);
    return 1.0;
  }

  DustDevilData toData() => DustDevilData(
        x: x,
        z: z,
        baseY: baseY,
        angularPhase: angularPhase,
        intensity: intensity,
      );
}

// ==================== SWIRL MANAGER ====================

/// Manages sporadic dust devil events: spawning, movement, and unit lifting.
///
/// Dust devils are short-lived rotating columns that travel roughly with
/// the prevailing wind at greater speed, blending into and out of the
/// wind pattern. They lift small/medium units (player, allies) off the
/// ground via upward force while the unit is within the devil's radius.
class WindSwirlState {
  final List<_DustDevil> _devils = [];
  final math.Random _rng = math.Random();
  double _spawnTimer = 8.0; // Initial delay before first spawn

  /// Set of ally indices currently airborne (lifted by a devil).
  /// Tracked so we can apply a fall force after they leave the swirl.
  final Set<int> _liftedAllyIndices = {};

  bool get hasActiveDevils => _devils.isNotEmpty || _liftedAllyIndices.isNotEmpty;

  /// Returns snapshots of all active devils for rendering.
  List<DustDevilData> getDevilData() =>
      _devils.map((d) => d.toData()).toList(growable: false);

  // ==================== UPDATE ====================

  void update(double dt, GameState gameState, WindState windState) {
    final config = globalWindConfig;

    // Tick spawn timer
    _spawnTimer -= dt;
    if (_spawnTimer <= 0) {
      _trySpawn(gameState, windState, config);
      final interval = config?.swirlSpawnInterval ?? 15.0;
      // Reason: jitter prevents predictable spawn rhythm.
      _spawnTimer = interval * (0.6 + _rng.nextDouble() * 0.8);
    }

    final angSpeed = config?.swirlAngularSpeed ?? 4.5;
    final speed    = config?.swirlSpeed        ?? 4.0;
    final radius   = config?.swirlRadius       ?? 2.0;
    final liftForce = config?.swirlLiftForce   ?? 12.0;

    // Advance active devils
    for (int i = _devils.length - 1; i >= 0; i--) {
      final d = _devils[i];
      d.age += dt;
      d.angularPhase += angSpeed * dt;

      // Reason: blend devil's own heading (70%) with wind (30%) so it enters
      // and exits the prevailing flow naturally while maintaining its own momentum.
      final effStr = windState.effectiveWindStrength.clamp(0.1, 5.0);
      final windInfluence = (0.2 + effStr * 0.04).clamp(0.0, 0.5);
      final wX = math.cos(windState.windAngle);
      final wZ = math.sin(windState.windAngle);
      var bDx = d.travelDx * (1.0 - windInfluence) + wX * windInfluence;
      var bDz = d.travelDz * (1.0 - windInfluence) + wZ * windInfluence;
      final len = math.sqrt(bDx * bDx + bDz * bDz);
      if (len > 0.001) { bDx /= len; bDz /= len; }
      d.x += bDx * speed * dt;
      d.z += bDz * speed * dt;

      // Update base Y from terrain each frame so the devil tracks terrain height.
      if (gameState.infiniteTerrainManager != null) {
        d.baseY = gameState.infiniteTerrainManager!.getTerrainHeight(d.x, d.z);
      } else {
        d.baseY = gameState.groundLevel;
      }

      if (d.age >= d.maxAge) {
        _devils.removeAt(i);
      }
    }

    // Apply lift effects to player and allies
    _applyLiftToPlayer(dt, gameState, radius, liftForce);
    _applyLiftToAllies(dt, gameState, radius, liftForce);
  }

  // ==================== SPAWN ====================

  void _trySpawn(GameState gs, WindState ws, WindConfig? cfg) {
    if (gs.playerTransform == null) return;

    final minD     = cfg?.swirlMinSpawnDist ?? 8.0;
    final maxD     = cfg?.swirlMaxSpawnDist ?? 30.0;
    final lifetime = cfg?.swirlLifetime     ?? 10.0;

    final px = gs.playerTransform!.position.x;
    final pz = gs.playerTransform!.position.z;

    // Reason: spawn upwind and slightly off-axis so the devil naturally
    // travels toward and past the player, giving a fly-through feel.
    final lateralBias = (_rng.nextDouble() - 0.5) * math.pi * 0.5;
    final spawnAngle  = ws.windAngle + math.pi + lateralBias;
    final dist = minD + _rng.nextDouble() * (maxD - minD);
    final spawnX = px + math.cos(spawnAngle) * dist;
    final spawnZ = pz + math.sin(spawnAngle) * dist;

    // Travel direction: mostly downwind with a random lateral swerve.
    final swerve = (_rng.nextDouble() - 0.5) * 0.6;
    final windX  = math.cos(ws.windAngle);
    final windZ  = math.sin(ws.windAngle);
    var tDx = windX + (-windZ) * swerve;
    var tDz = windZ + ( windX) * swerve;
    final tLen = math.sqrt(tDx * tDx + tDz * tDz);
    if (tLen > 0.001) { tDx /= tLen; tDz /= tLen; }

    _devils.add(_DustDevil(
      x: spawnX, z: spawnZ,
      travelDx: tDx, travelDz: tDz,
      maxAge: lifetime * (0.7 + _rng.nextDouble() * 0.6),
      angularPhase: _rng.nextDouble() * 2 * math.pi,
    ));
    print('[WindSwirl] Dust devil spawned at '
        '(${spawnX.toStringAsFixed(1)}, ${spawnZ.toStringAsFixed(1)})');
  }

  // ==================== LIFT MECHANICS ====================

  void _applyLiftToPlayer(
    double dt, GameState gs, double radius, double liftForce,
  ) {
    if (gs.playerTransform == null || gs.isFlying) return;
    final px = gs.playerTransform!.position.x;
    final pz = gs.playerTransform!.position.z;
    final r2 = radius * radius;

    for (final d in _devils) {
      final dx = px - d.x;
      final dz = pz - d.z;
      if (dx * dx + dz * dz < r2) {
        // Reason: continuous upward acceleration that exceeds gravity (PhysicsSystem
        // applies gravity separately), so net effect is upward while inside the swirl.
        gs.verticalVelocity += liftForce * d.intensity * dt;
        return;
      }
    }
  }

  void _applyLiftToAllies(
    double dt, GameState gs, double radius, double liftForce,
  ) {
    if (_devils.isEmpty && _liftedAllyIndices.isEmpty) return;
    final r2 = radius * radius;
    // Reason: net upward speed = liftForce - gravity; with liftForce=12 and gravity≈9.8,
    // allies rise at ~2.2 units/s while inside the swirl column.
    final netLift = liftForce - gs.gravity;

    for (int i = 0; i < gs.allies.length; i++) {
      final ally = gs.allies[i];
      final ax   = ally.transform.position.x;
      final az   = ally.transform.position.z;

      bool inSwirl = false;
      double swirlIntensity = 0.0;
      for (final d in _devils) {
        final dx = ax - d.x;
        final dz = az - d.z;
        if (dx * dx + dz * dz < r2) {
          inSwirl        = true;
          swirlIntensity = d.intensity;
          _liftedAllyIndices.add(i);
          break;
        }
      }

      if (inSwirl) {
        ally.transform.position.y += netLift * swirlIntensity * dt;
      } else if (_liftedAllyIndices.contains(i)) {
        // Ally exited swirl — apply downward gravity until back on ground.
        ally.transform.position.y -= gs.gravity * dt;

        double groundY = gs.groundLevel + 0.4;
        if (gs.infiniteTerrainManager != null) {
          groundY =
              gs.infiniteTerrainManager!.getTerrainHeight(ax, az) + 0.4;
        }
        if (ally.transform.position.y <= groundY) {
          ally.transform.position.y = groundY;
          _liftedAllyIndices.remove(i);
        }
      }
    }
  }
}

/// Global wind swirl state instance (lazily initialized in game3d_widget_update.dart).
WindSwirlState? globalWindSwirlState;
