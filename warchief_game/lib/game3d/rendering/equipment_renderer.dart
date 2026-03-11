import 'dart:convert';
import 'dart:math' show cos, sin;
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math.dart' hide Colors;
import '../../rendering3d/mesh.dart';
import '../../rendering3d/math/transform3d.dart';
import '../../rendering3d/webgl_renderer.dart';
import '../../rendering3d/camera3d.dart';
import '../../models/item.dart';
import '../../models/inventory.dart';
import 'equipment_visual.dart';

/// Global equipment visual config singleton.
/// Initialized in game3d_widget_init.dart alongside other configs.
EquipmentVisualConfig? globalEquipmentVisualConfig;

// ==================== SLOT VISUAL DEFINITION ====================

/// Per-slot visual parameters parsed from equipment_visual_config.json.
class _SlotVisualDef {
  final bool visible3d;
  final String meshType; // "cube" | "plane"
  final double size;     // cube only
  final double width;    // plane only
  final double height;   // plane only
  final Vector3 localOffset;
  final Vector3 defaultColor; // rgb 0.0–1.0

  const _SlotVisualDef({
    required this.visible3d,
    this.meshType = 'cube',
    this.size = 1.0,
    this.width = 1.0,
    this.height = 1.0,
    required this.localOffset,
    required this.defaultColor,
  });
}

// ==================== CONFIG CLASS ====================

/// Loaded from assets/data/equipment_visual_config.json.
/// Holds per-slot visual definitions used by [EquipmentRenderer].
class EquipmentVisualConfig {
  final Map<String, _SlotVisualDef> _slots;

  EquipmentVisualConfig._(this._slots);

  /// Load and parse the JSON config asset.
  static Future<EquipmentVisualConfig> load() async {
    final raw = await rootBundle.loadString('assets/data/equipment_visual_config.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final slotsJson = json['slots'] as Map<String, dynamic>;

    final slots = <String, _SlotVisualDef>{};
    for (final entry in slotsJson.entries) {
      final m = entry.value as Map<String, dynamic>;
      final visible = m['visible3d'] as bool? ?? false;
      if (!visible) {
        slots[entry.key] = _SlotVisualDef(
          visible3d: false,
          localOffset: Vector3.zero(),
          defaultColor: Vector3.zero(),
        );
        continue;
      }
      final offsetList = m['localOffset'] as List;
      final colorList  = m['defaultColor'] as List;
      slots[entry.key] = _SlotVisualDef(
        visible3d:    true,
        meshType:     m['meshType'] as String? ?? 'cube',
        size:         (m['size'] as num?)?.toDouble() ?? 1.0,
        width:        (m['width'] as num?)?.toDouble() ?? 1.0,
        height:       (m['height'] as num?)?.toDouble() ?? 1.0,
        localOffset:  Vector3(
          (offsetList[0] as num).toDouble(),
          (offsetList[1] as num).toDouble(),
          (offsetList[2] as num).toDouble(),
        ),
        defaultColor: Vector3(
          (colorList[0] as num).toDouble(),
          (colorList[1] as num).toDouble(),
          (colorList[2] as num).toDouble(),
        ),
      );
    }
    return EquipmentVisualConfig._(slots);
  }

  /// Returns the def for a slot name, or null if not found / not visible.
  _SlotVisualDef? _defForSlot(String slotName) {
    final def = _slots[slotName];
    if (def == null || !def.visible3d) return null;
    return def;
  }
}

// ==================== RENDERER ====================

/// Builds, repositions, and renders equipment visuals for characters.
///
/// Follows the [DuelBannerRenderer] pattern: static class, no per-frame
/// allocation for transforms (they are mutated in-place).
class EquipmentRenderer {
  EquipmentRenderer._();

