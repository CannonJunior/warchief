# 3D Isometric Game Platform Design
**Project**: Warchief 3D Isometric Game
**Target Platform**: Web (Development), Future: Multi-platform
**Tech Stack**: Flutter + Dart, Flame Engine, Ollama + MCP
**Date**: 2025-10-29

---

## Executive Summary

This document outlines the architecture for a 3D isometric game platform built with Flutter/Dart, targeting web deployment. The platform features WoW-inspired character controls, AI-powered NPC companions using local LLMs (Ollama + MCP), and a flexible UI system supporting easy asset replacement via SVG/PNG files.

---

## 1. Architecture Overview

### 1.1 Core Technology Stack

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter Web App                       │
│  ┌───────────────────────────────────────────────────┐  │
│  │         Flame Engine (Game Loop & Rendering)      │  │
│  │  ┌─────────────┐  ┌──────────────┐  ┌──────────┐ │  │
│  │  │   Flame     │  │ Flame Tiled  │  │  Flame   │ │  │
│  │  │  Isometric  │  │  Integration │  │   FCS    │ │  │
│  │  └─────────────┘  └──────────────┘  └──────────┘ │  │
│  └───────────────────────────────────────────────────┘  │
│                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   Input      │  │  UI Layer    │  │   Game       │  │
│  │   Manager    │  │  (SVG/PNG)   │  │   State      │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
                          ↓ HTTP/REST API
┌─────────────────────────────────────────────────────────┐
│           Local Ollama Server (Port 11434)              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ Llama 3.1 8B │  │ Mistral 7B   │  │  Qwen 2.5    │  │
│  │  (Function   │  │  (Dialogue)  │  │  (Strategy)  │  │
│  │   Calling)   │  │              │  │              │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
                          ↓ MCP Protocol
┌─────────────────────────────────────────────────────────┐
│            Model Context Protocol (MCP)                  │
│  - Game State Context                                    │
│  - NPC Personality Profiles                              │
│  - Action Tool Definitions                               │
│  - World Knowledge Base                                  │
└─────────────────────────────────────────────────────────┘
```

### 1.2 Key Packages & Dependencies

**Core Game Engine:**
- `flame: ^1.19.0` - Main game engine
- `flame_isometric: ^0.8.0` - Isometric tile rendering
- `flame_tiled: ^1.21.0` - Tiled map integration

**Graphics & UI:**
- `flutter_svg: ^2.0.0` - SVG rendering with hot-reload support
- `vector_graphics: ^1.1.0` - Optimized SVG compilation

**Input Handling:**
- Built-in Flutter `Focus`, `FocusableActionDetector`, `MouseRegion`
- Custom input manager for rebindable controls

**AI/NPC Integration:**
- `http: ^1.2.0` - Communication with local Ollama server
- Custom MCP client implementation
- `shared_preferences: ^2.2.0` - Keybind persistence

**State Management:**
- `riverpod: ^2.5.0` - Game state management
- `freezed: ^2.5.0` - Immutable state classes

---

## 2. Control System Design

### 2.1 WoW-Inspired Control Scheme

Based on research of World of Warcraft's control system, the following scheme is implemented:

#### **Movement Controls**
| Key(s) | Action | Default | Rebindable |
|--------|--------|---------|------------|
| W | Move Forward | ✓ | ✓ |
| S | Move Backward | ✓ | ✓ |
| A | Strafe Left | ✓ | ✓ |
| D | Strafe Right | ✓ | ✓ |
| Q | Rotate Left / Strafe Left | ✓ | ✓ |
| E | Rotate Right / Strafe Right | ✓ | ✓ |
| Space | Jump | ✓ | ✓ |
| Mouse + Right Click | Camera Rotation | ✓ | ✗ |
| Both Mouse Buttons | Move Forward (Auto-run) | ✓ | ✗ |

#### **Action Controls**
| Key(s) | Action | Rebindable |
|--------|--------|------------|
| 1-9 | Action Bar Slot 1-9 | ✓ |
| 0 | Action Bar Slot 10 | ✓ |
| - | Action Bar Slot 11 | ✓ |
| = | Action Bar Slot 12 | ✓ |

### 2.2 Input Manager Architecture

```dart
/// Core input manager - handles all keyboard/mouse input
class InputManager {
  final Map<LogicalKeyboardKey, GameAction> _keyBindings;
  final Set<LogicalKeyboardKey> _pressedKeys;
  final Map<GameAction, VoidCallback> _actionCallbacks;

  /// Registers a callback for a game action
  void bindAction(GameAction action, VoidCallback callback);

  /// Rebinds a key to a different action
  Future<void> rebindKey(GameAction action, LogicalKeyboardKey newKey);

  /// Handles raw keyboard events
  void handleKeyEvent(KeyEvent event);

  /// Saves keybinds to persistent storage
  Future<void> saveBindings();

  /// Loads keybinds from persistent storage
  Future<void> loadBindings();
}

/// Game actions enum
enum GameAction {
  moveForward,
  moveBackward,
  strafeLeft,
  strafeRight,
  rotateLeft,
  rotateRight,
  jump,
  actionBar1,
  actionBar2,
  // ... up to actionBar12
  petAttack,
  petFollow,
  petStay,
  petPassive,
  petDefensive,
  petAggressive,
}
```

### 2.3 Camera System

```dart
/// Camera controller with WoW-style mouse controls
class IsometricCameraController extends Component {
  double rotationAngle = 0.0; // 0-360 degrees
  double zoomLevel = 1.0;
  double tiltAngle = 45.0; // Isometric default

