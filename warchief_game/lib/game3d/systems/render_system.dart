import 'dart:math' as math;
import 'package:vector_math/vector_math.dart' hide Colors;
import '../state/game_state.dart';
import '../state/game_config.dart';
import '../../rendering3d/webgl_renderer.dart';
import '../../rendering3d/camera3d.dart';
import '../../rendering3d/math/transform3d.dart';
import '../../rendering3d/mesh.dart';
import '../../rendering3d/ley_lines.dart';
import '../rendering/wind_particles.dart';
import '../rendering/dust_devil_particles.dart';
import '../rendering/duel_banner_renderer.dart';
import '../rendering/equipment_renderer.dart' show EquipmentRenderer;
import '../rendering/equipment_visual.dart' show EquipmentVisual;
import '../state/wind_swirl_state.dart';
import '../state/duel_banner_state.dart' show DuelBannerPhase;
import '../rendering/green_mana_sparkles.dart';
import '../rendering/meteor_particles.dart';
import '../rendering/meteor_crater_renderer.dart';
import '../rendering/sky_renderer.dart';
import '../state/gameplay_settings.dart';
import '../state/comet_state.dart' show globalCometState;
import '../data/abilities/ability_types.dart' show ManaColor;

/// Render System - Handles 3D scene rendering
///
/// Orchestrates rendering of all game objects in the correct order:
/// 1. Terrain (with LOD)
/// 2. Shadows
/// 3. Characters (player, monster, allies)
/// 4. Effects (abilities, projectiles, impacts)
class RenderSystem {
  RenderSystem._(); // Private constructor

  /// Wind particle system (initialized on first use)
  static final WindParticleSystem _windParticles = WindParticleSystem();

  /// Green mana sparkle particle system (initialized on first use)
  static final GreenManaSparkleSystem _greenSparkles = GreenManaSparkleSystem();

  /// Meteor shower particle system (initialized on first use)
  static final MeteorParticleSystem _meteorParticles = MeteorParticleSystem();

  /// Persistent meteor impact crater renderer (initialized on first use)
  static final MeteorCraterRenderer _craterRenderer = MeteorCraterRenderer();

  /// Dust devil swirl particle system (initialized on first use)
  static final DustDevilParticleSystem _dustDevils = DustDevilParticleSystem();

  /// Sky gradient and comet billboard renderer
  static final SkyRenderer _skyRenderer = SkyRenderer();

  /// Cached transforms for terrain chunks (keyed by world position hash).
  /// Avoids per-frame Transform3d allocation for each chunk.
  static final Map<int, Transform3d> _chunkTransformCache = {};

  /// Reusable transform for ley line rendering (position always origin).
  static final Transform3d _originTransform = Transform3d(position: Vector3(0, 0, 0));

  /// Get or create a cached transform for a chunk position.
  static Transform3d _getChunkTransform(Vector3 worldPos) {
    final key = worldPos.x.hashCode ^ (worldPos.z.hashCode * 31);
    return _chunkTransformCache.putIfAbsent(key, () => Transform3d(position: worldPos));
  }

