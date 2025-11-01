import 'dart:html' as html;
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math.dart' hide Colors;
import 'dart:ui' as ui;

import '../rendering3d/webgl_renderer.dart';
import '../rendering3d/camera3d.dart';
import '../rendering3d/mesh.dart';
import '../rendering3d/math/transform3d.dart';
import '../rendering3d/terrain_generator.dart';
import '../rendering3d/player_mesh.dart';
import '../game/controllers/input_manager.dart';
import '../models/game_action.dart';

/// Projectile - Represents a moving projectile (like fireball)
class Projectile {
  Mesh mesh;
  Transform3d transform;
  Vector3 velocity;
  double lifetime;

  Projectile({
    required this.mesh,
    required this.transform,
    required this.velocity,
    this.lifetime = 5.0, // 5 seconds max lifetime
  });
}

/// ImpactEffect - Visual effect for projectile impacts
class ImpactEffect {
  Mesh mesh;
  Transform3d transform;
  double lifetime;
  double maxLifetime;

  ImpactEffect({
    required this.mesh,
    required this.transform,
    this.lifetime = 0.5, // 0.5 seconds impact animation
  }) : maxLifetime = lifetime;

  double get progress => 1.0 - (lifetime / maxLifetime);
}

/// Ally - Represents an allied NPC character
class Ally {
  Mesh mesh;
  Mesh directionIndicatorMesh;
  Transform3d transform;
  Transform3d? directionIndicatorTransform;
  double rotation;
  double health;
  double maxHealth;
  int abilityIndex; // 0, 1, or 2 (which player ability they have)
  double abilityCooldown;
  double abilityCooldownMax;
  double aiTimer;
  final double aiInterval = 3.0; // Think every 3 seconds
  List<Projectile> projectiles;

  Ally({
    required this.mesh,
    required this.directionIndicatorMesh,
    required this.transform,
    this.directionIndicatorTransform,
    this.rotation = 0.0,
    this.health = 50.0,
    this.maxHealth = 50.0,
    required this.abilityIndex,
    this.abilityCooldown = 0.0,
    this.abilityCooldownMax = 5.0,
    this.aiTimer = 0.0,
  }) : projectiles = [];
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

class _Game3DState extends State<Game3D> {
  // Canvas element for WebGL
  late html.CanvasElement canvas;
  late String canvasId;

  // Core systems
  WebGLRenderer? renderer;
  Camera3D? camera;
  InputManager? inputManager;

  // Game objects
  List<TerrainTile>? terrainTiles;
  Mesh? playerMesh;
  Transform3d? playerTransform;
  Mesh? directionIndicator;
  Transform3d? directionIndicatorTransform;
  Mesh? shadowMesh;
  Transform3d? shadowTransform;

  // Monster (enemy)
  Mesh? monsterMesh;
  Transform3d? monsterTransform;
  Mesh? monsterDirectionIndicator;
  Transform3d? monsterDirectionIndicatorTransform;
  double monsterRotation = 180.0; // Face toward player initially

  // Monster health and abilities
  double monsterHealth = 100.0;
  final double monsterMaxHealth = 100.0;
  double monsterAbility1Cooldown = 0.0;
  final double monsterAbility1CooldownMax = 2.0;
  double monsterAbility2Cooldown = 0.0;
  final double monsterAbility2CooldownMax = 4.0;
  double monsterAbility3Cooldown = 0.0;
  final double monsterAbility3CooldownMax = 8.0;

  // Monster AI state
  bool monsterPaused = false;
  double monsterAiTimer = 0.0;
  final double monsterAiInterval = 2.0; // Think every 2 seconds
  List<Projectile> monsterProjectiles = [];

  // Ally state
  List<Ally> allies = []; // Start with zero allies

  // Game state
  double playerRotation = 0.0;
  double playerSpeed = 5.0;
  int? animationFrameId;
  DateTime? lastFrameTime;
  int frameCount = 0;

  // Jump state
  bool isJumping = false;
  double verticalVelocity = 0.0;
  bool isGrounded = true;
  int jumpsRemaining = 2; // Allow 2 jumps total (ground jump + air jump)
  final int maxJumps = 2;
  final double jumpForce = 8.0;
  final double gravity = 20.0;
  final double groundLevel = 0.5; // Player's Y position when on ground
  bool jumpKeyWasPressed = false; // Track previous jump key state

  // Ability system
  // Ability 1: Sword Attack (melee)
  double ability1Cooldown = 0.0;
  final double ability1CooldownMax = 1.5; // 1.5 seconds
  bool ability1Active = false;
  double ability1ActiveTime = 0.0;
  final double ability1Duration = 0.3; // Sword swing duration
  Mesh? swordMesh;
  Transform3d? swordTransform;

  // Ability 2: Fireball (projectile)
  double ability2Cooldown = 0.0;
  final double ability2CooldownMax = 3.0; // 3 seconds
  List<Projectile> fireballs = []; // List of active fireballs
  List<ImpactEffect> impactEffects = []; // List of active impact effects

  // Ability 3: Heal
  double ability3Cooldown = 0.0;
  final double ability3CooldownMax = 10.0; // 10 seconds
  bool ability3Active = false;
  double ability3ActiveTime = 0.0;
  final double ability3Duration = 1.0; // Heal effect duration
  Mesh? healEffectMesh;
  Transform3d? healEffectTransform;