  /// Handles right-click drag for camera rotation
  void onMouseDrag(PointerMoveEvent event);

  /// Handles scroll wheel for zoom
  void onMouseScroll(PointerScrollEvent event);

  /// Smoothly interpolates camera to target position
  void followTarget(Vector2 targetPosition);
}
```

---

## 3. NPC/Companion Control System

### 3.1 WoW Pet Command System

Based on research, WoW uses a command system with stances and direct commands:

**Command Types:**
- **Stances**: Passive, Defensive, Aggressive
- **Direct Commands**: Attack, Follow, Stay, Move To
- **Abilities**: Class-specific abilities on Pet Action Bar

### 3.2 AI-Powered NPC Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Player Controller                     │
└───────────────────────┬─────────────────────────────────┘
                        │
        ┌───────────────┼───────────────┐
        │               │               │
┌───────▼───────┐ ┌────▼──────┐ ┌──────▼────────┐
│  NPC Follower │ │NPC Follower│ │ NPC Follower  │
│   "Warrior"   │ │  "Healer"  │ │    "Mage"     │
│               │ │            │ │               │
│ ┌───────────┐ │ │┌──────────┐│ │ ┌───────────┐ │
│ │ Ollama    │ │ ││ Ollama   ││ │ │ Ollama    │ │
│ │ Llama 3.1 │ │ ││ Mistral  ││ │ │ Qwen 2.5  │ │
│ │ + MCP     │ │ ││ + MCP    ││ │ │ + MCP     │ │
│ └───────────┘ │ │└──────────┘│ │ └───────────┘ │
└───────────────┘ └────────────┘ └───────────────┘
```

### 3.3 NPC Control Modes

#### **Mode 1: Intent-Based Control (High-Level)**
Player provides strategic intent, NPC uses LLM to determine actions:

```dart
/// High-level intent system
class NPCIntentController {
  final String npcPersonality; // Loaded from personality file
  final OllamaMCPClient mcpClient;

  /// Player provides intent like "Focus on healing" or "Protect the mage"
  Future<NPCBehavior> interpretIntent(String playerIntent) async {
    final context = _buildGameStateContext();
    final response = await mcpClient.sendIntent(
      personality: npcPersonality,
      intent: playerIntent,
      context: context,
    );
    return _parseIntoBehavior(response);
  }
}

/// Examples of player intents:
/// - "Stay close and heal me when I'm low"
/// - "Attack enemies I'm fighting"
/// - "Focus on crowd control"
/// - "Defend yourself but don't engage"
```

#### **Mode 2: Direct Action Control (Low-Level)**
Player issues specific commands similar to WoW pet controls:

```dart
/// Direct command system
class NPCDirectController {
  /// WoW-style direct commands
  void commandAttack(Entity target);
  void commandFollow();
  void commandStay();
  void commandMoveTo(Vector2 position);

  /// Stance control
  void setStance(NPCStance stance); // Passive, Defensive, Aggressive

  /// Ability activation (number keys)
  void useAbility(int slotNumber);
}

enum NPCStance {
  passive,    // Takes no action unless commanded
  defensive,  // Attacks when player is threatened
  aggressive, // Actively seeks and engages enemies
}
```

### 3.4 MCP Integration Architecture

```dart
/// Model Context Protocol client for Ollama integration
class OllamaMCPClient {
  final String ollamaBaseUrl = 'http://localhost:11434';
  final http.Client httpClient;

  /// Sends intent with full game context to LLM
  Future<MCPResponse> sendIntent({
    required String personality,
    required String intent,
    required GameStateContext context,
  }) async {
    final prompt = _buildMCPPrompt(personality, intent, context);

    final response = await httpClient.post(
      Uri.parse('$ollamaBaseUrl/api/chat'),
      body: jsonEncode({
        'model': 'llama3.1:8b-instruct-q8_0', // Best for function calling
        'messages': [
          {'role': 'system', 'content': personality},
          {'role': 'user', 'content': prompt},
        ],
        'tools': _getAvailableTools(), // MCP tool definitions
        'stream': false,
      }),
    );

    return MCPResponse.fromJson(jsonDecode(response.body));
  }

  /// Defines available tools/actions for the NPC
  List<Map<String, dynamic>> _getAvailableTools() {
    return [
      {
        'type': 'function',
        'function': {
          'name': 'move_to_position',
          'description': 'Move to a specific position',
          'parameters': {
            'type': 'object',
            'properties': {
              'x': {'type': 'number'},
              'y': {'type': 'number'},
            },
            'required': ['x', 'y'],
          },
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'attack_target',
          'description': 'Attack a specific target',
          'parameters': {
            'type': 'object',
            'properties': {
              'target_id': {'type': 'string'},
            },
            'required': ['target_id'],
          },
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'use_ability',
          'description': 'Use a specific ability',
          'parameters': {
            'type': 'object',
            'properties': {
              'ability_name': {'type': 'string'},
              'target_id': {'type': 'string'},
            },
            'required': ['ability_name'],
          },
        },
      },
      // Additional tools: heal, buff, crowd_control, etc.
    ];
  }
}

/// Game state context passed to LLM
class GameStateContext {
  final Vector2 playerPosition;
  final double playerHealthPercent;
  final List<NearbyEntity> nearbyEnemies;
  final List<NearbyEntity> nearbyAllies;
  final String currentObjective;

  Map<String, dynamic> toJson() {
    return {
      'player': {
        'position': {'x': playerPosition.x, 'y': playerPosition.y},
        'health_percent': playerHealthPercent,
      },
      'nearby_enemies': nearbyEnemies.map((e) => e.toJson()).toList(),
      'nearby_allies': nearbyAllies.map((e) => e.toJson()).toList(),
      'objective': currentObjective,
    };
  }
}
```