  /// Renders the entire 3D scene
  ///
  /// Parameters:
  /// - renderer: WebGL renderer to use
  /// - camera: Camera for view/projection
  /// - gameState: Current game state with all renderable objects
  static void render(
    WebGLRenderer renderer,
    Camera3D camera,
    GameState gameState,
    double dt,
  ) {
    // Tint clearColor toward void-purple during comet flyby
    // Reason: the sky mesh quad is outside the isometric camera frustum; clearColor
    // is the most reliable way to show the comet's influence on the sky background.
    final cometState = globalCometState;
    final cometI = cometState?.cometIntensity ?? 0.0;
    if (cometI > 0.01) {
      renderer.gl.clearColor(
        0.10 - cometI * 0.06, // R: neutral gray → darker (0.04 at peak)
        0.10 - cometI * 0.09, // G: neutral gray → near-black (0.01 at peak)
        0.10 + cometI * 0.05, // B: neutral gray → void-blue tint (0.15 at peak)
        1.0,
      );
    } else {
      renderer.gl.clearColor(0.10, 0.10, 0.10, 1.0);
    }

    // Clear screen
    renderer.clear();

    // Render sky background (before terrain so it sits behind everything)
    if (cometState != null) {
      _skyRenderer.update(cometState, dt);
      _skyRenderer.renderSky(renderer, camera, cometState);
    }

    // Render infinite terrain chunks with LOD and texture splatting
    if (gameState.infiniteTerrainManager != null) {
      final chunks = gameState.infiniteTerrainManager!.getLoadedChunks();
      for (final chunk in chunks) {
        // Reason: Reuse cached transform per chunk to avoid per-frame allocation
        final chunkTransform = _getChunkTransform(chunk.worldPosition);

        // Render terrain with texture splatting (if enabled)
        // Falls back to regular rendering if texturing not initialized
        renderer.renderTerrain(chunk, chunkTransform, camera);
      }
    }
    // Fallback to old terrain system (backwards compatibility)
    else if (gameState.terrainTiles != null) {
      for (final tile in gameState.terrainTiles!) {
        renderer.render(tile.mesh, tile.transform, camera);
      }
    }

    // Render Ley Lines (magical energy lines on terrain)
    _renderLeyLines(renderer, camera, gameState);

    // Render buildings (static structures on terrain, before characters)
    for (final building in gameState.buildings) {
      if (building.isPlaced) {
        renderer.render(building.mesh, building.transform, camera);
      }
    }

    // Render shadow (before player so it appears underneath)
    if (gameState.shadowMesh != null && gameState.shadowTransform != null) {
      renderer.render(gameState.shadowMesh!, gameState.shadowTransform!, camera);
    }

    // Render aura glow discs at unit bases (additive blending)
    _renderAuras(renderer, camera, gameState);

    // Render duel arena banner (pole + cloth + victory flag, normal blending)
    final duelBanner = gameState.duelBannerState;
    if (duelBanner != null && duelBanner.phase != DuelBannerPhase.idle) {
      DuelBannerRenderer.render(renderer, camera, duelBanner);
    }

    // Render duel combatants with normal blending (not inside the aura pass)
    for (final combatant in gameState.duelCombatants) {
      renderer.render(combatant.mesh, combatant.transform, camera);
      _renderEquipment(combatant.equipVisuals, combatant.transform, renderer, camera);
    }

    // Render in-flight duel projectiles
    for (final proj in gameState.duelProjectiles) {
      renderer.render(proj.mesh, proj.transform, camera);
    }

    // Render target indicator (yellow dashed rectangle around target's base)
    _renderTargetIndicator(renderer, camera, gameState);

    // Render player
    if (gameState.playerMesh != null && gameState.playerTransform != null) {
      renderer.render(gameState.playerMesh!, gameState.playerTransform!, camera);
      _renderEquipment(gameState.playerEquipVisuals, gameState.playerTransform!, renderer, camera);
    }

    // Render direction indicator
    if (gameState.directionIndicator != null && gameState.directionIndicatorTransform != null) {
      renderer.render(gameState.directionIndicator!, gameState.directionIndicatorTransform!, camera);
    }

    // Render monster
    if (gameState.monsterMesh != null && gameState.monsterTransform != null) {
      renderer.render(gameState.monsterMesh!, gameState.monsterTransform!, camera);
    }

    // Render monster direction indicator
    if (gameState.monsterDirectionIndicator != null && gameState.monsterDirectionIndicatorTransform != null) {
      renderer.render(gameState.monsterDirectionIndicator!, gameState.monsterDirectionIndicatorTransform!, camera);
    }

    // Render allies
    for (final ally in gameState.allies) {
      // Render ally mesh
      renderer.render(ally.mesh, ally.transform, camera);
      _renderEquipment(ally.equipVisuals, ally.transform, renderer, camera);

      // Render ally projectiles
      for (final projectile in ally.projectiles) {
        renderer.render(projectile.mesh, projectile.transform, camera);
      }
    }

    // Render minions
    for (final minion in gameState.aliveMinions) {
      // Render minion mesh
      renderer.render(minion.mesh, minion.transform, camera);

      // Render minion direction indicator
      if (minion.directionIndicatorTransform != null) {
        final indicator = gameState.getMinionDirectionIndicator(minion.definition);
        renderer.render(indicator, minion.directionIndicatorTransform!, camera);
      }

      // Render minion projectiles
      for (final projectile in minion.projectiles) {
        renderer.render(projectile.mesh, projectile.transform, camera);
      }
    }

    // Render target dummy (for DPS testing)
    if (gameState.targetDummy != null && gameState.targetDummy!.isSpawned) {
      final dummy = gameState.targetDummy!;
      renderer.render(dummy.mesh, dummy.transform, camera);
      // Render dummy direction indicator
      if (dummy.directionIndicator != null && dummy.directionIndicatorTransform != null) {
        renderer.render(dummy.directionIndicator!, dummy.directionIndicatorTransform!, camera);
      }
    }

    // Render ability effects
    // Render player sword attack
    if (gameState.ability1Active && gameState.swordMesh != null && gameState.swordTransform != null) {
      renderer.render(gameState.swordMesh!, gameState.swordTransform!, camera);
    }

    // Render monster sword attack
    if (gameState.monsterAbility1Active && gameState.monsterSwordMesh != null && gameState.monsterSwordTransform != null) {
      renderer.render(gameState.monsterSwordMesh!, gameState.monsterSwordTransform!, camera);
    }

    // Render fireballs
    for (final fireball in gameState.fireballs) {
      renderer.render(fireball.mesh, fireball.transform, camera);
    }

    // Render monster projectiles
    for (final projectile in gameState.monsterProjectiles) {
      renderer.render(projectile.mesh, projectile.transform, camera);
    }

    // Render impact effects
    for (final impact in gameState.impactEffects) {
      renderer.render(impact.mesh, impact.transform, camera);
    }

    // Render heal effect
    if (gameState.ability3Active && gameState.healEffectMesh != null && gameState.healEffectTransform != null) {
      renderer.render(gameState.healEffectMesh!, gameState.healEffectTransform!, camera);
    }

    // Render wind particles (Effects pass)
    _renderWindParticles(renderer, camera, gameState, dt);

    // Render dust devil swirl columns (Effects pass)
    _renderDustDevils(renderer, camera);

    // Render green mana sparkles (Effects pass)
    _renderGreenManaSparkles(renderer, camera, gameState, dt);

    // Render comet billboard (additive blending, after opaque geometry)
    if (cometState != null) {
      _skyRenderer.renderComet(renderer, camera, cometState);
    }

    // Render meteor shower particles
    _renderMeteors(renderer, camera, gameState, dt);

    // Render persistent 3D meteor impact craters (scorched disc + rock debris)
    _renderMeteorCraters(renderer, camera);
  }

