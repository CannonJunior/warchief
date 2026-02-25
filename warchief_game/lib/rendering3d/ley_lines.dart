import 'dart:math' as math;
import 'package:vector_math/vector_math.dart';
import '../game3d/state/mana_config.dart';

part 'ley_line_manager.dart';

/// A point used for Voronoi tessellation
class VoronoiSite {
  final double x;
  final double z;
  final int id;

  const VoronoiSite(this.x, this.z, this.id);

  double distanceTo(double px, double pz) {
    final dx = x - px;
    final dz = z - pz;
    return math.sqrt(dx * dx + dz * dz);
  }

  double distanceToSq(double px, double pz) {
    final dx = x - px;
    final dz = z - pz;
    return dx * dx + dz * dz;
  }
}

/// An edge in the Voronoi diagram representing a Ley Line segment
class LeyLineSegment {
  final double x1, z1; // Start point
  final double x2, z2; // End point
  final double thickness; // Thicker where shorter
  final double length;

  LeyLineSegment({
    required this.x1,
    required this.z1,
    required this.x2,
    required this.z2,
  }) : length = _calculateLength(x1, z1, x2, z2),
       thickness = _calculateThickness(x1, z1, x2, z2);

  static double _calculateLength(double x1, double z1, double x2, double z2) {
    final dx = x2 - x1;
    final dz = z2 - z1;
    return math.sqrt(dx * dx + dz * dz);
  }

  /// Calculate thickness - shorter segments are thicker (more concentrated energy)
  static double _calculateThickness(double x1, double z1, double x2, double z2) {
    final length = _calculateLength(x1, z1, x2, z2);
    // Inverse relationship: shorter = thicker
    // Base thickness 0.3, scales up to 2.0 for very short segments
    const minLength = 5.0;
    const maxLength = 50.0;
    const minThickness = 0.3;
    const maxThickness = 2.0;

    if (length <= minLength) return maxThickness;
    if (length >= maxLength) return minThickness;

    // Inverse linear interpolation
    final t = (length - minLength) / (maxLength - minLength);
    return maxThickness - t * (maxThickness - minThickness);
  }

  /// Get the closest point on this segment to a given point
  Vector3 closestPointTo(double px, double pz) {
    final dx = x2 - x1;
    final dz = z2 - z1;
    final lengthSq = dx * dx + dz * dz;

    if (lengthSq < 0.0001) {
      return Vector3(x1, 0, z1);
    }

    // Project point onto line segment
    final t = ((px - x1) * dx + (pz - z1) * dz) / lengthSq;
    final clampedT = t.clamp(0.0, 1.0);

    return Vector3(
      x1 + clampedT * dx,
      0,
      z1 + clampedT * dz,
    );
  }

  /// Get distance from a point to this segment
  double distanceTo(double px, double pz) {
    final closest = closestPointTo(px, pz);
    final dx = px - closest.x;
    final dz = pz - closest.z;
    return math.sqrt(dx * dx + dz * dz);
  }

  /// Get squared distance from a point to this segment (avoids sqrt)
  double distanceToSq(double px, double pz) {
    final closest = closestPointTo(px, pz);
    final dx = px - closest.x;
    final dz = pz - closest.z;
    return dx * dx + dz * dz;
  }

  /// Cached center X/Z (avoids Vector3 allocation per access)
  late final double centerX = (x1 + x2) / 2;
  late final double centerZ = (z1 + z2) / 2;

  /// Get the center point of this segment
  Vector3 get center => Vector3(centerX, 0, centerZ);

  /// Get start point as Vector3
  Vector3 get start => Vector3(x1, 0, z1);

  /// Get end point as Vector3
  Vector3 get end => Vector3(x2, 0, z2);
}

/// A Ley Power node - an intersection point where multiple Ley Lines meet
/// Power nodes regenerate ALL mana types at the same rate as blue mana regen
class LeyPowerNode {
  final double x;
  final double z;
  final double radius; // Effective radius of the power node
  final double strength; // Mana regen multiplier based on intersecting line thickness
  final int intersectionCount; // Number of lines intersecting here

  const LeyPowerNode({
    required this.x,
    required this.z,
    required this.radius,
    required this.strength,
    required this.intersectionCount,
  });

  /// Check if a position is within this power node
  bool containsPoint(double px, double pz) {
    final dx = px - x;
    final dz = pz - z;
    return (dx * dx + dz * dz) <= radius * radius;
  }

  /// Get distance from point to node center
  double distanceTo(double px, double pz) {
    final dx = px - x;
    final dz = pz - z;
    return math.sqrt(dx * dx + dz * dz);
  }
}

/// Result of finding the closest Ley Line
class LeyLineResult {
  final LeyLineSegment segment;
  final double distance;
  final Vector3 closestPoint;

  const LeyLineResult({
    required this.segment,
    required this.distance,
    required this.closestPoint,
  });
}

/// Ley Line information for UI display
class LeyLineInfo {
  final double distance;
  final double thickness;
  final double regenRate;
  final bool isInRange;
  final bool isOnPowerNode;

  const LeyLineInfo({
    required this.distance,
    required this.thickness,
    required this.regenRate,
    required this.isInRange,
    this.isOnPowerNode = false,
  });
}

/// Ley Power node information for UI display
class LeyPowerNodeInfo {
  final double distance;
  final double strength;
  final double regenRate;
  final int intersectionCount;

  const LeyPowerNodeInfo({
    required this.distance,
    required this.strength,
    required this.regenRate,
    required this.intersectionCount,
  });
}