  @override
  void initState() {
    super.initState();
    canvasId = 'game3d_canvas_${DateTime.now().millisecondsSinceEpoch}';

    // Initialize input manager
    inputManager = InputManager();

    // Create canvas element immediately
    _initializeGame();
  }

  void _initializeGame() {
    try {
      print('=== Game3D Initialization Starting ===');

      // Create canvas element
      canvas = html.CanvasElement()
        ..id = canvasId
        ..style.position = 'fixed'
        ..style.top = '0'
        ..style.left = '0'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.display = 'block'
        ..style.zIndex = '-1' // Behind Flutter UI
        ..style.pointerEvents = 'none'; // Let Flutter handle input

      // Append canvas to document body
      html.document.body?.append(canvas);
      print('Canvas created and appended to DOM');

      // Set canvas size
      canvas.width = 1600;
      canvas.height = 900;
      print('Canvas size: ${canvas.width}x${canvas.height}');

      // Initialize renderer
      renderer = WebGLRenderer(canvas);

      // Initialize camera
      camera = Camera3D(
        position: Vector3(0, 10, 15),
        rotation: Vector3(30, 0, 0), // Start at 30 degrees
        aspectRatio: canvas.width! / canvas.height!,
      );

      // Set camera to orbit around origin
      camera!.setTarget(Vector3(0, 0, 0));
      camera!.setTargetDistance(15);

      // Initialize terrain
      terrainTiles = TerrainGenerator.createTileGrid(
        width: 20,
        height: 20,
        tileSize: 1.0,
      );

      // Initialize player
      playerMesh = PlayerMesh.createSimpleCharacter();
      playerTransform = Transform3d(
        position: Vector3(0, 0.5, 0), // Slightly above ground
        scale: Vector3(1, 1, 1),
      );

      // Initialize direction indicator (red triangle on top of player)
      directionIndicator = Mesh.triangle(
        size: 0.5,
        color: Vector3(1.0, 0.0, 0.0), // Red color
      );
      directionIndicatorTransform = Transform3d(
        position: Vector3(0, 1.2, 0), // On top of player cube
        scale: Vector3(1, 1, 1),
      );

      // Initialize shadow (dark semi-transparent plane under player)
      shadowMesh = Mesh.plane(
        width: 1.0,
        height: 1.0,
        color: Vector3(0.0, 0.0, 0.0), // Black shadow
      );
      shadowTransform = Transform3d(
        position: Vector3(0, 0.01, 0), // Slightly above ground to avoid z-fighting
        scale: Vector3(1, 1, 1),
      );

      // Initialize sword mesh (gray metallic plane for sword swing)
      swordMesh = Mesh.plane(
        width: 0.3,
        height: 1.5,
        color: Vector3(0.7, 0.7, 0.8), // Gray metallic color
      );
      swordTransform = Transform3d(
        position: Vector3(0, 0, 0), // Will be positioned in front of player when active
        scale: Vector3(1, 1, 1),
      );

      // Initialize heal effect mesh (green/yellow glow around player)
      healEffectMesh = Mesh.cube(
        size: 1.5,
        color: Vector3(0.5, 1.0, 0.3), // Green/yellow healing color
      );
      healEffectTransform = Transform3d(
        position: Vector3(0, 0, 0), // Will match player position when active
        scale: Vector3(1, 1, 1),
      );

      // Initialize monster (purple enemy at opposite end of terrain)
      monsterMesh = Mesh.cube(
        size: 1.2,
        color: Vector3(0.6, 0.2, 0.8), // Purple color
      );
      monsterTransform = Transform3d(
        position: Vector3(18, 0.6, 18), // Opposite end of 20x20 terrain
        rotation: Vector3(0, monsterRotation, 0),
        scale: Vector3(1, 1, 1),
      );

      // Initialize monster direction indicator (green triangle on top of monster)
      monsterDirectionIndicator = Mesh.triangle(
        size: 0.5,
        color: Vector3(0.0, 1.0, 0.0), // Green color
      );
      monsterDirectionIndicatorTransform = Transform3d(
        position: Vector3(18, 1.3, 18), // On top of monster cube
        rotation: Vector3(0, monsterRotation + 180, 0),
        scale: Vector3(1, 1, 1),
      );

      print('Game3D initialized successfully!');

      // Start game loop
      _startGameLoop();
    } catch (e, stackTrace) {
      print('Error initializing Game3D: $e');
      print(stackTrace);
    }
  }

  void _startGameLoop() {
    lastFrameTime = DateTime.now();
    print('Starting game loop...');

    void gameLoop(num timestamp) {
      if (!mounted) return;

      final now = DateTime.now();
      final dt = lastFrameTime != null
          ? (now.millisecondsSinceEpoch - lastFrameTime!.millisecondsSinceEpoch) / 1000.0
          : 0.016; // Default to ~60fps
      lastFrameTime = now;

      frameCount++;

      // Log every 60 frames (~1 second at 60fps)
      if (frameCount % 60 == 0) {
        print('Frame $frameCount - dt: ${dt.toStringAsFixed(4)}s - Terrain: ${terrainTiles?.length ?? 0} tiles');
      }

      _update(dt);
      _render();

      // Update UI every 10 frames to show camera changes
      if (frameCount % 10 == 0 && mounted) {
        setState(() {});
      }

      animationFrameId = html.window.requestAnimationFrame(gameLoop);
    }

    animationFrameId = html.window.requestAnimationFrame(gameLoop);
    print('Game loop started - animationFrameId: $animationFrameId');
  }

