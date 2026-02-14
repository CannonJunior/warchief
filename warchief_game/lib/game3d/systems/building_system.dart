import 'package:vector_math/vector_math.dart' hide Colors;
import '../../models/building.dart';
import '../../rendering3d/building_mesh.dart';
import '../../rendering3d/math/transform3d.dart';
import '../../rendering3d/infinite_terrain_manager.dart';
import '../../rendering3d/ley_lines.dart';
import '../state/building_config.dart';
import '../state/game_state.dart';

/// Building System - Handles placement, interaction, upgrades, and aura effects.
///
/// Static utility class following the same pattern as [AbilitySystem],
/// [AISystem], and [RenderSystem].
class BuildingSystem {
  BuildingSystem._();

  static int _counter = 0;

  /// Place a building at a world position, snapped to terrain height.
  ///
  /// Creates the building mesh from the tier definition, adjusts Y to
  /// terrain surface, and returns the fully initialized [Building] instance.
  static Building placeBuilding({
    required BuildingDefinition definition,
    required double worldX,
    required double worldZ,
    required InfiniteTerrainManager? terrainManager,
    int tier = 0,
  }) {
    final tierDef = definition.getTier(tier);
    final mesh = BuildingMesh.createBuilding(tierDef);

    // Get terrain height at placement position
    double y = 0.0;
    if (terrainManager != null) {
      y = terrainManager.getTerrainHeight(worldX, worldZ);
    }

    final transform = Transform3d(
      position: Vector3(worldX, y, worldZ),
    );

    final building = Building(
      instanceId: '${definition.id}_${_counter++}',
      definition: definition,
      currentTier: tier,
      mesh: mesh,
      transform: transform,
      isPlaced: true,
      constructionProgress: 1.0,
    );

    return building;
  }

  /// Upgrade a building to the next tier.
  ///
  /// Regenerates the mesh for the new tier definition. Returns true if
  /// the upgrade succeeded, false if already at max tier.
  static bool upgradeBuilding(Building building) {
    if (!building.canUpgrade) return false;

    building.currentTier++;
    building.mesh = BuildingMesh.createBuilding(
      building.definition.getTier(building.currentTier),
    );

    print('[BUILDING] ${building.definition.name} upgraded to '
        'Tier ${building.currentTier + 1}: ${building.tierDef.name}');
    return true;
  }

  /// Apply building aura effects (health + mana regen) to the player.
  ///
  /// Called once per frame in the game loop. Iterates all placed buildings
  /// and applies regen bonuses when the player is within aura radius.
  /// Ley line proximity multiplies the aura effect.
  static void applyBuildingAuras(GameState gameState, double dt) {
    if (gameState.playerTransform == null) return;
    if (gameState.buildings.isEmpty) return;

    final px = gameState.playerTransform!.position.x;
    final pz = gameState.playerTransform!.position.z;

    for (final building in gameState.buildings) {
      if (!building.isPlaced) continue;
      if (!building.isInAura(px, pz)) continue;

      // Check for ley line proximity bonus on the building
      final bonus = getLeyLineBonus(building, gameState.leyLineManager);

      // Apply health regen
      final hRegen = building.healthRegen * bonus;
      if (hRegen > 0) {
        gameState.playerHealth = (gameState.playerHealth + hRegen * dt)
            .clamp(0.0, gameState.playerMaxHealth);
      }

      // Apply blue mana regen bonus (stacks with ley line regen)
      final mRegen = building.manaRegen * bonus;
      if (mRegen > 0) {
        gameState.blueMana = (gameState.blueMana + mRegen * dt)
            .clamp(0.0, gameState.maxBlueMana);
      }
    }
  }

  /// Check if a building is near a ley line and return the bonus multiplier.
  ///
  /// Returns 1.0 if no ley line is nearby, or the configured multiplier
  /// (default 1.5x) if within the bonus radius.
  static double getLeyLineBonus(
      Building building, LeyLineManager? leyManager) {
    if (leyManager == null) return 1.0;

    final config = globalBuildingConfig;
    final bonusRadius = config?.leyLineBonusRadius ?? 10.0;
    final bonusMult = config?.leyLineBonusMultiplier ?? 1.5;

    final info = leyManager.getLeyLineInfo(
      building.transform.position.x,
      building.transform.position.z,
    );

    if (info != null && info.distance < bonusRadius) {
      return bonusMult;
    }
    return 1.0;
  }
}