  /// Render equipment visuals (helm, weapon, shield, cloak) for a character.
  static void _renderEquipment(
    List<EquipmentVisual> visuals,
    Transform3d characterTransform,
    WebGLRenderer renderer,
    Camera3D camera,
  ) {
    if (visuals.isEmpty) return;
    EquipmentRenderer.renderVisuals(visuals, characterTransform, renderer, camera);
  }

  /// Render aura glow discs at unit bases with additive blending.
  ///
  /// Enables GL_BLEND with SRC_ALPHA + ONE (additive) so the disc
  /// creates a soft glow effect. Depth writes are disabled to prevent
  /// the transparent disc from occluding geometry behind it.
  static void _renderAuras(
    WebGLRenderer renderer,
    Camera3D camera,
    GameState gameState,
  ) {
    final gl = renderer.gl;

    // Enable additive blending for glow effect
    gl.enable(0x0BE2); // GL_BLEND
    gl.blendFunc(0x0302, 0x0001); // SRC_ALPHA, ONE (additive)
    gl.depthMask(false); // Don't write to depth buffer

    // Render player aura
    if (gameState.playerAuraMesh != null && gameState.playerAuraTransform != null) {
      renderer.render(gameState.playerAuraMesh!, gameState.playerAuraTransform!, camera);
    }

    // Render ally auras
    for (final ally in gameState.allies) {
      if (ally.auraMesh != null) {
        renderer.render(ally.auraMesh!, ally.auraTransform, camera);
      }
    }

    // Restore state
    gl.depthMask(true);
    gl.disable(0x0BE2); // GL_BLEND
  }

  /// Update and render wind particles.
  static void _renderWindParticles(
    WebGLRenderer renderer,
    Camera3D camera,
    GameState gameState,
    double dt,
  ) {
    if (gameState.playerTransform == null) return;

    // Hide wind particles when active character is not white-attuned (if gated)
    if (globalGameplaySettings?.manaSourceVisibilityGated ?? false) {
      if (!gameState.activeManaAttunements.contains(ManaColor.white)) return;
    }

    // Initialize on first call
    if (!_windParticles.isInitialized) {
      _windParticles.init();
    }

    // Update particle positions based on wind state
    _windParticles.update(
      dt,
      gameState.playerTransform!.position,
      gameState.windState,
    );

    // Render as single batched mesh
    _windParticles.render(renderer, camera);
  }

