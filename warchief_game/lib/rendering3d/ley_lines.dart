import 'dart:math' as math;
import 'package:vector_math/vector_math.dart';
import '../game3d/state/mana_config.dart';

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

/// Manages Ley Lines across the game world using Voronoi tessellation
class LeyLineManager {
  final List<VoronoiSite> _sites = [];
  final List<LeyLineSegment> _segments = [];
  final List<LeyPowerNode> _powerNodes = [];
  final math.Random _random;

  // Configuration
  final double worldSize;
  final int siteCount;
  final int seed;

  // Mana regeneration settings (read from ManaConfig, fallback to hardcoded)
  static double get maxRegenDistance => globalManaConfig?.leyLineMaxRegenDistance ?? 8.0;
  static double get optimalDistance => globalManaConfig?.leyLineOptimalDistance ?? 2.0;
  static double get baseRegenRate => globalManaConfig?.baseRegenRate ?? 0.0;
  static double get maxRegenRate => globalManaConfig?.maxRegenRate ?? 15.0;

  // Power node settings (read from ManaConfig, fallback to hardcoded)
  static double get powerNodeRadius => globalManaConfig?.powerNodeRadius ?? 3.0;
  static double get powerNodeFraction => globalManaConfig?.powerNodeFraction ?? 0.33;

  LeyLineManager({
    this.worldSize = 200.0,
    this.siteCount = 25,
    this.seed = 42,
  }) : _random = math.Random(seed) {
    _generateSites();
    _generateVoronoiEdges();
    _generatePowerNodes();
  }