### 3.5 NPC Personality System

Each NPC has a master prompt (personality file) that defines its behavior:

```
# personalities/warrior_companion.txt

You are Throk, a seasoned warrior companion who follows the player's character. Your role is to:

## Personality Traits
- Brave and protective
- Prefers close-combat and direct confrontation
- Tends to charge into battle when in aggressive stance
- Loyal and follows orders dutifully

## Combat Behavior
- In AGGRESSIVE stance: Actively seek enemies and engage
- In DEFENSIVE stance: Only attack when player or allies are threatened
- In PASSIVE stance: Only act when directly commanded

## Decision Making
When given high-level intent like "protect the healer", you should:
1. Position yourself between enemies and the healer
2. Use taunt/crowd control abilities on enemies targeting the healer
3. Stay within range to intercept attacks

## Available Abilities
- Shield Bash (stun)
- Charge (gap closer)
- Taunt (force enemy to attack you)
- Defensive Stance (reduce damage taken)
- Whirlwind (AoE damage)

When responding, use the provided tools to execute actions. Consider the current game state context and player's intent before acting.
```

---

## 4. UI Configuration System

### 4.1 Asset-Based UI Components

All UI elements are defined as configurable components backed by SVG/PNG files:

```
assets/
├── ui/
│   ├── action_bars/
│   │   ├── action_bar_frame.svg
│   │   ├── action_slot_empty.svg
│   │   ├── action_slot_filled.svg
│   │   └── action_slot_cooldown.svg
│   ├── health_bars/
│   │   ├── health_frame.svg
│   │   ├── health_fill_red.png
│   │   ├── mana_fill_blue.png
│   │   └── energy_fill_yellow.png
│   ├── pet_frames/
│   │   ├── pet_portrait_frame.svg
│   │   ├── pet_action_bar.svg
│   │   └── pet_stance_icons.svg
│   ├── character_portraits/
│   │   ├── player_portrait_frame.svg
│   │   └── npc_portrait_frame.svg
│   └── buttons/
│       ├── button_default.svg
│       ├── button_hover.svg
│       └── button_pressed.svg
├── icons/
│   ├── abilities/
│   ├── items/
│   └── buffs/
└── ui_config.json
```

### 4.2 UI Configuration Schema

```json
{
  "ui_version": "1.0.0",
  "components": {
    "action_bar": {
      "type": "ActionBar",
      "position": { "x": "center", "y": "bottom", "offset_y": 20 },
      "slots": 12,
      "assets": {
        "frame": "ui/action_bars/action_bar_frame.svg",
        "slot_empty": "ui/action_bars/action_slot_empty.svg",
        "slot_filled": "ui/action_bars/action_slot_filled.svg",
        "cooldown_overlay": "ui/action_bars/action_slot_cooldown.svg"
      },
      "dimensions": { "width": 600, "height": 60 },
      "slot_size": 48,
      "slot_spacing": 4
    },
    "player_health_bar": {
      "type": "ResourceBar",
      "position": { "x": "left", "y": "top", "offset_x": 20, "offset_y": 20 },
      "assets": {
        "frame": "ui/health_bars/health_frame.svg",
        "fill": "ui/health_bars/health_fill_red.png"
      },
      "dimensions": { "width": 200, "height": 30 },
      "animate_changes": true,
      "show_text": true
    },
    "pet_frame": {
      "type": "PetFrame",
      "position": { "x": "left", "y": "top", "offset_x": 20, "offset_y": 80 },
      "assets": {
        "portrait_frame": "ui/pet_frames/pet_portrait_frame.svg",
        "action_bar": "ui/pet_frames/pet_action_bar.svg",
        "stance_passive": "ui/pet_frames/stance_passive.svg",
        "stance_defensive": "ui/pet_frames/stance_defensive.svg",
        "stance_aggressive": "ui/pet_frames/stance_aggressive.svg"
      },
      "show_health": true,
      "show_stance": true,
      "show_abilities": true
    }
  },
  "themes": {
    "default": "dark_fantasy",
    "available": ["dark_fantasy", "minimalist", "pixel_art"]
  }
}
```

### 4.3 UI Component Implementation