  /// Update and render dust devil swirl columns.
  static void _renderDustDevils(WebGLRenderer renderer, Camera3D camera) {
    final swirls = globalWindSwirlState;
    if (swirls == null || !swirls.hasActiveDevils) return;
    if (!_dustDevils.isInitialized) _dustDevils.init();
    _dustDevils.update(swirls.getDevilData());
    _dustDevils.render(renderer, camera);
  }

  /// Update and render green mana sparkle particles.
  static void _renderGreenManaSparkles(
    WebGLRenderer renderer,
    Camera3D camera,
    GameState gameState,
    double dt,
  ) {
    // Gate visibility by green mana attunement if setting is enabled
    if (globalGameplaySettings?.manaSourceVisibilityGated ?? false) {
      if (!gameState.activeManaAttunements.contains(ManaColor.green)) return;
    }

    if (!_greenSparkles.isInitialized) {
      _greenSparkles.init();
    }

    _greenSparkles.update(dt, gameState);
    _greenSparkles.render(renderer, camera);
  }

  /// Update and render meteor shower particles.
  static void _renderMeteors(
    WebGLRenderer renderer,
    Camera3D camera,
    GameState gameState,
    double dt,
  ) {
    final cometState = globalCometState;
    if (cometState == null) return;
    if (gameState.playerTransform == null) return;

    if (!_meteorParticles.isInitialized) {
      _meteorParticles.init();
    }

    final pos = gameState.playerTransform!.position;
    final terrainManager = gameState.infiniteTerrainManager;

    _meteorParticles.update(
      dt,
      pos.x,
      pos.z,
      terrainManager != null
          ? (x, z) => terrainManager.getTerrainHeight(x, z)
          : (x, z) => 0.0,
      cometState,
    );

    _meteorParticles.render(renderer, camera);
  }

  /// Update and render persistent 3D meteor impact craters.
  static void _renderMeteorCraters(WebGLRenderer renderer, Camera3D camera) {
    final cometState = globalCometState;
    if (cometState == null || cometState.activeCraterCount == 0) return;
    if (!_craterRenderer.isInitialized) _craterRenderer.init();
    _craterRenderer.update(cometState.craterDataForRendering);
    _craterRenderer.render(renderer, camera);
  }