  void _update(double dt) {
    if (inputManager == null || camera == null || playerTransform == null) return;

    inputManager!.update(dt);

    // Camera controls
    if (inputManager!.isActionPressed(GameAction.cameraRotateLeft)) {
      camera!.yawBy(-90 * dt); // J key - yaw left
    }
    if (inputManager!.isActionPressed(GameAction.cameraRotateRight)) {
      camera!.yawBy(90 * dt); // L key - yaw right
    }
    if (inputManager!.isActionPressed(GameAction.cameraPitchUp)) {
      camera!.pitchBy(45 * dt); // N key - pitch up
    }
    if (inputManager!.isActionPressed(GameAction.cameraPitchDown)) {
      camera!.pitchBy(-45 * dt); // M key - pitch down
    }
    if (inputManager!.isActionPressed(GameAction.cameraZoomIn)) {
      camera!.zoom(-5 * dt); // I key - zoom in
    }
    if (inputManager!.isActionPressed(GameAction.cameraZoomOut)) {
      camera!.zoom(5 * dt); // K key - zoom out
    }

    // Player movement controls
    // W = Forward
    if (inputManager!.isActionPressed(GameAction.moveForward)) {
      // Move forward in player's facing direction
      final forward = Vector3(
        -Math.sin(radians(playerRotation)),
        0,
        -Math.cos(radians(playerRotation)),
      );
      playerTransform!.position += forward * playerSpeed * dt;
    }

    // S = Backward
    if (inputManager!.isActionPressed(GameAction.moveBackward)) {
      // Move backward
      final forward = Vector3(
        -Math.sin(radians(playerRotation)),
        0,
        -Math.cos(radians(playerRotation)),
      );
      playerTransform!.position -= forward * playerSpeed * dt;
    }

    // A = Rotate Right
    if (inputManager!.isActionPressed(GameAction.rotateLeft)) {
      playerRotation += 180 * dt; // A key - rotate right
      playerTransform!.rotation.y = playerRotation;
    }

    // D = Rotate Left
    if (inputManager!.isActionPressed(GameAction.rotateRight)) {
      playerRotation -= 180 * dt; // D key - rotate left
      playerTransform!.rotation.y = playerRotation;
    }

    // Q = Strafe Left
    if (inputManager!.isActionPressed(GameAction.strafeLeft)) {
      // Strafe left (perpendicular to facing direction)
      final right = Vector3(
        Math.cos(radians(playerRotation)),
        0,
        -Math.sin(radians(playerRotation)),
      );
      playerTransform!.position -= right * playerSpeed * dt;
    }

    // E = Strafe Right
    if (inputManager!.isActionPressed(GameAction.strafeRight)) {
      // Strafe right
      final right = Vector3(
        Math.cos(radians(playerRotation)),
        0,
        -Math.sin(radians(playerRotation)),
      );
      playerTransform!.position += right * playerSpeed * dt;
    }

    // Spacebar = Jump (allows double jump)
    // Only trigger jump on new key press, not when held
    final jumpKeyIsPressed = inputManager!.isActionPressed(GameAction.jump);
    if (jumpKeyIsPressed && !jumpKeyWasPressed && jumpsRemaining > 0) {
      verticalVelocity = jumpForce;
      isJumping = true;
      isGrounded = false;
      jumpsRemaining--;
    }
    jumpKeyWasPressed = jumpKeyIsPressed;

    // Apply gravity and vertical movement
    verticalVelocity -= gravity * dt;
    playerTransform!.position.y += verticalVelocity * dt;

    // Ground collision detection
    if (playerTransform!.position.y <= groundLevel) {
      playerTransform!.position.y = groundLevel;
      verticalVelocity = 0.0;
      isJumping = false;
      isGrounded = true;
      jumpsRemaining = maxJumps; // Reset jumps when landing
    }

    // ===== ABILITY SYSTEM =====
    // Update cooldowns
    if (ability1Cooldown > 0) ability1Cooldown -= dt;
    if (ability2Cooldown > 0) ability2Cooldown -= dt;
    if (ability3Cooldown > 0) ability3Cooldown -= dt;

    // Update monster ability cooldowns
    if (monsterAbility1Cooldown > 0) monsterAbility1Cooldown -= dt;
    if (monsterAbility2Cooldown > 0) monsterAbility2Cooldown -= dt;
    if (monsterAbility3Cooldown > 0) monsterAbility3Cooldown -= dt;

    // ===== MONSTER AI SYSTEM =====
    if (!monsterPaused && monsterHealth > 0 && monsterTransform != null && playerTransform != null) {
      monsterAiTimer += dt;

      // AI thinks every 2 seconds
      if (monsterAiTimer >= monsterAiInterval) {
        monsterAiTimer = 0.0;

        // Calculate distance to player
        final distanceToPlayer = (monsterTransform!.position - playerTransform!.position).length;

        // Always face the player
        final toPlayer = playerTransform!.position - monsterTransform!.position;
        monsterRotation = math.atan2(-toPlayer.x, -toPlayer.z) * (180 / math.pi);
        monsterDirectionIndicatorTransform?.rotation.y = monsterRotation;

        // Decision making
        if (distanceToPlayer > 8.0) {
          // Move toward player if too far
          final moveDirection = toPlayer.normalized();
          monsterTransform!.position += moveDirection * 0.5;
        } else if (distanceToPlayer < 3.0) {
          // Move away if too close
          final moveDirection = toPlayer.normalized();
          monsterTransform!.position -= moveDirection * 0.3;
        }

        // Use abilities based on distance and cooldown
        if (distanceToPlayer < 5.0 && monsterAbility1Cooldown <= 0) {
          _activateMonsterAbility1(); // Dark strike
        } else if (distanceToPlayer > 4.0 && distanceToPlayer < 12.0 && monsterAbility2Cooldown <= 0) {
          _activateMonsterAbility2(); // Shadow bolt
        } else if (monsterHealth < 50 && monsterAbility3Cooldown <= 0) {
          _activateMonsterAbility3(); // Healing
        }
      }
    }

    // Update monster projectiles
    monsterProjectiles.removeWhere((projectile) {
      projectile.transform.position += projectile.velocity * dt;
      projectile.lifetime -= dt;

      // Check collision with player
      if (playerTransform != null) {
        final distance = (projectile.transform.position - playerTransform!.position).length;
        if (distance < 1.0) {
          // Hit player - create impact
          final impactMesh = Mesh.cube(
            size: 0.8,
            color: Vector3(0.5, 0.0, 0.5), // Purple impact
          );
          final impactTransform = Transform3d(
            position: projectile.transform.position.clone(),
            scale: Vector3(1, 1, 1),
          );
          impactEffects.add(ImpactEffect(
            mesh: impactMesh,
            transform: impactTransform,
          ));
          print('Monster hit player! (implement player damage later)');
          return true;
        }
      }

      return projectile.lifetime <= 0;
    });

    // Ability 1: Sword Attack (Key 1)
    if (inputManager!.isActionPressed(GameAction.actionBar1) && ability1Cooldown <= 0 && !ability1Active) {
      ability1Active = true;
      ability1ActiveTime = 0.0;
      ability1Cooldown = ability1CooldownMax;
      print('Sword attack activated!');
    }

    // Update sword attack
    if (ability1Active) {
      ability1ActiveTime += dt;
      if (ability1ActiveTime >= ability1Duration) {
        ability1Active = false;
      } else if (swordTransform != null && playerTransform != null) {
        // Position sword in front of player, rotating during swing
        final forward = Vector3(
          -Math.sin(radians(playerRotation)),
          0,
          -Math.cos(radians(playerRotation)),
        );
        final swingProgress = ability1ActiveTime / ability1Duration;
        final swingAngle = swingProgress * 180; // 0 to 180 degrees

        swordTransform!.position = playerTransform!.position + forward * 0.8;
        swordTransform!.position.y = playerTransform!.position.y;
        swordTransform!.rotation.y = playerRotation + swingAngle - 90;
      }
    }

    // Ability 2: Fireball (Key 2)
    if (inputManager!.isActionPressed(GameAction.actionBar2) && ability2Cooldown <= 0) {
      // Create fireball projectile
      final forward = Vector3(
        -Math.sin(radians(playerRotation)),
        0,
        -Math.cos(radians(playerRotation)),
      );

      final fireballMesh = Mesh.cube(
        size: 0.4,
        color: Vector3(1.0, 0.4, 0.0), // Orange/red fireball
      );

      final startPos = playerTransform!.position.clone() + forward * 1.0;
      startPos.y = playerTransform!.position.y;

      final fireballTransform = Transform3d(
        position: startPos,
        scale: Vector3(1, 1, 1),
      );

      fireballs.add(Projectile(
        mesh: fireballMesh,
        transform: fireballTransform,
        velocity: forward * 10.0, // Speed of 10 units/sec
      ));

      ability2Cooldown = ability2CooldownMax;
      print('Fireball launched!');
    }

    // Update fireballs and check for collisions
    fireballs.removeWhere((fireball) {
      // Move fireball
      fireball.transform.position += fireball.velocity * dt;
      fireball.lifetime -= dt;

      // Check collision with monster
      if (monsterTransform != null && monsterHealth > 0) {
        final distance = (fireball.transform.position - monsterTransform!.position).length;
        final collisionThreshold = 1.0; // Collision distance

        if (distance < collisionThreshold) {
          // Create impact effect at collision point
          final impactMesh = Mesh.cube(
            size: 0.8,
            color: Vector3(1.0, 0.5, 0.0), // Orange impact flash
          );
          final impactTransform = Transform3d(
            position: fireball.transform.position.clone(),
            scale: Vector3(1, 1, 1),
          );
          impactEffects.add(ImpactEffect(
            mesh: impactMesh,
            transform: impactTransform,
          ));

          // Deal damage to monster
          final damage = 20.0;
          monsterHealth = (monsterHealth - damage).clamp(0.0, monsterMaxHealth);
          print('Fireball hit monster for $damage damage! Monster health: ${monsterHealth.toStringAsFixed(1)}');

          // Remove fireball
          return true;
        }
      }

      // Remove if lifetime expired
      return fireball.lifetime <= 0;
    });

    // Update impact effects
    impactEffects.removeWhere((impact) {
      impact.lifetime -= dt;

      // Scale effect (expand and fade)
      final scale = 1.0 + (impact.progress * 1.5); // Grows to 2.5x size
      impact.transform.scale = Vector3(scale, scale, scale);

      return impact.lifetime <= 0;
    });

    // Ability 3: Heal (Key 3)
    if (inputManager!.isActionPressed(GameAction.actionBar3) && ability3Cooldown <= 0 && !ability3Active) {
      ability3Active = true;
      ability3ActiveTime = 0.0;
      ability3Cooldown = ability3CooldownMax;
      print('Heal activated!');
    }

    // Update heal effect
    if (ability3Active) {
      ability3ActiveTime += dt;
      if (ability3ActiveTime >= ability3Duration) {
        ability3Active = false;
      } else if (healEffectTransform != null && playerTransform != null) {
        // Position heal effect around player with pulsing animation
        healEffectTransform!.position = playerTransform!.position.clone();
        final pulseScale = 1.0 + (Math.sin(ability3ActiveTime * 10) * 0.2);
        healEffectTransform!.scale = Vector3(pulseScale, pulseScale, pulseScale);
      }
    }
    // ===== END ABILITY SYSTEM =====

    // Update direction indicator position and rotation to match player
    if (directionIndicatorTransform != null && playerTransform != null) {
      directionIndicatorTransform!.position.x = playerTransform!.position.x;
      directionIndicatorTransform!.position.y = playerTransform!.position.y + 0.5; // Flush with top of cube
      directionIndicatorTransform!.position.z = playerTransform!.position.z;
      directionIndicatorTransform!.rotation.y = playerRotation + 180; // Rotate 180 degrees
    }

    // Update shadow position, rotation, and scale based on player height and light direction
    if (shadowTransform != null && playerTransform != null) {
      // Light direction (from upper-right-front) - normalized direction from where light is coming
      final lightDirX = 0.5; // Light from right
      final lightDirZ = 0.3; // Light from front

      // Calculate shadow offset based on player height (higher = further from player)
      final playerHeight = playerTransform!.position.y - groundLevel;
      final shadowOffsetX = playerHeight * lightDirX;
      final shadowOffsetZ = playerHeight * lightDirZ;

      // Position shadow with offset from player
      shadowTransform!.position.x = playerTransform!.position.x + shadowOffsetX;
      shadowTransform!.position.z = playerTransform!.position.z + shadowOffsetZ;

      // Rotate shadow to match player rotation
      shadowTransform!.rotation.y = playerRotation;

      // Shadow gets larger the higher the player is (scale factor includes base size adjustment)
      final scaleFactor = 1.0 + playerHeight * 0.15;
      shadowTransform!.scale = Vector3(scaleFactor, 1, scaleFactor);
    }

    // Update camera to follow player (with smoothing to avoid "terrain moving" effect)
    // Only update camera target if player moves significantly from center
    final currentTarget = camera!.getTarget();
    final distanceFromTarget = (playerTransform!.position - currentTarget).length;

    // Update camera target smoothly when player moves away from center
    if (distanceFromTarget > 0.1) {
      // Smoothly interpolate camera target toward player position
      final newTarget = currentTarget + (playerTransform!.position - currentTarget) * 0.05;
      camera!.setTarget(newTarget);
    }
  }