```dart
/// Base class for all UI components
abstract class UIComponent extends PositionComponent {
  final UIComponentConfig config;
  late final Map<String, SvgPicture> svgAssets;
  late final Map<String, Image> pngAssets;

  UIComponent({required this.config});

  @override
  Future<void> onLoad() async {
    await _loadAssets();
    _buildComponent();
  }

  Future<void> _loadAssets() async {
    // Load all SVG/PNG assets defined in config
    for (final entry in config.assets.entries) {
      if (entry.value.endsWith('.svg')) {
        svgAssets[entry.key] = await _loadSvg(entry.value);
      } else {
        pngAssets[entry.key] = await _loadPng(entry.value);
      }
    }
  }

  void _buildComponent();

  /// Hot-reload support: reload assets when changed
  Future<void> reloadAssets() async {
    svgAssets.clear();
    pngAssets.clear();
    await _loadAssets();
    _buildComponent();
  }
}

/// Example: Action bar component
class ActionBarComponent extends UIComponent {
  final List<ActionSlot> slots = [];

  @override
  void _buildComponent() {
    // Create action slots using loaded assets
    for (int i = 0; i < config.slotCount; i++) {
      final slot = ActionSlot(
        slotNumber: i + 1,
        emptyAsset: svgAssets['slot_empty']!,
        filledAsset: svgAssets['slot_filled']!,
        cooldownAsset: svgAssets['cooldown_overlay']!,
      );
      slots.add(slot);
      add(slot);
    }
  }

  void assignAction(int slotNumber, GameAction action) {
    slots[slotNumber - 1].assignAction(action);
  }
}
```

### 4.4 Asset Hot-Reload System

```dart
/// Development tool: watches for asset changes and hot-reloads UI
class UIAssetWatcher {
  final FileSystemWatcher watcher;
  final List<UIComponent> watchedComponents;

  void startWatching(String assetDirectory) {
    watcher.watch(assetDirectory).listen((event) {
      if (event.type == FileSystemEvent.modify) {
        _handleAssetChange(event.path);
      }
    });
  }

  void _handleAssetChange(String assetPath) async {
    // Find components using this asset
    for (final component in watchedComponents) {
      if (component.config.usesAsset(assetPath)) {
        await component.reloadAssets();
        print('Hot-reloaded: $assetPath');
      }
    }
  }
}
```

---

## 5. Game Component Structure

### 5.1 Flame Component System (FCS)

```
GameWorld (FlameGame)
├── IsometricMapComponent
│   ├── TerrainLayer
│   ├── ObjectLayer
│   └── NavigationMesh
├── EntityManager
│   ├── PlayerCharacter
│   │   └── PlayerController
│   ├── NPCFollowers[]
│   │   ├── NPCController (AI or Direct)
│   │   ├── NPCAnimator
│   │   └── NPCHealthBar
│   └── Enemies[]
├── CameraController
├── InputManager
├── UILayer
│   ├── ActionBarComponent
│   ├── HealthBarComponent
│   ├── PetFrameComponent[]
│   └── MinimapComponent
└── AIManager
    ├── OllamaMCPClient
    └── NPCBehaviorTree[]
```

### 5.2 Player Character Component

```dart
class PlayerCharacter extends PositionComponent with HasGameRef {
  // Movement
  Vector2 velocity = Vector2.zero();
  double moveSpeed = 150.0; // pixels per second
  double rotationSpeed = 3.0; // radians per second

  // State
  double health = 100.0;
  double maxHealth = 100.0;
  bool isJumping = false;

  // References
  late PlayerController controller;
  late PlayerAnimator animator;

  @override
  void update(double dt) {
    super.update(dt);

    // Apply movement from controller
    position += velocity * dt;

    // Update animations
    animator.update(dt);

    // Check collisions
    _checkCollisions();
  }

  void moveForward() {
    velocity.y = -moveSpeed;
  }

  void strafeLeft() {
    velocity.x = -moveSpeed;
  }

  // ... other movement methods
}

class PlayerController {
  final PlayerCharacter character;
  final InputManager inputManager;

  PlayerController(this.character, this.inputManager) {
    _bindActions();
  }

  void _bindActions() {
    inputManager.bindAction(GameAction.moveForward, () => character.moveForward());
    inputManager.bindAction(GameAction.strafeLeft, () => character.strafeLeft());
    // ... bind all actions
  }
}
```

### 5.3 NPC Follower Component

```dart
class NPCFollowerComponent extends PositionComponent {
  // Identity
  final String npcId;
  final String personalityFile;

  // AI Controller (can be swapped between modes)
  late NPCController controller;

  // State
  NPCStance stance = NPCStance.defensive;
  double health = 100.0;
  List<Ability> abilities = [];

  // AI Integration
  late OllamaMCPClient mcpClient;
  String? currentIntent;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Load personality from file
    final personality = await loadPersonality(personalityFile);

    // Initialize MCP client
    mcpClient = OllamaMCPClient(personality: personality);

    // Start with intent-based controller
    controller = NPCIntentController(
      npc: this,
      mcpClient: mcpClient,
    );
  }

  /// Switch between AI and direct control
  void switchControlMode(NPCControlMode mode) {
    switch (mode) {
      case NPCControlMode.intentBased:
        controller = NPCIntentController(npc: this, mcpClient: mcpClient);
        break;
      case NPCControlMode.direct:
        controller = NPCDirectController(npc: this);
        break;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    controller.update(dt);
  }
}

enum NPCControlMode {
  intentBased,  // High-level AI control
  direct,       // Player issues specific commands
}
```

---

## 6. Keybind System Design