  /// Render target indicator around the current target
  static void _renderTargetIndicator(
    WebGLRenderer renderer,
    Camera3D camera,
    GameState gameState,
  ) {
    if (gameState.currentTargetId == null) return;

    // Read configurable indicator settings.
    final cfg = globalGameplaySettings;
    final sizeScale   = cfg?.targetSizeScale       ?? 1.0;
    final lineWidth   = cfg?.targetLineWidth        ?? 0.10;
    final acqScale    = cfg?.targetAcquiredScale    ?? 1.3;
    final acqDuration = cfg?.targetAcquiredDuration ?? 2.0;

    // Helper: convert ARGB int to normalised Vector3 RGB.
    Vector3 colorFromArgb(int argb) => Vector3(
      ((argb >> 16) & 0xFF) / 255.0,
      ((argb >>  8) & 0xFF) / 255.0,
      ( argb        & 0xFF) / 255.0,
    );

    // Get target position, size, and indicator color.
    Vector3? targetPosition;
    double targetSize = 1.5;
    int indicatorArgb = cfg?.targetEnemyColor ?? 0xFFFF3333; // red default

    if (gameState.currentTargetId == 'boss') {
      if (gameState.monsterTransform != null && gameState.monsterHealth > 0) {
        targetPosition = gameState.monsterTransform!.position;
        targetSize = 1.8;
      }
    } else if (gameState.currentTargetId == 'target_dummy') {
      if (gameState.targetDummy != null && gameState.targetDummy!.isSpawned) {
        targetPosition = gameState.targetDummy!.position;
        targetSize = 1.5 * 1.5;
      }
    } else if (gameState.currentTargetId!.startsWith('ally_')) {
      final index = int.tryParse(gameState.currentTargetId!.substring(5));
      if (index != null && index < gameState.allies.length && gameState.allies[index].health > 0) {
        targetPosition = gameState.allies[index].transform.position;
        targetSize = GameConfig.allySize * 1.5;
        indicatorArgb = cfg?.targetAllyColor ?? 0xFF33FF44; // green for allies
      }
    } else if (gameState.currentTargetId!.startsWith('duel_')) {
      // Duel combatant — blue for challengers, red for enemies (hardcoded, not user-configurable).
      final index = int.tryParse(gameState.currentTargetId!.substring(5));
      if (index != null && index < gameState.duelCombatants.length) {
        final combatant = gameState.duelCombatants[index];
        if (combatant.health > 0) {
          targetPosition = combatant.transform.position;
          targetSize = 0.8 * 1.5;
          final mgr = gameState.duelManager;
          final isChallenger = mgr != null && index < mgr.challengerPartySize;
          indicatorArgb = isChallenger ? 0xFF4488FF : (cfg?.targetEnemyColor ?? 0xFFFF3333);
        }
      }
    } else {
      final minion = gameState.minionById(gameState.currentTargetId!);
      if (minion != null) {
        targetPosition = minion.transform.position;
        targetSize = minion.definition.effectiveScale * 1.5;
      }
    }

    if (targetPosition == null) return;

    final scaledSize = targetSize * sizeScale;

    // Recreate mesh when target, size, or color changes.
    final targetChanged = gameState.lastTargetIndicatorId != gameState.currentTargetId;
    final needsNewMesh = gameState.targetIndicatorMesh == null ||
        gameState.lastTargetIndicatorSize != scaledSize ||
        gameState.lastTargetIndicatorId != gameState.currentTargetId ||
        gameState.lastTargetIndicatorColorValue != indicatorArgb;

    if (needsNewMesh) {
      // Reason: capture previous indicator world position BEFORE updating the
      // cached ID so we know where to start the slide from.
      if (targetChanged && gameState.targetIndicatorTransform != null) {
        gameState.targetIndicatorAnimFrom =
            gameState.targetIndicatorTransform!.position.clone();
        gameState.targetIndicatorAnimStartTime = gameState.gameTimeSec;
      }

      gameState.targetIndicatorMesh = Mesh.targetIndicator(
        size: scaledSize,
        lineWidth: lineWidth,
        color: colorFromArgb(indicatorArgb),
      );
      gameState.lastTargetIndicatorSize  = scaledSize;
      gameState.lastTargetIndicatorId    = gameState.currentTargetId;
      gameState.lastTargetIndicatorColorValue = indicatorArgb;
    }

    // "Target acquired" flash — recreated on target change, visible for acqDuration.
    final acqArgb = cfg?.targetAcquiredColor ?? 0xFFFFF200;
    if (targetChanged) {
      gameState.targetAcquiredMesh = Mesh.targetIndicator(
        size: scaledSize * acqScale,
        lineWidth: lineWidth * 1.3,
        color: colorFromArgb(acqArgb),
      );
      gameState.targetAcquiredStartTime = gameState.gameTimeSec;
    }
    if (gameState.targetAcquiredMesh != null &&
        gameState.targetAcquiredStartTime >= 0) {
      final acquiredAge =
          gameState.gameTimeSec - gameState.targetAcquiredStartTime;
      if (acquiredAge < acqDuration) { // acqDuration read from settings above
        gameState.targetAcquiredTransform ??= Transform3d();
        // Reason: acquired flash tracks the target's live position (may be moving).
        gameState.targetAcquiredTransform!.position = targetPosition;
        renderer.render(
          gameState.targetAcquiredMesh!,
          gameState.targetAcquiredTransform!,
          camera,
        );
      }
    }

    // Compute animated display position — ease-out cubic slide from old to new.
    gameState.targetIndicatorTransform ??= Transform3d();
    Vector3 displayPosition;
    final animFrom = gameState.targetIndicatorAnimFrom;
    if (animFrom != null && gameState.targetIndicatorAnimStartTime >= 0) {
      final age = gameState.gameTimeSec - gameState.targetIndicatorAnimStartTime;
      final raw = (age / GameState.targetIndicatorAnimDuration).clamp(0.0, 1.0);
      // Reason: ease-out cubic — starts fast, decelerates into target position.
      final t = 1.0 - math.pow(1.0 - raw, 3.0).toDouble();

      // Interpolate X and Z along the slide path.
      final interpX = animFrom.x + (targetPosition.x - animFrom.x) * t;
      final interpZ = animFrom.z + (targetPosition.z - animFrom.z) * t;

      // Reason: linearly interpolating Y between two entity heights cuts through
      // terrain whenever the ground between them is higher than either endpoint.
      // Sampling the actual terrain height keeps the indicator on the surface.
      final terrainY = gameState.infiniteTerrainManager
          ?.getTerrainHeight(interpX, interpZ) ?? targetPosition.y;
      displayPosition = Vector3(interpX, terrainY, interpZ);

      if (raw >= 1.0) gameState.targetIndicatorAnimFrom = null; // animation done
    } else {
      displayPosition = targetPosition;
    }

    gameState.targetIndicatorTransform!.position = displayPosition;

    // Render the indicator
    renderer.render(
      gameState.targetIndicatorMesh!,
      gameState.targetIndicatorTransform!,
      camera,
    );
  }

