import 'dart:html' as html;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math.dart' hide Colors;

import '../rendering3d/webgl_renderer.dart';
import '../rendering3d/camera3d.dart';
import '../rendering3d/mesh.dart';
import '../rendering3d/math/transform3d.dart';
import '../rendering3d/terrain_generator.dart';
import '../rendering3d/infinite_terrain_manager.dart';
import '../rendering3d/game_config_terrain.dart';
import '../rendering3d/player_mesh.dart';
import '../game/controllers/input_manager.dart';
import '../models/game_action.dart';
import '../ai/ollama_client.dart';
import '../models/item.dart';
import '../models/projectile.dart';
import '../models/ally.dart';
import '../models/ai_chat_message.dart';
import '../models/monster.dart';
import '../models/monster_ontology.dart';
import 'ai/ally_strategy.dart';
import 'ai/tactical_positioning.dart';
import 'state/game_config.dart';
import 'state/game_state.dart';
import 'state/abilities_config.dart';
import 'systems/physics_system.dart';
import 'systems/ability_system.dart';
import 'systems/ai_system.dart';
import 'systems/input_system.dart';
import 'systems/render_system.dart';
import 'ui/instructions_overlay.dart';
import 'ui/monster_hud.dart';
import 'ui/ai_chat_panel.dart';
import 'ui/player_hud.dart';
import 'ui/allies_panel.dart';
import 'ui/formation_panel.dart';
import 'ui/draggable_panel.dart';
import 'ui/ally_command_panels.dart';
import 'ui/ally_commands_panel.dart';
import 'ui/ui_config.dart';
import 'ui/abilities_modal.dart';
import 'ui/character_panel.dart';
import 'ui/bag_panel.dart';
import 'ui/dps_panel.dart';
import 'ui/cast_bar.dart';
import 'ui/mana_bar.dart';
import 'ui/damage_indicators.dart';
import 'ui/unit_frames/unit_frames.dart';
import '../models/target_dummy.dart';
import '../main.dart' show globalInterfaceConfig;
import 'state/action_bar_config.dart';
import 'state/ability_override_manager.dart';
import 'state/mana_config.dart';
import 'state/custom_options_manager.dart';
import 'state/custom_ability_manager.dart';
import 'state/item_config.dart';
import 'state/custom_item_manager.dart';
import 'state/wind_config.dart';
import 'state/wind_state.dart';
import 'state/minimap_config.dart';
import 'state/minimap_state.dart';
import 'state/building_config.dart';
import 'state/goals_config.dart';
import 'state/macro_config.dart';
import 'state/macro_manager.dart';
import 'state/gameplay_settings.dart';
import 'data/stances/stances.dart';
import 'state/ability_order_manager.dart';
import 'ui/minimap/minimap_widget.dart';
import 'ui/minimap/minimap_ping_overlay.dart';
import 'ui/building_panel.dart';
import 'ui/goals_panel.dart';
import 'ui/warrior_spirit_panel.dart';
import 'ui/chat_panel.dart';
import 'ui/stance_selector.dart';
import 'ui/stance_effects_overlay.dart';
import 'ui/channel_effects_overlay.dart';
import 'ui/macro_builder_panel.dart';
import 'systems/entity_picking_system.dart';
import 'systems/building_system.dart';
import 'systems/goal_system.dart';
import 'systems/macro_system.dart';
import 'ai/warrior_spirit.dart';
import 'effects/aura_system.dart';
// Note: WindIndicator replaced by minimap border wind arrow

part 'game3d_widget_init.dart';
part 'game3d_widget_update.dart';
part 'game3d_widget_input.dart';
part 'game3d_widget_commands.dart';
part 'game3d_widget_ui.dart';
part 'game3d_widget_ui_helpers.dart';