### 6.1 Keybind Manager

```dart
class KeybindManager {
  // Default keybindings
  static final Map<GameAction, LogicalKeyboardKey> defaultBindings = {
    GameAction.moveForward: LogicalKeyboardKey.keyW,
    GameAction.moveBackward: LogicalKeyboardKey.keyS,
    GameAction.strafeLeft: LogicalKeyboardKey.keyA,
    GameAction.strafeRight: LogicalKeyboardKey.keyD,
    GameAction.rotateLeft: LogicalKeyboardKey.keyQ,
    GameAction.rotateRight: LogicalKeyboardKey.keyE,
    GameAction.jump: LogicalKeyboardKey.space,
    GameAction.actionBar1: LogicalKeyboardKey.digit1,
    // ... all actions
  };

  // Current keybindings (loaded from storage)
  Map<GameAction, LogicalKeyboardKey> currentBindings = {};

  // Reverse lookup: key -> action
  Map<LogicalKeyboardKey, GameAction> keyToAction = {};

  Future<void> loadBindings() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('keybindings');

    if (saved != null) {
      final decoded = jsonDecode(saved) as Map<String, dynamic>;
      currentBindings = _deserializeBindings(decoded);
    } else {
      currentBindings = Map.from(defaultBindings);
    }

    _rebuildLookup();
  }

  Future<void> saveBindings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('keybindings', jsonEncode(_serializeBindings()));
  }

  Future<bool> rebindAction(GameAction action, LogicalKeyboardKey newKey) async {
    // Check if key is already bound
    if (keyToAction.containsKey(newKey)) {
      final existingAction = keyToAction[newKey]!;
      if (existingAction != action) {
        // Show warning: "Key already bound to ${existingAction.name}"
        return false;
      }
    }

    currentBindings[action] = newKey;
    _rebuildLookup();
    await saveBindings();
    return true;
  }

  void _rebuildLookup() {
    keyToAction.clear();
    currentBindings.forEach((action, key) {
      keyToAction[key] = action;
    });
  }

  GameAction? getActionForKey(LogicalKeyboardKey key) {
    return keyToAction[key];
  }

  void resetToDefaults() {
    currentBindings = Map.from(defaultBindings);
    _rebuildLookup();
    saveBindings();
  }
}
```

### 6.2 Keybind UI Component

```dart
/// UI for rebinding controls
class KeybindSettingsScreen extends StatefulWidget {
  @override
  _KeybindSettingsScreenState createState() => _KeybindSettingsScreenState();
}

class _KeybindSettingsScreenState extends State<KeybindSettingsScreen> {
  final KeybindManager keybindManager = KeybindManager();
  GameAction? listeningForAction;

  @override
  void initState() {
    super.initState();
    keybindManager.loadBindings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Keybindings')),
      body: ListView(
        children: [
          _buildSection('Movement', [
            GameAction.moveForward,
            GameAction.moveBackward,
            GameAction.strafeLeft,
            GameAction.strafeRight,
            GameAction.jump,
          ]),
          _buildSection('Action Bar', [
            GameAction.actionBar1,
            GameAction.actionBar2,
            // ... all 12 slots
          ]),
          _buildSection('Pet/NPC Control', [
            GameAction.petAttack,
            GameAction.petFollow,
            GameAction.petStay,
            GameAction.petPassive,
            GameAction.petDefensive,
            GameAction.petAggressive,
          ]),
          ElevatedButton(
            onPressed: () {
              keybindManager.resetToDefaults();
              setState(() {});
            },
            child: Text('Reset to Defaults'),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<GameAction> actions) {
    return ExpansionTile(
      title: Text(title),
      children: actions.map(_buildKeybindRow).toList(),
    );
  }

  Widget _buildKeybindRow(GameAction action) {
    final currentKey = keybindManager.currentBindings[action];
    final isListening = listeningForAction == action;

    return ListTile(
      title: Text(action.displayName),
      trailing: Focus(
        onKeyEvent: (node, event) {
          if (isListening && event is KeyDownEvent) {
            keybindManager.rebindAction(action, event.logicalKey);
            setState(() => listeningForAction = null);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: ElevatedButton(
          onPressed: () => setState(() => listeningForAction = action),
          style: ElevatedButton.styleFrom(
            backgroundColor: isListening ? Colors.orange : null,
          ),
          child: Text(
            isListening ? 'Press any key...' : currentKey?.keyLabel ?? 'Unbound',
          ),
        ),
      ),
    );
  }
}
```

---

## 7. Implementation Phases

### Phase 1: Core Infrastructure (Weeks 1-2)
- [ ] Set up Flutter web project with Flame engine
- [ ] Implement isometric tile rendering with Flame Isometric
- [ ] Create basic player character with WASD movement
- [ ] Implement camera controller with mouse controls
- [ ] Build input manager with keybind support

### Phase 2: UI System (Weeks 3-4)
- [ ] Design and implement UI configuration system
- [ ] Create asset-based UI components (action bars, health bars)
- [ ] Implement SVG/PNG loading and hot-reload
- [ ] Build keybind settings screen
- [ ] Create player portrait and resource bars

### Phase 3: Basic Combat & Actions (Weeks 5-6)
- [ ] Implement action bar system with 12 slots
- [ ] Create ability framework (cooldowns, costs, effects)
- [ ] Add basic enemies and combat mechanics
- [ ] Implement health/damage system
- [ ] Add animations for abilities and combat