  void _render() {
    if (renderer == null || camera == null) {
      print('Render skipped - renderer: ${renderer != null}, camera: ${camera != null}');
      return;
    }

    // Clear screen
    renderer!.clear();

    // Render terrain tiles
    if (terrainTiles != null) {
      for (final tile in terrainTiles!) {
        renderer!.render(tile.mesh, tile.transform, camera!);
      }
    }

    // Render shadow (before player so it appears underneath)
    if (shadowMesh != null && shadowTransform != null) {
      renderer!.render(shadowMesh!, shadowTransform!, camera!);
    }

    // Render player
    if (playerMesh != null && playerTransform != null) {
      renderer!.render(playerMesh!, playerTransform!, camera!);
    }

    // Render direction indicator
    if (directionIndicator != null && directionIndicatorTransform != null) {
      renderer!.render(directionIndicator!, directionIndicatorTransform!, camera!);
    }

    // Render monster
    if (monsterMesh != null && monsterTransform != null) {
      renderer!.render(monsterMesh!, monsterTransform!, camera!);
    }

    // Render monster direction indicator
    if (monsterDirectionIndicator != null && monsterDirectionIndicatorTransform != null) {
      renderer!.render(monsterDirectionIndicator!, monsterDirectionIndicatorTransform!, camera!);
    }

    // Render allies
    for (final ally in allies) {
      // Render ally mesh
      renderer!.render(ally.mesh, ally.transform, camera!);

      // Render ally direction indicator
      if (ally.directionIndicatorTransform != null) {
        renderer!.render(ally.directionIndicatorMesh, ally.directionIndicatorTransform!, camera!);
      }

      // Render ally projectiles
      for (final projectile in ally.projectiles) {
        renderer!.render(projectile.mesh, projectile.transform, camera!);
      }
    }

    // Render ability effects
    // Render sword attack
    if (ability1Active && swordMesh != null && swordTransform != null) {
      renderer!.render(swordMesh!, swordTransform!, camera!);
    }

    // Render fireballs
    for (final fireball in fireballs) {
      renderer!.render(fireball.mesh, fireball.transform, camera!);
    }

    // Render monster projectiles
    for (final projectile in monsterProjectiles) {
      renderer!.render(projectile.mesh, projectile.transform, camera!);
    }

    // Render impact effects
    for (final impact in impactEffects) {
      renderer!.render(impact.mesh, impact.transform, camera!);
    }

    // Render heal effect
    if (ability3Active && healEffectMesh != null && healEffectTransform != null) {
      renderer!.render(healEffectMesh!, healEffectTransform!, camera!);
    }
  }