  /// Cached Ley Line meshes to avoid regenerating every frame
  static final Map<int, Mesh> _leyLineMeshCache = {};
  static int _lastLeyLineHash = 0;

  /// Render Ley Lines on the terrain
  static void _renderLeyLines(
    WebGLRenderer renderer,
    Camera3D camera,
    GameState gameState,
  ) {
    if (gameState.leyLineManager == null) return;
    if (gameState.playerTransform == null) return;

    // Hide ley lines when active character is not blue-attuned (if gated)
    if (globalGameplaySettings?.manaSourceVisibilityGated ?? false) {
      if (!gameState.activeManaAttunements.contains(ManaColor.blue)) return;
    }

    final playerPos = gameState.playerTransform!.position;
    final viewRadius = 100.0; // Only render Ley Lines within this radius

    // Get visible segments
    final segments = gameState.leyLineManager!.getVisibleSegments(
      playerPos.x,
      playerPos.z,
      viewRadius,
    );

    if (segments.isEmpty) return;

    // Hash based on segment positions + loaded chunk count.
    // Including the chunk count ensures the mesh is regenerated as terrain
    // chunks stream in, so subdivided Y samples stay current.
    int hash = segments.length;
    hash = hash * 31 + (gameState.infiniteTerrainManager?.loadedChunkCount ?? 0);
    for (final seg in segments) {
      hash = hash * 31 + seg.x1.hashCode;
      hash = hash * 31 + seg.z1.hashCode;
      hash = hash * 31 + seg.x2.hashCode;
      hash = hash * 31 + seg.z2.hashCode;
    }

    // Regenerate mesh if segments changed
    if (hash != _lastLeyLineHash || !_leyLineMeshCache.containsKey(hash)) {
      _leyLineMeshCache.clear();
      _leyLineMeshCache[hash] = _createLeyLineMesh(segments, gameState);
      _lastLeyLineHash = hash;
    }

    final mesh = _leyLineMeshCache[hash];
    if (mesh == null) return;

    // Render at world origin (positions are absolute)
    renderer.render(mesh, _originTransform, camera);
  }