  /// Generate random Voronoi sites across the world
  void _generateSites() {
    _sites.clear();

    // Use stratified sampling for more even distribution
    final gridSize = math.sqrt(siteCount).ceil();
    final cellSize = worldSize / gridSize;

    int id = 0;
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        if (id >= siteCount) break;

        // Random point within this cell (with jitter)
        final x = -worldSize / 2 + (i + _random.nextDouble()) * cellSize;
        final z = -worldSize / 2 + (j + _random.nextDouble()) * cellSize;

        _sites.add(VoronoiSite(x, z, id));
        id++;
      }
    }
  }

  /// Generate Voronoi edges using a simple algorithm
  /// (For production, consider using Fortune's algorithm)
  void _generateVoronoiEdges() {
    _segments.clear();

    // Use Delaunay triangulation approximation via connecting nearby sites
    // and computing perpendicular bisectors

    // Step 1: For each pair of sites, find if they share an edge
    final edgeSet = <String>{};

    for (int i = 0; i < _sites.length; i++) {
      for (int j = i + 1; j < _sites.length; j++) {
        final siteA = _sites[i];
        final siteB = _sites[j];

        // Check if these sites are "neighbors" (no other site closer to midpoint)
        final midX = (siteA.x + siteB.x) / 2;
        final midZ = (siteA.z + siteB.z) / 2;
        final distToMidSq = siteA.distanceToSq(midX, midZ);
        final thresholdSq = distToMidSq * 0.81; // 0.9^2

        bool isNeighbor = true;
        for (int k = 0; k < _sites.length; k++) {
          if (k == i || k == j) continue;
          if (_sites[k].distanceToSq(midX, midZ) < thresholdSq) {
            isNeighbor = false;
            break;
          }
        }

        if (isNeighbor) {
          // Create Voronoi edge (perpendicular bisector segment)
          final edgeKey = '${math.min(i, j)}-${math.max(i, j)}';
          if (!edgeSet.contains(edgeKey)) {
            edgeSet.add(edgeKey);
            _createVoronoiEdge(siteA, siteB);
          }
        }
      }
    }

    print('[LeyLines] Generated ${_segments.length} Ley Line segments from $siteCount sites');
  }

  /// Find intersections between Ley Line segments and create power nodes at ~1/3 of them
  void _generatePowerNodes() {
    _powerNodes.clear();

    // Find all intersections
    final intersections = <_Intersection>[];

    for (int i = 0; i < _segments.length; i++) {
      for (int j = i + 1; j < _segments.length; j++) {
        final intersection = _findIntersection(_segments[i], _segments[j]);
        if (intersection != null) {
          // Check if this intersection is close to an existing one (merge nearby)
          bool merged = false;
          for (final existing in intersections) {
            final dx = existing.x - intersection.x;
            final dz = existing.z - intersection.z;
            if (dx * dx + dz * dz < 4.0) { // Within 2 units
              // Merge by averaging and increasing count
              existing.x = (existing.x + intersection.x) / 2;
              existing.z = (existing.z + intersection.z) / 2;
              existing.totalThickness += intersection.totalThickness;
              existing.segmentCount += intersection.segmentCount;
              merged = true;
              break;
            }
          }

          if (!merged) {
            intersections.add(intersection);
          }
        }
      }
    }

    // Select ~1/3 of intersections to be power nodes (randomly)
    final selectedIndices = <int>{};
    final targetCount = (intersections.length * powerNodeFraction).round();

    while (selectedIndices.length < targetCount && selectedIndices.length < intersections.length) {
      final idx = _random.nextInt(intersections.length);
      selectedIndices.add(idx);
    }

    // Create power nodes from selected intersections
    for (final idx in selectedIndices) {
      final inter = intersections[idx];
      // Strength based on total thickness of intersecting lines
      final strength = (inter.totalThickness / inter.segmentCount).clamp(0.5, 2.0);

      _powerNodes.add(LeyPowerNode(
        x: inter.x,
        z: inter.z,
        radius: powerNodeRadius,
        strength: strength,
        intersectionCount: inter.segmentCount,
      ));
    }

    print('[LeyLines] Generated ${_powerNodes.length} Ley Power nodes from ${intersections.length} intersections');
  }

  /// Find intersection point between two line segments (if any)
  _Intersection? _findIntersection(LeyLineSegment a, LeyLineSegment b) {
    // Line segment intersection using parametric form
    final x1 = a.x1, y1 = a.z1, x2 = a.x2, y2 = a.z2;
    final x3 = b.x1, y3 = b.z1, x4 = b.x2, y4 = b.z2;

    final denom = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4);
    if (denom.abs() < 0.0001) return null; // Parallel lines

    final t = ((x1 - x3) * (y3 - y4) - (y1 - y3) * (x3 - x4)) / denom;
    final u = -((x1 - x2) * (y1 - y3) - (y1 - y2) * (x1 - x3)) / denom;

    // Check if intersection is within both segments (with small margin)
    if (t >= 0.05 && t <= 0.95 && u >= 0.05 && u <= 0.95) {
      final ix = x1 + t * (x2 - x1);
      final iz = y1 + t * (y2 - y1);
      return _Intersection(ix, iz, a.thickness + b.thickness, 2);
    }

    return null;
  }

  /// Create a Voronoi edge (perpendicular bisector) between two sites
  void _createVoronoiEdge(VoronoiSite a, VoronoiSite b) {
    // Midpoint
    final midX = (a.x + b.x) / 2;
    final midZ = (a.z + b.z) / 2;

    // Direction perpendicular to line AB
    final dx = b.x - a.x;
    final dz = b.z - a.z;
    final perpX = -dz;
    final perpZ = dx;

    // Normalize
    final len = math.sqrt(perpX * perpX + perpZ * perpZ);
    if (len < 0.0001) return;

    final normX = perpX / len;
    final normZ = perpZ / len;

    // Extend edge in both directions (clip to world bounds later)
    final edgeHalfLength = _random.nextDouble() * 15.0 + 10.0; // Random length for variation

    final x1 = midX - normX * edgeHalfLength;
    final z1 = midZ - normZ * edgeHalfLength;
    final x2 = midX + normX * edgeHalfLength;
    final z2 = midZ + normZ * edgeHalfLength;

    _segments.add(LeyLineSegment(x1: x1, z1: z1, x2: x2, z2: z2));
  }

  /// Get all Ley Line segments
  List<LeyLineSegment> get segments => _segments;

  /// Get all Ley Power nodes
  List<LeyPowerNode> get powerNodes => _powerNodes;

  /// Find the power node at a given position (if any)
  LeyPowerNode? findPowerNodeAt(double x, double z) {
    for (final node in _powerNodes) {
      if (node.containsPoint(x, z)) {
        return node;
      }
    }
    return null;
  }

  /// Check if a position is within any power node
  bool isOnPowerNode(double x, double z) {
    return findPowerNodeAt(x, z) != null;
  }

  /// Get power node info for UI display
  LeyPowerNodeInfo? getPowerNodeInfo(double x, double z) {
    final node = findPowerNodeAt(x, z);
    if (node == null) return null;

    final distance = node.distanceTo(x, z);
    // Regen rate at power nodes equals Ley Line rate for all mana types
    final regenRate = calculateManaRegen(x, z);

    return LeyPowerNodeInfo(
      distance: distance,
      strength: node.strength,
      regenRate: regenRate,
      intersectionCount: node.intersectionCount,
    );
  }

  /// Reusable list for getVisibleSegments to avoid per-frame allocation
  final List<LeyLineSegment> _visibleSegmentsCache = [];

  /// Get segments visible within a certain radius of a position
  List<LeyLineSegment> getVisibleSegments(double x, double z, double radius) {
    _visibleSegmentsCache.clear();
    for (final seg in _segments) {
      // Use cached center coords and squared distance (no Vector3 alloc, no sqrt)
      final dx = seg.centerX - x;
      final dz = seg.centerZ - z;
      final threshold = radius + seg.length / 2;
      if (dx * dx + dz * dz < threshold * threshold) {
        _visibleSegmentsCache.add(seg);
      }
    }
    return _visibleSegmentsCache;
  }

  /// Find the closest Ley Line to a position
  LeyLineResult? findClosestLeyLine(double x, double z) {
    if (_segments.isEmpty) return null;

    LeyLineSegment? closest;
    double closestDistSq = double.infinity;

    for (final seg in _segments) {
      final distSq = seg.distanceToSq(x, z);
      if (distSq < closestDistSq) {
        closestDistSq = distSq;
        closest = seg;
      }
    }

    if (closest == null) return null;

    return LeyLineResult(
      segment: closest,
      distance: math.sqrt(closestDistSq),
      closestPoint: closest.closestPointTo(x, z),
    );
  }

  /// Calculate mana regeneration rate at a given position
  ///
  /// Returns mana per second based on:
  /// - Distance to nearest Ley Line
  /// - Thickness of that Ley Line
  double calculateManaRegen(double x, double z) {
    final result = findClosestLeyLine(x, z);
    if (result == null) return baseRegenRate;

    final distance = result.distance;
    final thickness = result.segment.thickness;

    // No regen if too far
    if (distance > maxRegenDistance) return baseRegenRate;

    // Calculate distance factor (1.0 at optimal, decreasing with distance)
    double distanceFactor;
    if (distance <= optimalDistance) {
      distanceFactor = 1.0;
    } else {
      // Linear falloff from optimal to max distance
      distanceFactor = 1.0 - (distance - optimalDistance) / (maxRegenDistance - optimalDistance);
    }

    // Thickness multiplier (thicker = more mana)
    // Thickness ranges from 0.3 to 2.0, normalize to 0.5 to 1.5 multiplier
    final thicknessFactor = 0.5 + (thickness - 0.3) / (2.0 - 0.3);

    // Final regen rate
    return baseRegenRate + maxRegenRate * distanceFactor * thicknessFactor;
  }

  /// Get Ley Line info for UI display
  LeyLineInfo? getLeyLineInfo(double x, double z) {
    final result = findClosestLeyLine(x, z);
    if (result == null) return null;

    // Check if on a power node
    final onPowerNode = isOnPowerNode(x, z);

    return LeyLineInfo(
      distance: result.distance,
      thickness: result.segment.thickness,
      regenRate: calculateManaRegen(x, z),
      isInRange: result.distance <= maxRegenDistance,
      isOnPowerNode: onPowerNode,
    );
  }

  /// Generate mesh vertices for rendering Ley Lines
  /// Returns a list of triangle vertices with position and color
  List<double> generateMeshData(double centerX, double centerZ, double viewRadius) {
    final vertices = <double>[];
    final visibleSegments = getVisibleSegments(centerX, centerZ, viewRadius);

    for (final seg in visibleSegments) {
      // Create a quad for each segment with wispy edges
      _addSegmentVertices(vertices, seg);
    }

    return vertices;
  }

  /// Add vertices for a single Ley Line segment with wispy appearance
  void _addSegmentVertices(List<double> vertices, LeyLineSegment seg) {
    final dx = seg.x2 - seg.x1;
    final dz = seg.z2 - seg.z1;
    final len = seg.length;
    if (len < 0.1) return;

    // Perpendicular direction for width
    final perpX = -dz / len;
    final perpZ = dx / len;

    // Create multiple quads with varying widths for wispy effect
    final numLayers = 3;
    for (int layer = 0; layer < numLayers; layer++) {
      final layerWidth = seg.thickness * (1.0 - layer * 0.3);
      final alpha = 1.0 - layer * 0.3;

      // Calculate corner positions
      final halfWidth = layerWidth / 2;
      final p1x = seg.x1 - perpX * halfWidth;
      final p1z = seg.z1 - perpZ * halfWidth;
      final p2x = seg.x1 + perpX * halfWidth;
      final p2z = seg.z1 + perpZ * halfWidth;
      final p3x = seg.x2 + perpX * halfWidth;
      final p3z = seg.z2 + perpZ * halfWidth;
      final p4x = seg.x2 - perpX * halfWidth;
      final p4z = seg.z2 - perpZ * halfWidth;

      // Y height slightly above terrain
      const y = 0.1 + 0.02;

      // Blue color with alpha for each layer
      final r = 0.2 * alpha;
      final g = 0.5 * alpha;
      final b = 1.0 * alpha;

      // Triangle 1: p1, p2, p3
      vertices.addAll([p1x, y, p1z, r, g, b]);
      vertices.addAll([p2x, y, p2z, r, g, b]);
      vertices.addAll([p3x, y, p3z, r, g, b]);

      // Triangle 2: p1, p3, p4
      vertices.addAll([p1x, y, p1z, r, g, b]);
      vertices.addAll([p3x, y, p3z, r, g, b]);
      vertices.addAll([p4x, y, p4z, r, g, b]);
    }
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

/// Helper class for tracking intersection points during generation
class _Intersection {
  double x;
  double z;
  double totalThickness;
  int segmentCount;

  _Intersection(this.x, this.z, this.totalThickness, this.segmentCount);
}