### Phase 4: NPC Direct Control (Weeks 7-8)
- [ ] Create NPC follower component
- [ ] Implement WoW-style pet commands (Attack, Follow, Stay)
- [ ] Add stance system (Passive, Defensive, Aggressive)
- [ ] Build NPC UI frames and action bars
- [ ] Create NPC behavior tree for direct control mode

### Phase 5: Ollama + MCP Integration (Weeks 9-11)
- [ ] Set up local Ollama server integration
- [ ] Implement MCP client in Dart
- [ ] Create personality system (load from files)
- [ ] Build game state context serialization
- [ ] Define MCP tools (move, attack, use_ability, etc.)
- [ ] Test with Llama 3.1 8B for function calling

### Phase 6: Intent-Based AI Control (Weeks 12-14)
- [ ] Implement intent interpretation system
- [ ] Create high-level command parser
- [ ] Build AI decision-making loop
- [ ] Add context-aware behavior
- [ ] Test different personality profiles
- [ ] Optimize LLM prompts for game performance

### Phase 7: Advanced Features (Weeks 15-16)
- [ ] Add multiple NPC support (party system)
- [ ] Implement NPC progression (leveling, new abilities)
- [ ] Create quest/objective system
- [ ] Add NPC-to-NPC interactions
- [ ] Build formation system for multiple NPCs

### Phase 8: Polish & Optimization (Weeks 17-18)
- [ ] Optimize web build performance
- [ ] Add sound effects and music
- [ ] Implement save/load system
- [ ] Polish UI/UX
- [ ] Performance testing with multiple NPCs
- [ ] Documentation and tutorials

---

## 8. Technical Considerations

### 8.1 Performance Optimization

**Web Build Performance:**
- Use Flutter's CanvasKit renderer for best graphics quality
- Implement object pooling for frequently created/destroyed entities
- Optimize sprite sheets and texture atlases
- Use LOD (Level of Detail) for distant entities
- Lazy-load assets not immediately needed

**LLM Performance:**
- Cache LLM responses for common scenarios
- Batch NPC decision-making (not every frame)
- Use smaller quantized models (Q4 or Q8)
- Implement request queuing to avoid overwhelming Ollama
- Fall back to behavior trees when LLM is slow

### 8.2 Development Workflow

**Asset Pipeline:**
1. Designer creates/updates SVG/PNG in design tool
2. Export to `assets/ui/` directory
3. Update `ui_config.json` if new component
4. Hot-reload in development mode
5. Test in game

**NPC Personality Development:**
1. Write personality prompt in `personalities/` directory
2. Define available tools/actions in MCP client
3. Test with Ollama CLI first
4. Integrate into game
5. Iterate based on behavior testing

### 8.3 Configuration Files

**config/game_config.json:**
```json
{
  "server": {
    "port": 8008,
    "enable_hot_reload": true
  },
  "ollama": {
    "base_url": "http://localhost:11434",
    "default_model": "llama3.1:8b-instruct-q8_0",
    "request_timeout_ms": 5000,
    "max_concurrent_requests": 3
  },
  "game": {
    "max_npcs": 5,
    "npc_decision_interval_ms": 1000,
    "enable_ai_control": true,
    "default_npc_stance": "defensive"
  },
  "graphics": {
    "target_fps": 60,
    "enable_vsync": true,
    "tile_size": 64,
    "camera_zoom_min": 0.5,
    "camera_zoom_max": 2.0
  }
}
```

### 8.4 Project Structure

```
warchief/
├── lib/
│   ├── main.dart
│   ├── game/
│   │   ├── warchief_game.dart          # Main FlameGame class
│   │   ├── components/
│   │   │   ├── player_character.dart
│   │   │   ├── npc_follower.dart
│   │   │   ├── enemy.dart
│   │   │   └── projectile.dart
│   │   ├── controllers/
│   │   │   ├── input_manager.dart
│   │   │   ├── camera_controller.dart
│   │   │   ├── player_controller.dart
│   │   │   ├── npc_intent_controller.dart
│   │   │   └── npc_direct_controller.dart
│   │   ├── systems/
│   │   │   ├── combat_system.dart
│   │   │   ├── ability_system.dart
│   │   │   └── animation_system.dart
│   │   └── world/
│   │       ├── isometric_map.dart
│   │       └── navigation_mesh.dart
│   ├── ui/
│   │   ├── components/
│   │   │   ├── action_bar.dart
│   │   │   ├── health_bar.dart
│   │   │   ├── pet_frame.dart
│   │   │   └── minimap.dart
│   │   ├── config/
│   │   │   ├── ui_config.dart
│   │   │   └── ui_theme.dart
│   │   └── screens/
│   │       ├── game_screen.dart
│   │       ├── main_menu.dart
│   │       └── settings_screen.dart
│   ├── ai/
│   │   ├── ollama_client.dart
│   │   ├── mcp_client.dart
│   │   ├── personality_loader.dart
│   │   ├── game_state_context.dart
│   │   └── npc_behavior_tree.dart
│   ├── models/
│   │   ├── ability.dart
│   │   ├── character_stats.dart
│   │   ├── keybind.dart
│   │   └── npc_state.dart
│   └── utils/
│       ├── asset_loader.dart
│       ├── collision_detection.dart
│       └── vector_math_extensions.dart
├── assets/
│   ├── ui/                              # UI assets (SVG/PNG)
│   ├── sprites/                         # Character/entity sprites
│   ├── tiles/                           # Isometric tiles
│   ├── icons/                           # Ability/item icons
│   └── sounds/                          # Audio files
├── config/
│   ├── game_config.json
│   └── ui_config.json
├── personalities/
│   ├── warrior_companion.txt
│   ├── healer_companion.txt
│   └── mage_companion.txt
├── tests/
│   ├── unit/
│   ├── widget/
│   └── integration/
├── pubspec.yaml
├── CLAUDE.md
├── PLATFORM_DESIGN.md                   # This document
├── TASK.md
└── README.md
```