  void _onKeyEvent(KeyEvent event) {
    if (inputManager != null) {
      inputManager!.handleKeyEvent(event);
    }
  }

  // Ability activation methods (for clickable buttons)
  void _activateAbility1() {
    if (ability1Cooldown <= 0 && !ability1Active) {
      setState(() {
        ability1Active = true;
        ability1ActiveTime = 0.0;
        ability1Cooldown = ability1CooldownMax;
      });
      print('Sword attack activated! (clicked)');
    }
  }

  void _activateAbility2() {
    if (ability2Cooldown <= 0 && playerTransform != null) {
      setState(() {
        // Create fireball projectile
        final forward = Vector3(
          -Math.sin(radians(playerRotation)),
          0,
          -Math.cos(radians(playerRotation)),
        );

        final fireballMesh = Mesh.cube(
          size: 0.4,
          color: Vector3(1.0, 0.4, 0.0), // Orange/red fireball
        );

        final startPos = playerTransform!.position.clone() + forward * 1.0;
        startPos.y = playerTransform!.position.y;

        final fireballTransform = Transform3d(
          position: startPos,
          scale: Vector3(1, 1, 1),
        );

        fireballs.add(Projectile(
          mesh: fireballMesh,
          transform: fireballTransform,
          velocity: forward * 10.0, // Speed of 10 units/sec
        ));

        ability2Cooldown = ability2CooldownMax;
      });
      print('Fireball launched! (clicked)');
    }
  }

