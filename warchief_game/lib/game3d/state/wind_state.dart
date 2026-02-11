import 'dart:math' as math;
import 'wind_config.dart';

/// Core wind simulation with gradual drift via layered sine waves.
///
/// Wind is a 2D force on the XZ plane. Direction and strength drift
/// organically using multiple sine/cosine layers at different frequencies,
/// producing smooth natural-feeling changes with no sudden jumps.
class WindState {
  /// Current wind direction in radians (0 = +X, pi/2 = +Z)
  double windAngle = 0.0;

  /// Current wind strength (0.0 = calm, 1.0 = maximum)
  double windStrength = 0.3;

  /// Internal noise time accumulator
  double _noiseTime = 0.0;

  /// Update wind simulation.
  ///
  /// Advances internal noise clock and recalculates wind angle and strength
  /// using layered sine/cosine waves for organic drift.
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
    final layer1 = math.sin(_noiseTime * dirDriftSpeed * 1.0) * 0.5;
    final layer2 = math.sin(_noiseTime * dirDriftSpeed * 2.3 + 1.7) * 0.3;
    final layer3 = math.cos(_noiseTime * dirDriftSpeed * 0.7 + 3.1) * 0.2;
    windAngle += (layer1 + layer2 + layer3) * dt;

    // Keep angle in [0, 2*pi]
    while (windAngle < 0) windAngle += 2 * math.pi;
    while (windAngle >= 2 * math.pi) windAngle -= 2 * math.pi;

    // Strength drift: base + layered gusts
    final gust1 = math.sin(_noiseTime * gustFreq * 1.0) * gustAmp * 0.6;
    final gust2 = math.sin(_noiseTime * gustFreq * 2.7 + 0.8) * gustAmp * 0.3;
    final gust3 = math.cos(_noiseTime * gustFreq * 0.4 + 2.5) * gustAmp * 0.1;
    windStrength = (baseStr + gust1 + gust2 + gust3).clamp(0.0, maxStr);
  }

  /// Wind as a 2D vector on the XZ plane.
  ///
  /// Returns (x, z) components representing wind force direction and magnitude.
  List<double> get windVector => [
        math.cos(windAngle) * windStrength,
        math.sin(windAngle) * windStrength,
      ];

  /// Calculate movement speed modifier based on unit's movement direction.
  ///
  /// Uses dot product of unit's normalized movement direction with the wind
  /// vector to determine headwind (slows) vs tailwind (speeds up) effect.
  ///
  /// Returns a multiplier around 1.0 (e.g. 0.85 for headwind, 1.10 for tailwind).
  double getMovementModifier(double unitDx, double unitDz) {
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
    // Scale by wind strength so calm wind has minimal effect
    if (dot > 0) {
      return 1.0 + dot * tailFactor * windStrength;
    } else {
      return 1.0 + dot * headFactor * windStrength; // dot is negative
    }
  }

  /// Current wind exposure level for White Mana regeneration.
  ///
  /// Returns windStrength directly. Future: terrain/buildings can reduce this.
  double get exposureLevel => windStrength;

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
  double get windStrengthPercent {
    final maxStr = globalWindConfig?.maxStrength ?? 1.0;
    return (windStrength / maxStr * 100.0).clamp(0.0, 100.0);
  }
}

/// Global wind state instance (initialized in game3d_widget.dart)
WindState? globalWindState;
