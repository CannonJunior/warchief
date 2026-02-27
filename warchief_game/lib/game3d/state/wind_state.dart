import 'dart:math' as math;
import 'wind_config.dart';

/// Core wind simulation with gradual drift via layered sine waves.
///
/// Wind is a 2D force on the XZ plane. Direction and strength drift
/// organically using multiple sine/cosine layers at different frequencies,
/// producing smooth natural-feeling changes with no sudden jumps.
///
/// Supports derecho storms: rare, extreme wind events with 10x strength,
/// mana regen, and visual intensity that ramp up and down smoothly.
class WindState {
  /// Current wind direction in radians (0 = +X, pi/2 = +Z)
  double windAngle = 0.0;

  /// Current wind strength (0.0 = calm, 1.0 = maximum)
  double windStrength = 0.3;

  /// Internal noise time accumulator
  double _noiseTime = 0.0;

  /// Smoothed angular velocity of wind direction (radians/second).
  /// Positive = counter-clockwise, negative = clockwise.
  /// Used by particle renderers to curve trail geometry.
  double windAngularVelocity = 0.0;

  /// Previous wind angle, for finite-difference angular velocity calculation.
  double _prevWindAngle = 0.0;

  // ==================== DERECHO STATE ====================

  /// Whether a derecho storm is currently active (including ramp phases)
  bool isDerechoActive = false;

  /// Current derecho intensity (0.0 = inactive, 1.0 = full power).
  /// Ramps up/down smoothly during transition phases.
  double derechoIntensity = 0.0;

  /// Remaining derecho duration in seconds (including ramp-down)
  double _derechoTimer = 0.0;

  /// Total duration of the current derecho (set at trigger time)
  double _derechoDuration = 0.0;

  /// Time since last derecho ended (drives random trigger chance)
  double _timeSinceLastDerecho = 0.0;

  /// RNG for derecho trigger timing
  final math.Random _derechoRng = math.Random();

  /// Effective wind strength including derecho multiplier.
  /// Normal wind: 0.0-1.0. During derecho: up to strengthMultiplier * maxStrength.
  double get effectiveWindStrength {
    if (!isDerechoActive) return windStrength;
    final mult = globalWindConfig?.derechoStrengthMultiplier ?? 10.0;
    // Reason: lerp from 1x to mult based on derecho intensity for smooth ramp
    final effectiveMult = 1.0 + (mult - 1.0) * derechoIntensity;
    return windStrength * effectiveMult;
  }

  /// Multiplier for white mana regeneration during derecho
  double get derechoManaMultiplier {
    if (!isDerechoActive) return 1.0;
    final mult = globalWindConfig?.derechoManaRegenMultiplier ?? 10.0;
    return 1.0 + (mult - 1.0) * derechoIntensity;
  }

  /// Multiplier for visual particle count/intensity during derecho
  double get derechoVisualMultiplier {
    if (!isDerechoActive) return 1.0;
    final mult = globalWindConfig?.derechoVisualMultiplier ?? 10.0;
    return 1.0 + (mult - 1.0) * derechoIntensity;
  }

  /// Update wind simulation and derecho storm state.
  ///
  /// Advances internal noise clock and recalculates wind angle and strength
  /// using layered sine/cosine waves for organic drift. Also manages derecho
  /// storm lifecycle: random trigger, ramp up, sustain, ramp down.
  void update(double dt) {
    final config = globalWindConfig;
    final driftSpeed = config?.driftSpeed ?? 0.1;
    final gustFreq = config?.gustFrequency ?? 0.05;
    final gustAmp = config?.gustAmplitude ?? 0.4;
    final dirDriftSpeed = config?.directionDriftSpeed ?? 0.08;
    final baseStr = config?.baseStrength ?? 0.3;
    final maxStr = config?.maxStrength ?? 1.0;

    _noiseTime += dt;

    // Reason: layered sine waves at different frequencies produce organic
    // drift without the jarring discontinuities of random noise.

    // Direction drift: 3 layers at different speeds for complex motion
    // During derecho, direction drifts faster for chaotic feel
    final dirSpeedMult = isDerechoActive ? 1.0 + derechoIntensity * 2.0 : 1.0;
    final layer1 = math.sin(_noiseTime * dirDriftSpeed * 1.0 * dirSpeedMult) * 0.5;
    final layer2 = math.sin(_noiseTime * dirDriftSpeed * 2.3 * dirSpeedMult + 1.7) * 0.3;
    final layer3 = math.cos(_noiseTime * dirDriftSpeed * 0.7 * dirSpeedMult + 3.1) * 0.2;
    windAngle += (layer1 + layer2 + layer3) * dt;

    // Keep angle in [0, 2*pi]
    while (windAngle < 0) windAngle += 2 * math.pi;
    while (windAngle >= 2 * math.pi) windAngle -= 2 * math.pi;

    // Track angular velocity as EMA of angle delta / dt.
    // Reason: shortest-arc delta handles the 0/2π wraparound so a wind
    // that crosses north doesn't appear to spin a full revolution.
    if (dt > 0) {
      double delta = windAngle - _prevWindAngle;
      if (delta > math.pi)  delta -= 2 * math.pi;
      if (delta < -math.pi) delta += 2 * math.pi;
      windAngularVelocity = windAngularVelocity * 0.85 + (delta / dt) * 0.15;
      _prevWindAngle = windAngle;
    }

    // Strength drift: base + layered gusts
    final gust1 = math.sin(_noiseTime * gustFreq * 1.0) * gustAmp * 0.6;
    final gust2 = math.sin(_noiseTime * gustFreq * 2.7 + 0.8) * gustAmp * 0.3;
    final gust3 = math.cos(_noiseTime * gustFreq * 0.4 + 2.5) * gustAmp * 0.1;
    windStrength = (baseStr + gust1 + gust2 + gust3).clamp(0.0, maxStr);

    // Update derecho state
    _updateDerecho(dt);
  }