---

## 9. MCP Integration Deep Dive

### 9.1 MCP Tool Definitions

The following tools are exposed to NPCs via MCP:

```dart
final List<MCPTool> npcTools = [
  MCPTool(
    name: 'move_to_position',
    description: 'Move character to a specific position on the map',
    parameters: {
      'x': {'type': 'number', 'description': 'X coordinate'},
      'y': {'type': 'number', 'description': 'Y coordinate'},
      'run': {'type': 'boolean', 'description': 'Run instead of walk', 'default': true},
    },
    required: ['x', 'y'],
  ),
  MCPTool(
    name: 'attack_target',
    description: 'Attack a specific target',
    parameters: {
      'target_id': {'type': 'string', 'description': 'Unique ID of the target entity'},
    },
    required: ['target_id'],
  ),
  MCPTool(
    name: 'use_ability',
    description: 'Use one of your available abilities',
    parameters: {
      'ability_name': {'type': 'string', 'description': 'Name of the ability to use'},
      'target_id': {'type': 'string', 'description': 'Target entity ID (optional for AoE/self abilities)'},
    },
    required: ['ability_name'],
  ),
  MCPTool(
    name: 'follow_entity',
    description: 'Follow a specific entity (usually the player)',
    parameters: {
      'entity_id': {'type': 'string', 'description': 'Entity ID to follow'},
      'distance': {'type': 'number', 'description': 'Distance to maintain', 'default': 3.0},
    },
    required: ['entity_id'],
  ),
  MCPTool(
    name: 'stay_at_position',
    description: 'Stay at current position until given another command',
    parameters: {},
    required: [],
  ),
  MCPTool(
    name: 'say_dialogue',
    description: 'Say something in the game chat (for roleplay/feedback)',
    parameters: {
      'message': {'type': 'string', 'description': 'What to say'},
    },
    required: ['message'],
  ),
  MCPTool(
    name: 'request_help',
    description: 'Request help from other NPCs or the player',
    parameters: {
      'reason': {'type': 'string', 'description': 'Why you need help'},
      'target_id': {'type': 'string', 'description': 'Enemy that needs attention'},
    },
    required: ['reason'],
  ),
];
```

### 9.2 Example MCP Exchange

**Game State Context:**
```json
{
  "timestamp": 1698765432,
  "player": {
    "position": {"x": 100, "y": 150},
    "health_percent": 45,
    "in_combat": true,
    "target": "enemy_goblin_01"
  },
  "npc": {
    "position": {"x": 95, "y": 148},
    "health_percent": 80,
    "mana_percent": 60,
    "stance": "defensive",
    "available_abilities": [
      {"name": "Lesser Heal", "cooldown_remaining": 0, "mana_cost": 30},
      {"name": "Shield", "cooldown_remaining": 5.2, "mana_cost": 20},
      {"name": "Smite", "cooldown_remaining": 0, "mana_cost": 15}
    ]
  },
  "nearby_enemies": [
    {
      "id": "enemy_goblin_01",
      "type": "Goblin Warrior",
      "position": {"x": 105, "y": 152},
      "health_percent": 60,
      "targeting": "player"
    },
    {
      "id": "enemy_goblin_02",
      "type": "Goblin Archer",
      "position": {"x": 115, "y": 155},
      "health_percent": 100,
      "targeting": "npc_healer_01"
    }
  ],
  "nearby_allies": [
    {
      "id": "npc_warrior_01",
      "position": {"x": 108, "y": 150},
      "health_percent": 90
    }
  ],
  "current_objective": "Defend the village from goblin raiders"
}
```

**Player Intent:**
```
"Keep me alive and focus on healing"
```

**LLM Response (with tool calls):**
```json
{
  "message": "I see you're low on health and in danger. I'll heal you immediately.",
  "tool_calls": [
    {
      "name": "use_ability",
      "arguments": {
        "ability_name": "Lesser Heal",
        "target_id": "player"
      }
    },
    {
      "name": "move_to_position",
      "arguments": {
        "x": 98,
        "y": 149,
        "run": false
      },
      "reasoning": "Positioning closer to you while staying out of melee range"
    },
    {
      "name": "say_dialogue",
      "arguments": {
        "message": "Healing you now!"
      }
    }
  ]
}
```

### 9.3 Model Selection Guide

Based on research, recommended models for different NPC roles:

| Model | Use Case | RAM Required | Strengths |
|-------|----------|--------------|-----------|
| **llama3.1:8b-instruct-q8_0** | Combat NPCs, Strategy | 8GB | Best function calling, fast decisions |
| **mistral:7b-instruct-q4** | Dialogue NPCs | 4GB | Natural language, character voice |
| **qwen2.5:7b-instruct** | Support NPCs | 5GB | Good reasoning, efficient |
| **phi3:mini** | Simple NPCs | 2GB | Very fast, basic behaviors |

---

## 10. Testing Strategy

### 10.1 Unit Tests

```dart
// Test keybind manager
test('KeybindManager rebinds action correctly', () async {
  final manager = KeybindManager();
  await manager.loadBindings();

  final result = await manager.rebindAction(
    GameAction.moveForward,
    LogicalKeyboardKey.keyI,
  );

  expect(result, true);
  expect(manager.currentBindings[GameAction.moveForward], LogicalKeyboardKey.keyI);
});

// Test MCP client
test('OllamaMCPClient sends correct tool definitions', () {
  final client = OllamaMCPClient();
  final tools = client.getAvailableTools();

  expect(tools.length, greaterThan(0));
  expect(tools.any((t) => t['function']['name'] == 'attack_target'), true);
});

// Test NPC controller
test('NPCDirectController executes attack command', () {
  final npc = NPCFollowerComponent(npcId: 'test_npc');
  final controller = NPCDirectController(npc: npc);
  final target = Enemy(id: 'enemy_1');

  controller.commandAttack(target);

  expect(npc.currentTarget, target);
  expect(npc.isAttacking, true);
});
```

### 10.2 Integration Tests

```dart
testWidgets('Player can rebind keys in settings', (tester) async {
  await tester.pumpWidget(MyApp());

  // Navigate to settings
  await tester.tap(find.text('Settings'));
  await tester.pumpAndSettle();

  // Find the move forward keybind button
  await tester.tap(find.text('W'));
  await tester.pumpAndSettle();

  // Press new key
  await tester.sendKeyEvent(LogicalKeyboardKey.keyI);
  await tester.pumpAndSettle();

  // Verify change
  expect(find.text('I'), findsOneWidget);
});
```

### 10.3 AI Behavior Testing

Create test scenarios for NPC behavior:

```dart
class NPCBehaviorTest {
  Future<void> testHealerBehavior() async {
    // Setup: Player low health, healer NPC
    final scenario = TestScenario(
      playerHealth: 30.0,
      npcRole: 'healer',
      npcStance: NPCStance.defensive,
    );

    // Execute: Send intent
    final intent = "Keep the player alive";
    final response = await scenario.npc.interpretIntent(intent);

    // Assert: Should use healing ability
    expect(response.toolCalls.any((call) =>
      call.name == 'use_ability' &&
      call.arguments['ability_name'] == 'Heal'
    ), true);
  }
}
```

---

## 11. Future Enhancements

### 11.1 Multiplayer Support
- Add networked multiplayer using WebSockets
- Synchronize NPC states across clients
- Implement server-side LLM processing for fairness

### 11.2 Advanced AI Features
- Multi-NPC coordination ("warrior, protect the healer")
- Learning from player preferences over time
- Dynamic personality evolution based on experiences
- Voice commands via speech-to-text

### 11.3 Content Creation Tools
- Visual personality editor
- Ability/spell creator
- Map editor with Tiled integration
- Asset template library

### 11.4 Platform Expansion
- Mobile builds (iOS/Android)
- Desktop builds (Windows/Mac/Linux)
- VR support for immersive experience

---

## 12. Resources & References

### Documentation
- Flutter: https://docs.flutter.dev
- Flame Engine: https://docs.flame-engine.org
- Ollama: https://github.com/ollama/ollama
- Model Context Protocol: https://modelcontextprotocol.io

### Research Sources
- WoW Pet Control: https://vanilla-wow-archive.fandom.com/wiki/Pet_commands
- Flutter Flame Isometric: https://pub.dev/packages/flame_isometric
- Ollama Function Calling: https://github.com/ollama/ollama/blob/main/docs/api.md#chat-request-with-tools
- MCP with Ollama: https://github.com/patruff/ollama-mcp-bridge

### Community
- Flame Discord: https://discord.com/invite/pxrBmy4
- Flutter Discord: https://discord.com/invite/flutter
- Ollama Discord: https://discord.com/invite/ollama

---

## 13. Conclusion

This platform design provides a comprehensive foundation for building a 3D isometric game with Flutter and Dart that features:

1. **Intuitive WoW-inspired controls** with full rebindability
2. **Flexible UI system** supporting easy asset replacement
3. **AI-powered NPC companions** using local LLMs (Ollama)
4. **Model Context Protocol integration** for advanced gameplay
5. **Dual control modes** (intent-based AI and direct commands)
6. **Scalable architecture** supporting future enhancements

The design prioritizes:
- **Local-first**: No cloud dependencies, complete privacy
- **Configuration over code**: Easy customization via JSON/assets
- **Web-first development**: Fast iteration with hot-reload
- **Modular components**: Clean separation of concerns
- **Performance**: Optimized for web deployment

By following this design and the phased implementation plan, you'll create a unique gaming experience that combines traditional game mechanics with cutting-edge AI technology, all running locally on the player's machine.