  // ── Rarity tint colors (rgb) ──────────────────────────────────────────────
  static final _rarityColors = <ItemRarity, Vector3>{
    ItemRarity.common:    Vector3(0.62, 0.62, 0.62),
    ItemRarity.uncommon:  Vector3(0.12, 1.00, 0.00),
    ItemRarity.rare:      Vector3(0.00, 0.44, 0.87),
    ItemRarity.epic:      Vector3(0.64, 0.21, 0.93),
    ItemRarity.legendary: Vector3(1.00, 0.50, 0.00),
  };

  // ── Public API ────────────────────────────────────────────────────────────

  /// Build [EquipmentVisual] list from the character's equipped items.
  ///
  /// Only the four slots with `visible3d: true` produce a visual.
  /// Color priority:
  ///   1. item.visualColor (explicit override)
  ///   2. slot defaultColor lerped 20% toward rarity color
  static List<EquipmentVisual> buildEquipmentVisuals(
    Inventory inventory,
    EquipmentVisualConfig config,
  ) {
    final visuals = <EquipmentVisual>[];

    for (final slot in EquipmentSlot.values) {
      final item = inventory.equipment[slot];
      if (item == null) continue;

      final def = config._defForSlot(slot.name);
      if (def == null) continue;

      final color = _resolveColor(item, def);
      final mesh  = _buildMesh(item, def, color);

      visuals.add(EquipmentVisual(
        mesh:        mesh,
        localOffset: def.localOffset.clone(),
        slot:        slot,
      ));
    }
    return visuals;
  }

  /// Update [EquipmentVisual.worldTransform] for every visual each frame.
  ///
  /// Rotates each localOffset by character yaw and writes the result into
  /// worldTransform.position. No allocations — Vector3 math is in-place.
  static void repositionVisuals(
    List<EquipmentVisual> visuals,
    Transform3d characterTransform,
  ) {
    final charPos = characterTransform.position;
    final yawRad  = radians(characterTransform.rotation.y);
    final cosY    = cos(yawRad);
    final sinY    = sin(yawRad);

    for (final v in visuals) {
      final lx = v.localOffset.x;
      final ly = v.localOffset.y;
      final lz = v.localOffset.z;
      // Rotate XZ by yaw, keep Y unchanged
      final wx = cosY * lx - sinY * lz;
      final wz = sinY * lx + cosY * lz;

      v.worldTransform.position = Vector3(charPos.x + wx, charPos.y + ly, charPos.z + wz);
      v.worldTransform.rotation = Vector3(0, characterTransform.rotation.y, 0);
      v.worldTransform.scale    = Vector3(1, 1, 1);
    }
  }

  /// Reposition then render all visuals for a character.
  static void renderVisuals(
    List<EquipmentVisual> visuals,
    Transform3d characterTransform,
    WebGLRenderer renderer,
    Camera3D camera,
  ) {
    if (visuals.isEmpty) return;
    repositionVisuals(visuals, characterTransform);
    for (final v in visuals) {
      renderer.render(v.mesh, v.worldTransform, camera);
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  static Vector3 _resolveColor(Item item, _SlotVisualDef def) {
    // Priority 1: explicit item color override
    if (item.visualColor != null && item.visualColor!.length >= 3) {
      return Vector3(item.visualColor![0], item.visualColor![1], item.visualColor![2]);
    }
    // Priority 2: slot default lerped 20% toward rarity color
    final rarityColor = _rarityColors[item.rarity] ?? def.defaultColor;
    return Vector3(
      def.defaultColor.x + (rarityColor.x - def.defaultColor.x) * 0.20,
      def.defaultColor.y + (rarityColor.y - def.defaultColor.y) * 0.20,
      def.defaultColor.z + (rarityColor.z - def.defaultColor.z) * 0.20,
    );
  }

  static Mesh _buildMesh(Item item, _SlotVisualDef def, Vector3 color) {
    // item.visualShape overrides the slot config meshType
    final shape = item.visualShape ?? def.meshType;
    if (shape == 'plane') {
      return Mesh.plane(width: def.width, height: def.height, color: color);
    }
    // Default: cube
    return Mesh.cube(size: def.size, color: color);
  }
}