  void _activateAbility3() {
    if (ability3Cooldown <= 0 && !ability3Active) {
      setState(() {
        ability3Active = true;
        ability3ActiveTime = 0.0;
        ability3Cooldown = ability3CooldownMax;
      });
      print('Heal activated! (clicked)');
    }
  }

  // ===== MONSTER ABILITY METHODS =====

  /// Activate Monster Ability 1: Dark Strike (melee attack)
  void _activateMonsterAbility1() {
    if (monsterAbility1Cooldown > 0 || monsterHealth <= 0) return;

    setState(() {
      monsterAbility1Cooldown = monsterAbility1CooldownMax;
    });
    print('Monster uses Dark Strike! (melee attack)');
  }

  /// Activate Monster Ability 2: Shadow Bolt (ranged projectile)
  void _activateMonsterAbility2() {
    if (monsterAbility2Cooldown > 0 || monsterHealth <= 0) return;
    if (monsterTransform == null || playerTransform == null) return;

    // Create shadow bolt projectile aimed at player
    final direction = (playerTransform!.position - monsterTransform!.position).normalized();
    final projectileMesh = Mesh.cube(
      size: 0.5,
      color: Vector3(0.5, 0.0, 0.5), // Purple
    );
    final projectileTransform = Transform3d(
      position: monsterTransform!.position.clone() + Vector3(0, 1, 0),
      scale: Vector3(1, 1, 1),
    );

    setState(() {
      monsterProjectiles.add(Projectile(
        mesh: projectileMesh,
        transform: projectileTransform,
        velocity: direction * 8.0,
        lifetime: 5.0,
      ));
      monsterAbility2Cooldown = monsterAbility2CooldownMax;
    });
    print('Monster casts Shadow Bolt! (projectile)');
  }

  /// Activate Monster Ability 3: Dark Healing (restore health)
  void _activateMonsterAbility3() {
    if (monsterAbility3Cooldown > 0 || monsterHealth <= 0) return;

    setState(() {
      // Heal for 20-30 HP
      monsterHealth = math.min(monsterMaxHealth.toDouble(), monsterHealth + 25);
      monsterAbility3Cooldown = monsterAbility3CooldownMax;
    });
    print('Monster heals itself! Health: $monsterHealth/$monsterMaxHealth');
  }

  // ===== ALLY MANAGEMENT METHODS =====

  /// Add a new ally with a random ability
  void _addAlly() {
    setState(() {
      // Generate random ability (0, 1, or 2)
      final random = math.Random();
      final randomAbility = random.nextInt(3);

      // Create ally mesh (smaller, brighter blue than player)
      final allyMesh = Mesh.cube(
        size: 0.8, // 0.8x player size
        color: Vector3(0.4, 0.7, 1.0), // Brighter blue than player (0.3, 0.5, 0.8)
      );

      // Create direction indicator (cyan triangle on top)
      final allyDirectionIndicator = Mesh.triangle(
        size: 0.4, // Smaller than player's 0.5
        color: Vector3(0.0, 1.0, 1.0), // Cyan color
      );

      // Position ally near player (offset to avoid overlap)
      final allyCount = allies.length;
      final angle = (allyCount * 60.0) * (math.pi / 180.0); // Space out in circle
      final offsetX = math.cos(angle) * 2.0;
      final offsetZ = math.sin(angle) * 2.0;

      final allyPosition = playerTransform != null
          ? Vector3(
              playerTransform!.position.x + offsetX,
              0.4, // Slightly lower than player (0.5)
              playerTransform!.position.z + offsetZ,
            )
          : Vector3(2, 0.4, 2); // Default position if no player

      final allyTransform = Transform3d(
        position: allyPosition,
        scale: Vector3(1, 1, 1),
      );

      final allyDirectionTransform = Transform3d(
        position: Vector3(allyPosition.x, allyPosition.y + 0.4, allyPosition.z),
        rotation: Vector3(0, 180, 0),
        scale: Vector3(1, 1, 1),
      );

      // Create ally object
      final ally = Ally(
        mesh: allyMesh,
        directionIndicatorMesh: allyDirectionIndicator,
        transform: allyTransform,
        directionIndicatorTransform: allyDirectionTransform,
        rotation: 0.0,
        abilityIndex: randomAbility,
        health: 50.0,
        maxHealth: 50.0,
        abilityCooldown: 0.0,
        abilityCooldownMax: 5.0,
        aiTimer: 0.0,
      );

      allies.add(ally);

      final abilityNames = ['Sword', 'Fireball', 'Heal'];
      print('Ally added! Ability: ${abilityNames[randomAbility]} (Total: ${allies.length})');
    });
  }