/// Abstract base holding all instance fields shared across mixin parts.
///
/// Reason: Dart does not allow `mixin M on C` when C itself uses `with M`
/// (that creates a supertype-of-itself circularity).  Declaring fields here
/// and having every mixin use `on _GameStateBase` breaks the cycle while
/// still giving each mixin full access to the shared state.
///
/// Abstract method stubs allow sibling mixins to call each other's methods
/// without type errors — the concrete `_Game3DState` (which mixes in all
/// parts) provides all the implementations.
abstract class _GameStateBase extends State<Game3D> {
  // Canvas element for WebGL
  late html.CanvasElement canvas;
  late String canvasId;

  // Core systems
  WebGLRenderer? renderer;
  Camera3D? camera;
  InputManager? inputManager;
  OllamaClient? ollamaClient;

  // Game state - centralized state management
  final GameState gameState = GameState();

  // Reason: explicit FocusNode so we can reclaim keyboard focus from text fields
  // after the user interacts with editor panels or clicks on the game world.
  final FocusNode _gameFocusNode = FocusNode(debugLabel: 'Game3D');

  // Reason: lives in base so _WidgetUpdateMixin (reads/writes each frame) and
  // _WidgetCommandsMixin (no longer owns it) share a single field.
  double _flightDurationAccum = 0;

  // ==================== ABSTRACT CROSS-MIXIN INTERFACE ====================
  // Each stub is declared here so every mixin (which uses `on _GameStateBase`)
  // can call methods defined in sibling mixins.  Concrete implementations are
  // provided by the respective mixin parts mixed into _Game3DState.

  // --- from _Game3DState ---
  void _startGameLoop();

  // --- from _WidgetCommandsMixin ---
  bool _isVisible(String id);
  Widget _draggable(String id, Widget child, {double width = 200, double height = 100});
  void _updatePlayerAuraColor();
  void _refreshAllAuraColors();
  void _handleAllyCommands();
  void _updateAuraPositions();
  void _logMonsterAI(String text, {required bool isInput});
  void _activateMonsterAbility1();
  void _activateMonsterAbility2();
  void _activateMonsterAbility3();
  void _addAlly();
  void _removeAlly();
  void _activateAllyAbility(Ally ally);
  void _changeFormation(FormationType newFormation);
  AllyCommand _getCurrentAllyCommand();
  void _setAllyCommand(AllyCommand command);

  // --- from _WidgetInputMixin ---
  bool _isTextFieldFocused();
  void _onKeyEvent(KeyEvent event);
  void _handleWorldClick(PointerDownEvent event);
  void _handleMinimapPing(double worldX, double worldZ);
  void _activateAbility1();
  void _activateAbility2();
  void _activateAbility3();
  void _activateAbility4();
  void _activateAbility5();
  void _activateAbility6();
  void _activateAbility7();
  void _activateAbility8();
  void _activateAbility9();
  void _activateAbility10();
  void _handleAbilityDropped(int slotIndex, String abilityName);
  void _handleClassLoaded(String category);

  // --- from _WidgetUIHelpersMixin ---
  Widget _buildCombatHUD();
  Widget _buildAllyControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  });
}

/// Game3D - Main 3D game widget using custom WebGL renderer
///
/// This replaces the Flame-based WarchiefGame with true 3D rendering.
/// Supports dual-axis camera rotation (J/L for yaw, N/M for pitch).
///
/// Usage:
/// ```dart
/// MaterialApp(
///   home: Scaffold(
///     body: Game3D(),
///   ),
/// )
/// ```
class Game3D extends StatefulWidget {
  const Game3D({Key? key}) : super(key: key);

  @override
  State<Game3D> createState() => _Game3DState();
}