  /// Manage derecho lifecycle: trigger, ramp up, sustain, ramp down.
  void _updateDerecho(double dt) {
    final config = globalWindConfig;
    final rampUp = config?.derechoRampUpTime ?? 5.0;
    final rampDown = config?.derechoRampDownTime ?? 5.0;

    if (isDerechoActive) {
      _derechoTimer -= dt;

      if (_derechoTimer <= 0) {
        // Derecho ended
        isDerechoActive = false;
        derechoIntensity = 0.0;
        _derechoTimer = 0.0;
        _timeSinceLastDerecho = 0.0;
        print('[DERECHO] Storm has passed');
        return;
      }

      // Ramp intensity up during start, down during end
      if (_derechoTimer > _derechoDuration - rampUp) {
        // Ramp-up phase
        final elapsed = _derechoDuration - _derechoTimer;
        derechoIntensity = (elapsed / rampUp).clamp(0.0, 1.0);
      } else if (_derechoTimer < rampDown) {
        // Ramp-down phase
        derechoIntensity = (_derechoTimer / rampDown).clamp(0.0, 1.0);
      } else {
        // Full intensity
        derechoIntensity = 1.0;
      }
    } else {
      // Check for derecho trigger
      _timeSinceLastDerecho += dt;
      final interval = config?.derechoAverageInterval ?? 300.0;

      // Reason: probability increases over time so average interval matches config.
      // Each second has a small chance; after `interval` seconds the cumulative
      // probability is ~63% (1 - e^-1), matching a Poisson process.
      if (_timeSinceLastDerecho > interval * 0.5) {
        final chancePerSecond = 1.0 / interval;
        if (_derechoRng.nextDouble() < chancePerSecond * dt) {
          _triggerDerecho();
        }
      }
    }
  }

  /// Start a derecho storm with random duration.
  void _triggerDerecho() {
    final config = globalWindConfig;
    final minDur = config?.derechoDurationMin ?? 30.0;
    final maxDur = config?.derechoDurationMax ?? 60.0;

    _derechoDuration = minDur + _derechoRng.nextDouble() * (maxDur - minDur);
    _derechoTimer = _derechoDuration;
    isDerechoActive = true;
    derechoIntensity = 0.0; // Will ramp up
    print('[DERECHO] Storm incoming! Duration: ${_derechoDuration.toStringAsFixed(0)}s');
  }

  /// Wind as a 2D vector on the XZ plane.
  ///
  /// Returns (x, z) components representing wind force direction and magnitude.
  /// Uses effectiveWindStrength to include derecho amplification.
  List<double> get windVector => [
        math.cos(windAngle) * effectiveWindStrength,
        math.sin(windAngle) * effectiveWindStrength,
      ];

