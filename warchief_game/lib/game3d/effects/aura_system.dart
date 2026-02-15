import 'package:vector_math/vector_math.dart';
import '../../rendering3d/mesh.dart';
import '../../rendering3d/math/transform3d.dart';
import '../state/action_bar_config.dart';

/// Types of aura effects that can be displayed at a unit's base.
///
/// Currently only abilityGlow is implemented; future types can include
/// buff/debuff visuals with gameplay effects.
enum AuraType {
  abilityGlow, // Reflects equipped ability categories
  buff, // Future: positive effect aura
  debuff, // Future: negative effect aura
  environmental, // Future: zone-based aura
}

/// Aura System — computes aura colors from action bar ability categories
/// and manages aura disc mesh creation/caching.
///
/// Category colors mirror the palette in abilities_modal.dart _getCategoryColor
/// but as Vector3 values suitable for mesh vertex colors.
class AuraSystem {
  AuraSystem._();

  /// Map ability category strings to Vector3 RGB colors.
  ///
  /// Matches the color scheme from abilities_modal.dart for visual consistency.
  static Vector3 getCategoryColorVec3(String category) {
    switch (category) {
      case 'warrior':
        return Vector3(1.0, 0.2, 0.2); // Red
      case 'mage':
        return Vector3(0.2, 0.4, 1.0); // Blue
      case 'rogue':
        return Vector3(0.6, 0.6, 0.6); // Gray
      case 'healer':
        return Vector3(0.2, 0.8, 0.2); // Green
      case 'nature':
        return Vector3(0.4, 0.9, 0.4); // Light green
      case 'necromancer':
        return Vector3(0.6, 0.2, 0.8); // Purple
      case 'elemental':
        return Vector3(1.0, 0.6, 0.2); // Orange
      case 'utility':
        return Vector3(0.9, 0.9, 0.2); // Yellow
      case 'windwalker':
        return Vector3(0.9, 0.9, 1.0); // White-ish
      default:
        return Vector3(0.5, 0.5, 0.5); // Default gray
    }
  }

  /// Categories to skip when computing aura color (too generic).
  static const _skipCategories = {'player', 'monster', 'ally', 'general'};

  /// Compute the blended aura color from a character's action bar config.
  ///
  /// Iterates all 10 slots, collects unique category strings,
  /// maps each to a Vector3 color, and averages them.
  /// Returns null if no meaningful categories are found.
  static Vector3? computeAuraColor(ActionBarConfig config) {
    final uniqueCategories = <String>{};

    for (int i = 0; i < 10; i++) {
      final ability = config.getSlotAbilityData(i);
      final cat = ability.category;
      if (!_skipCategories.contains(cat)) {
        uniqueCategories.add(cat);
      }
    }

    if (uniqueCategories.isEmpty) return null;

    // Average all unique category colors
    final sum = Vector3.zero();
    for (final cat in uniqueCategories) {
      sum.add(getCategoryColorVec3(cat));
    }
    sum.scale(1.0 / uniqueCategories.length);

    return sum;
  }

  /// Create or update an aura disc mesh.
  ///
  /// Returns a new mesh only if the color changed or existing is null.
  /// This avoids per-frame mesh allocation.
  ///
  /// Parameters:
  /// - color: The blended aura color
  /// - radius: Disc radius (typically ~1.2 for player, ~0.8 for allies)
  /// - existing: The current mesh (null if first creation)
  /// - lastColor: The color used to create the existing mesh
  static Mesh? createOrUpdateAuraMesh({
    required Vector3? color,
    required double radius,
    Mesh? existing,
    Vector3? lastColor,
  }) {
    if (color == null) return null;

    // Reason: Only recreate mesh when color actually changes to avoid allocation churn
    if (existing != null && lastColor != null) {
      final dr = (color.x - lastColor.x).abs();
      final dg = (color.y - lastColor.y).abs();
      final db = (color.z - lastColor.z).abs();
      if (dr < 0.01 && dg < 0.01 && db < 0.01) {
        return existing;
      }
    }

    return Mesh.auraDisc(radius: radius, color: color);
  }
}