class _Game3DState extends _GameStateBase
    with _WidgetInitMixin, _WidgetUpdateMixin, _WidgetInputMixin,
         _WidgetCommandsMixin, _WidgetUIMixin, _WidgetUIHelpersMixin {
  @override
  void initState() {
    super.initState();
    canvasId = 'game3d_canvas_${DateTime.now().millisecondsSinceEpoch}';

    // Initialize input manager
    inputManager = InputManager();

    // Initialize Ollama client for AI
    ollamaClient = OllamaClient();

    // Initialize game config (JSON defaults + SharedPreferences overrides)
    _initializeGameConfig();

    // Initialize action bar config for ability slot assignments
    _initializeActionBarConfig();

    // Initialize ability override manager for custom ability edits
    _initializeAbilityOverrides();

    // Initialize mana config (JSON defaults + SharedPreferences overrides)
    _initializeManaConfig();

    // Initialize wind config (JSON defaults for wind simulation)
    _initializeWindConfig();

    // Initialize minimap config (JSON defaults for minimap display)
    _initializeMinimapConfig();

    // Initialize building config (JSON defaults for building definitions)
    _initializeBuildingConfig();

    // Initialize custom options manager (custom dropdown values + effect descriptions)
    _initializeCustomOptions();

    // Initialize custom ability manager (user-created abilities)
    _initializeCustomAbilities();

    // Initialize item config (power level weights, sentience thresholds)
    _initializeItemConfig();

    // Initialize custom item manager (user-created items)
    _initializeCustomItems();

    // Initialize goals config (JSON defaults for goal definitions)
    _initializeGoalsConfig();

    // Initialize macro config and manager (macro system)
    _initializeMacroConfig();

    // Initialize gameplay settings (attunement toggles, etc.)
    _initializeGameplaySettings();

    // Initialize stance registry (JSON definitions for exotic stances)
    _initializeStanceRegistry();

    // Initialize stance override manager for custom stance edits
    _initializeStanceOverrides();

    // Initialize ability order manager for category reordering in codex
    _initializeAbilityOrder();

    // Initialize player inventory with sample items
    _initializeInventory();

    // Create canvas element immediately
    _initializeGame();
  }

  void _startGameLoop() {
    // lastTimestamp will be set on the first rAF callback
    gameState.lastTimestamp = null;
    print('Starting game loop...');

    void gameLoop(num timestamp) {
      if (!mounted) return;

      // Use the requestAnimationFrame timestamp (DOMHighResTimeStamp from
      // performance.now()) for dt calculation.  This is monotonic,
      // sub-millisecond precision, and synchronized with the display refresh
      // — unlike DateTime.now() which has only millisecond precision and can
      // drift due to NTP sync, privacy coarsening, or system clock changes.
      final tsMs = timestamp.toDouble();
      final dt = gameState.lastTimestamp != null
          ? ((tsMs - gameState.lastTimestamp!) / 1000.0).clamp(0.0, 0.1)
          : 0.016; // Default to ~60fps on first frame
      gameState.lastTimestamp = tsMs;

      gameState.frameCount++;

      // Log every 60 frames (~1 second at 60fps)
      if (gameState.frameCount % 60 == 0) {
        print('Frame ${gameState.frameCount} - dt: ${dt.toStringAsFixed(4)}s - Terrain: ${gameState.terrainTiles?.length ?? 0} tiles');
        // Reason: Periodic aura refresh catches all config change paths (drag-drop, load-class, character switch)
        _refreshAllAuraColors();
      }

      _update(dt, tsMs / 1000.0);
      _render();

      // Update UI — every frame during active casts/windups for smooth
      // progress bars, otherwise every 10 frames to reduce rebuild overhead
      final needsFrequentUiUpdate = gameState.isCasting || gameState.isWindingUp;
      if (mounted && (needsFrequentUiUpdate || gameState.frameCount % 10 == 0)) {
        setState(() {});
      }

      gameState.animationFrameId = html.window.requestAnimationFrame(gameLoop);
    }

    gameState.animationFrameId = html.window.requestAnimationFrame(gameLoop);
    print('Game loop started - animationFrameId: ${gameState.animationFrameId}');
  }

  @override
  void dispose() {
    // Stop game loop
    if (gameState.animationFrameId != null) {
      html.window.cancelAnimationFrame(gameState.animationFrameId!);
    }

    // Cleanup renderer
    renderer?.dispose();

    // Remove canvas from DOM
    canvas.remove();

    _gameFocusNode.dispose();

    super.dispose();
  }
}

class Math {
  static double sin(double radians) => math.sin(radians);
  static double cos(double radians) => math.cos(radians);
}