  /// Remove the most recently added ally
  void _removeAlly() {
    if (allies.isEmpty) {
      print('No allies to remove!');
      return;
    }

    setState(() {
      allies.removeLast();
      print('Ally removed! Remaining: ${allies.length}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        _onKeyEvent(event);
        return KeyEventResult.handled;
      },
      child: Container(
        color: Colors.transparent, // Transparent to show canvas behind
        child: Stack(
          children: [
            // Canvas will be created and appended to body in initState
            SizedBox.expand(),

            // Instructions overlay
            Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: EdgeInsets.all(8),
              color: Colors.black54,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Camera: J/L=Yaw | N/M=Pitch | I/K=Zoom',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Movement: W/S=Forward/Back | A/D=Rotate | Q/E=Strafe',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Jump: Spacebar',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Abilities:',
                    style: TextStyle(color: Colors.cyan, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '1: Sword ${ability1Cooldown > 0 ? "(${ability1Cooldown.toStringAsFixed(1)}s)" : "READY"}',
                    style: TextStyle(
                      color: ability1Cooldown > 0 ? Colors.red : Colors.green,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    '2: Fireball ${ability2Cooldown > 0 ? "(${ability2Cooldown.toStringAsFixed(1)}s)" : "READY"}',
                    style: TextStyle(
                      color: ability2Cooldown > 0 ? Colors.red : Colors.green,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    '3: Heal ${ability3Cooldown > 0 ? "(${ability3Cooldown.toStringAsFixed(1)}s)" : "READY"}',
                    style: TextStyle(
                      color: ability3Cooldown > 0 ? Colors.red : Colors.green,
                      fontSize: 10,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Camera Angle to Terrain: ${(camera?.pitch.abs() ?? 0).toStringAsFixed(1)}°',
                    style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Camera Position: '
                    'X: ${camera?.position.x.toStringAsFixed(1) ?? "0"} | '
                    'Y: ${camera?.position.y.toStringAsFixed(1) ?? "0"} | '
                    'Z: ${camera?.position.z.toStringAsFixed(1) ?? "0"}',
                    style: TextStyle(color: Colors.amber, fontSize: 10),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Pitch: ${camera?.pitch.toStringAsFixed(1) ?? "0"}° | '
                    'Yaw: ${camera?.yaw.toStringAsFixed(1) ?? "0"}°',
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),

          // HUD - Monster Information (Bottom-left corner)
          Positioned(
            bottom: 20,
            left: 20,
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Monster label
                  Text(
                    'BOSS MONSTER',
                    style: TextStyle(
                      color: Colors.purple,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 8),
                  // Health bar
                  Container(
                    width: 200,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey.shade600, width: 2),
                    ),
                    child: Stack(
                      children: [
                        // Health fill
                        FractionallySizedBox(
                          widthFactor: (monsterHealth / monsterMaxHealth).clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: monsterHealth > 50 ? Colors.green :
                                     monsterHealth > 25 ? Colors.orange : Colors.red,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        // Health text
                        Center(
                          child: Text(
                            '${monsterHealth.toStringAsFixed(0)} / ${monsterMaxHealth.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 2,
                                  offset: Offset(1, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                  // Ability buttons
                  Row(
                    children: [
                      _buildAbilityButton(
                        label: 'M1',
                        color: Color(0xFF9B59B6), // Purple
                        cooldown: monsterAbility1Cooldown,
                        maxCooldown: monsterAbility1CooldownMax,
                        onPressed: _activateMonsterAbility1,
                      ),
                      SizedBox(width: 8),
                      _buildAbilityButton(
                        label: 'M2',
                        color: Color(0xFF8E44AD), // Darker purple
                        cooldown: monsterAbility2Cooldown,
                        maxCooldown: monsterAbility2CooldownMax,
                        onPressed: _activateMonsterAbility2,
                      ),
                      SizedBox(width: 8),
                      _buildAbilityButton(
                        label: 'M3',
                        color: Color(0xFF6C3483), // Even darker purple
                        cooldown: monsterAbility3Cooldown,
                        maxCooldown: monsterAbility3CooldownMax,
                        onPressed: _activateMonsterAbility3,
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  // Pause button for monster AI
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        monsterPaused = !monsterPaused;
                      });
                      print('Monster AI ${monsterPaused ? 'paused' : 'resumed'}');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: monsterPaused ? Colors.green : Colors.red,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text(
                      monsterPaused ? 'Resume Monster' : 'Pause Monster',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // HUD - Player and Allies (Top-right corner)
          Positioned(
            top: 120,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Player Interface
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Player label
                      Text(
                        'PLAYER',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 8),
                      // Health circles
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: List.generate(4, (index) {
                          return Container(
                            margin: EdgeInsets.only(left: index > 0 ? 8 : 0),
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red,
                              border: Border.all(color: Colors.red.shade900, width: 3),
                            ),
                          );
                        }),
                      ),
                      SizedBox(height: 12),
                      // Ability buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _buildAbilityButton(
                            label: '1',
                            color: Color(0xFFB3B3CC), // Gray (sword)
                            cooldown: ability1Cooldown,
                            maxCooldown: ability1CooldownMax,
                            onPressed: _activateAbility1,
                          ),
                          SizedBox(width: 10),
                          _buildAbilityButton(
                            label: '2',
                            color: Color(0xFFFF6600), // Orange (fireball)
                            cooldown: ability2Cooldown,
                            maxCooldown: ability2CooldownMax,
                            onPressed: _activateAbility2,
                          ),
                          SizedBox(width: 10),
                          _buildAbilityButton(
                            label: '3',
                            color: Color(0xFF80FF4D), // Green (heal)
                            cooldown: ability3Cooldown,
                            maxCooldown: ability3CooldownMax,
                            onPressed: _activateAbility3,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Allies Display
                ...allies.asMap().entries.map((entry) {
                  final index = entry.key;
                  final ally = entry.value;
                  final abilityNames = ['Sword', 'Fireball', 'Heal'];
                  final abilityColors = [
                    Color(0xFFB3B3CC), // Gray (sword)
                    Color(0xFFFF6600), // Orange (fireball)
                    Color(0xFF80FF4D), // Green (heal)
                  ];

                  return Container(
                    margin: EdgeInsets.only(top: 12),
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.cyan, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Ally label
                        Text(
                          'ALLY ${index + 1}',
                          style: TextStyle(
                            color: Colors.cyan,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 6),
                        // Health bar
                        Container(
                          width: 150,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade800,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey.shade600, width: 2),
                          ),
                          child: Stack(
                            children: [
                              // Health fill
                              FractionallySizedBox(
                                widthFactor: (ally.health / ally.maxHealth).clamp(0.0, 1.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: ally.health > 25 ? Colors.green :
                                           ally.health > 12 ? Colors.orange : Colors.red,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              // Health text
                              Center(
                                child: Text(
                                  '${ally.health.toStringAsFixed(0)} / ${ally.maxHealth.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 8),
                        // Ability display
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              abilityNames[ally.abilityIndex],
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 9,
                              ),
                            ),
                            SizedBox(width: 6),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: ally.abilityCooldown > 0
                                    ? Colors.grey.shade700
                                    : abilityColors[ally.abilityIndex],
                                border: Border.all(color: Colors.white30, width: 2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Text(
                                  '${ally.abilityIndex + 1}',
                                  style: TextStyle(
                                    color: ally.abilityCooldown > 0
                                        ? Colors.white38
                                        : Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),

          // Ally management buttons (Top-right corner)
          Positioned(
            top: 10,
            right: 170,
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.cyan, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'ALLIES (${allies.length})',
                    style: TextStyle(
                      color: Colors.cyan,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      // Add Ally button
                      ElevatedButton(
                        onPressed: _addAlly,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size(50, 30),
                        ),
                        child: Text(
                          '+ Ally',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      // Remove Ally button
                      ElevatedButton(
                        onPressed: allies.isEmpty ? null : _removeAlly,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          disabledBackgroundColor: Colors.grey.shade700,
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size(50, 30),
                        ),
                        child: Text(
                          '- Ally',
                          style: TextStyle(
                            color: allies.isEmpty ? Colors.white38 : Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }

  // Build ability button with cooldown clock animation
  Widget _buildAbilityButton({
    required String label,
    required Color color,
    required double cooldown,
    required double maxCooldown,
    VoidCallback? onPressed,
  }) {
    final isOnCooldown = cooldown > 0;
    final progress = isOnCooldown ? (1.0 - (cooldown / maxCooldown)) : 1.0;

    return InkWell(
      onTap: isOnCooldown || onPressed == null ? null : onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.black87,
          border: Border.all(color: Colors.white30, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            // Base color
            Container(
              decoration: BoxDecoration(
                color: isOnCooldown ? Colors.grey.shade700 : color,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            // Cooldown clock animation
            if (isOnCooldown)
              CustomPaint(
                size: Size(60, 60),
                painter: CooldownClockPainter(progress: progress),
              ),
            // Label
            Center(
              child: Text(
                label,
                style: TextStyle(
                  color: isOnCooldown ? Colors.white38 : Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Cooldown text
            if (isOnCooldown)
              Positioned(
                bottom: 4,
                right: 4,
                child: Text(
                  cooldown.toStringAsFixed(1),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Stop game loop
    if (animationFrameId != null) {
      html.window.cancelAnimationFrame(animationFrameId!);
    }

    // Cleanup renderer
    renderer?.dispose();

    // Remove canvas from DOM
    canvas.remove();

    super.dispose();
  }
}

class Math {
  static double sin(double radians) => math.sin(radians);
  static double cos(double radians) => math.cos(radians);
}

/// CustomPainter for cooldown clock animation
/// Draws a sweeping dark overlay that reveals the ability as cooldown completes
class CooldownClockPainter extends CustomPainter {
  final double progress; // 0.0 = just started cooldown, 1.0 = ready

  CooldownClockPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Dark overlay that sweeps clockwise as cooldown progresses
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    // Calculate sweep angle (starts at top, sweeps clockwise)
    // progress 0.0 = full circle (360°), progress 1.0 = no circle (0°)
    final sweepAngle = (1.0 - progress) * 2 * math.pi;

    // Draw arc from top (-π/2) sweeping clockwise
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start at top (12 o'clock)
      sweepAngle, // Sweep clockwise
      true, // Use center (filled pie slice)
      paint,
    );
  }

  @override
  bool shouldRepaint(CooldownClockPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