  /// Create a mesh for the visible Ley Line segments.
  ///
  /// Each segment is subdivided into sub-quads so that the line drapes
  /// over terrain topology rather than cutting through hills in the middle.
  ///
  /// Terrain height is sampled at the four actual corner positions of every
  /// sub-quad (not just the two centerline endpoints), so lines drape correctly
  /// across cross-slopes as well as along-line elevation changes.
  ///
  /// Subdivision step is 3 world units; a 60-unit segment → 20 quads per layer.
  static Mesh _createLeyLineMesh(
    List<LeyLineSegment> segments,
    GameState gameState,
  ) {
    const double hoverOffset = 0.15;  // Float above terrain surface
    const double subdivStep  = 3.0;   // World units per sub-quad (halved for finer slope fidelity)
    const int    maxSteps    = 80;    // Safety cap on sub-division count

    final tm       = gameState.infiniteTerrainManager;
    final vertices = <double>[];
    final indices  = <int>[];
    var   vertexCount = 0;

    for (final seg in segments) {
      if (seg.length < 0.1) continue;

      final totalDx = seg.x2 - seg.x1;
      final totalDz = seg.z2 - seg.z1;

      // Subdivide the segment so height samples follow the terrain contour.
      final steps = (seg.length / subdivStep).ceil().clamp(1, maxSteps);

      // Outer (layer-0) half-width used as the reference for per-corner
      // terrain sampling; inner layers interpolate between centerline and
      // outer heights so that the slope is correctly reflected at all widths.
      final outerHw = seg.thickness / 2;

      for (int step = 0; step < steps; step++) {
        final t0 = step       / steps;
        final t1 = (step + 1) / steps;

        final sx1 = seg.x1 + totalDx * t0;
        final sz1 = seg.z1 + totalDz * t0;
        final sx2 = seg.x1 + totalDx * t1;
        final sz2 = seg.z1 + totalDz * t1;

        // Perpendicular in XZ plane for quad width
        final subDx  = sx2 - sx1;
        final subDz  = sz2 - sz1;
        final subLen = math.sqrt(subDx * subDx + subDz * subDz);
        if (subLen < 0.001) continue;

        final perpX = -subDz / subLen;
        final perpZ =  subDx / subLen;

        // Outer-layer corner XZ positions
        final oc1x = sx1 - perpX * outerHw;  final oc1z = sz1 - perpZ * outerHw;
        final oc2x = sx1 + perpX * outerHw;  final oc2z = sz1 + perpZ * outerHw;
        final oc3x = sx2 + perpX * outerHw;  final oc3z = sz2 + perpZ * outerHw;
        final oc4x = sx2 - perpX * outerHw;  final oc4z = sz2 - perpZ * outerHw;

        // Sample terrain height at all 6 reference positions: the 4 outer
        // corners plus the 2 centerline endpoints.  Inner layers lerp between
        // the centerline and the outer heights proportionally to their width.
        // Reason: this correctly tilts each quad to match the terrain slope in
        // both the along-line and cross-line directions simultaneously.
        double cy1, cy2, oc1y, oc2y, oc3y, oc4y;
        if (tm != null) {
          cy1  = tm.getTerrainHeight(sx1,  sz1)  + hoverOffset;
          cy2  = tm.getTerrainHeight(sx2,  sz2)  + hoverOffset;
          oc1y = tm.getTerrainHeight(oc1x, oc1z) + hoverOffset;
          oc2y = tm.getTerrainHeight(oc2x, oc2z) + hoverOffset;
          oc3y = tm.getTerrainHeight(oc3x, oc3z) + hoverOffset;
          oc4y = tm.getTerrainHeight(oc4x, oc4z) + hoverOffset;
        } else {
          cy1 = cy2 = oc1y = oc2y = oc3y = oc4y = hoverOffset;
        }

        // Three wispy layers per sub-quad (wide + faint → narrow + bright)
        for (int layer = 0; layer < 3; layer++) {
          final halfWidth = seg.thickness * (1.0 - layer * 0.25) / 2;
          final alpha     = 0.8 - layer * 0.2;

          // Fraction of the outer half-width this layer occupies.
          // lerpT = 1.0 for layer-0 (exact sampled corners), < 1.0 for
          // inner layers (lerp toward the sampled centerline height).
          final lerpT = outerHw > 0 ? halfWidth / outerHw : 1.0;

          // Corner XZ positions for this layer
          final c1x = sx1 - perpX * halfWidth;  final c1z = sz1 - perpZ * halfWidth;
          final c2x = sx1 + perpX * halfWidth;  final c2z = sz1 + perpZ * halfWidth;
          final c3x = sx2 + perpX * halfWidth;  final c3z = sz2 + perpZ * halfWidth;
          final c4x = sx2 - perpX * halfWidth;  final c4z = sz2 - perpZ * halfWidth;

          // Lerped Y: inner layers sit proportionally between centerline and
          // the outer corner heights so all three layers hug the same surface.
          final c1y = cy1 + (oc1y - cy1) * lerpT;
          final c2y = cy1 + (oc2y - cy1) * lerpT;
          final c3y = cy2 + (oc3y - cy2) * lerpT;
          final c4y = cy2 + (oc4y - cy2) * lerpT;

          final r = 0.2 * alpha;
          final g = 0.5 * alpha;
          final b = 1.0 * alpha;

          vertices.addAll([c1x, c1y, c1z, r, g, b]);
          vertices.addAll([c2x, c2y, c2z, r, g, b]);
          vertices.addAll([c3x, c3y, c3z, r, g, b]);
          vertices.addAll([c4x, c4y, c4z, r, g, b]);

          final base = vertexCount;
          indices.addAll([base, base + 1, base + 2, base, base + 2, base + 3]);
          vertexCount += 4;
        }
      }
    }

    if (vertices.isEmpty) {
      return Mesh.cube(size: 0.01, color: Vector3(0, 0, 0));
    }

    return Mesh.fromVerticesAndIndices(
      vertices: vertices,
      indices: indices,
      vertexStride: 6, // x, y, z, r, g, b
    );
  }
}