  /// Calculate movement speed modifier based on unit's movement direction.
  ///
  /// Uses dot product of unit's normalized movement direction with the wind
  /// vector to determine headwind (slows) vs tailwind (speeds up) effect.
  ///
  /// [resistance]: 0.0 = fully affected by wind, 1.0 = immune to wind penalty.
  /// Returns a multiplier around 1.0 (e.g. 0.85 for headwind, 1.10 for tailwind).
  double getMovementModifier(double unitDx, double unitDz, {double resistance = 0.0}) {
    final config = globalWindConfig;
    final headFactor = config?.headwindFactor ?? 0.15;
    final tailFactor = config?.tailwindFactor ?? 0.10;

    // Normalize unit movement direction
    final len = math.sqrt(unitDx * unitDx + unitDz * unitDz);
    if (len < 0.001) return 1.0; // No movement, no effect

    final normDx = unitDx / len;
    final normDz = unitDz / len;

    // Dot product with wind direction (not wind vector magnitude)
    final windDirX = math.cos(windAngle);
    final windDirZ = math.sin(windAngle);
    final dot = normDx * windDirX + normDz * windDirZ;

    // dot > 0 means moving WITH the wind (tailwind)
    // dot < 0 means moving AGAINST the wind (headwind)
    // Scale by effective wind strength so derecho has massive movement impact
    final effStr = effectiveWindStrength;
    if (dot > 0) {
      return 1.0 + dot * tailFactor * effStr;
    } else {
      final impassThreshold = config?.windImpassableThreshold ?? 5.0;
      final impassMin       = config?.windImpassableMinSpeed  ?? 0.02;

      // Reason: base headFactor (0.15) keeps rawMod above 0.1 for effStr < ~6,
      // so the impassMin floor is never reached through the formula alone.
      // Above the impassable threshold, ramp effectiveHeadFactor toward 1.0 so
      // rawMod goes deeply negative and the clamp kicks in regardless of effStr.
      // resistance scales the ramp down so immune stances (Tide) keep the base factor.
      double effectiveHeadFactor = headFactor;
      double minSpeed = 0.1;
      if (effStr >= impassThreshold) {
        final maxEffStr = (config?.derechoStrengthMultiplier ?? 10.0) *
                          (config?.maxStrength ?? 1.0);
        final t = ((effStr - impassThreshold) / (maxEffStr - impassThreshold))
            .clamp(0.0, 1.0);
        effectiveHeadFactor = headFactor + (1.0 - headFactor) * t * (1.0 - resistance);
        // Resistant units get a higher floor — Tide (resistance=1) stays at 0.1
        minSpeed = impassMin + (0.1 - impassMin) * resistance;
      }

      return (1.0 + dot * effectiveHeadFactor * effStr * (1.0 - resistance * 0.5))
          .clamp(minSpeed, double.infinity);
    }
  }

  /// Passive position drift this frame for ground units in strong winds.
  ///
  /// Returns [dx, dz]. Zero when effective wind is below drift threshold.
  /// [resistance]: 0.0 = fully affected, 1.0 = immune to wind drift.
  List<double> getWindDrift(double dt, {double resistance = 0.0}) {
    final config = globalWindConfig;
    final threshold = config?.windDriftThreshold ?? 2.0;
    final maxDrift  = config?.windDriftMaxSpeed  ?? 0.6;
    final effStr    = effectiveWindStrength;
    if (effStr < threshold) return [0.0, 0.0];

    // Reason: scale linearly from threshold to full derecho cap so drift
    // builds gradually rather than snapping on at full force.
    final maxEff  = (config?.derechoStrengthMultiplier ?? 10.0) * (config?.maxStrength ?? 1.0);
    final frac    = ((effStr - threshold) / (maxEff - threshold)).clamp(0.0, 1.0);
    final speed   = maxDrift * frac * (1.0 - resistance);
    return [math.cos(windAngle) * speed * dt, math.sin(windAngle) * speed * dt];
  }

  /// True when wind is strong enough to nearly block counter-wind movement for normal units.
  bool get isWindImpassable {
    return effectiveWindStrength >= (globalWindConfig?.windImpassableThreshold ?? 5.0);
  }

  /// Current wind exposure level for White Mana regeneration.
  ///
  /// Returns effectiveWindStrength to include derecho amplification.
  /// Future: terrain/buildings can reduce this.
  double get exposureLevel => effectiveWindStrength;

  /// Wind force to apply to projectiles.
  ///
  /// Returns (x, z) force components scaled by windForceMultiplier config.
  List<double> getProjectileForce() {
    final config = globalWindConfig;
    final mult = config?.windForceMultiplier ?? 0.8;
    final wv = windVector;
    return [wv[0] * mult, wv[1] * mult];
  }

  /// Wind direction in degrees (0-360) for UI display.
  double get windAngleDegrees => windAngle * 180.0 / math.pi;

  /// Wind strength as percentage (0-100) for UI display.
  /// During derecho, can exceed 100% to show extreme conditions.
  double get windStrengthPercent {
    final maxStr = globalWindConfig?.maxStrength ?? 1.0;
    return (effectiveWindStrength / maxStr * 100.0).clamp(0.0, 1000.0);
  }
}

/// Global wind state instance (initialized in game3d_widget.dart)
WindState? globalWindState;
