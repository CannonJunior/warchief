# AI Architecture - Advanced Movement and Decision System

## Overview

This document describes the new AI architecture implemented for monsters and allies in the Warchief game. The system uses Model Context Protocol (MCP) tools for decision-making and advanced pathfinding with Bezier curves for smooth, realistic movement.

## Core Components

### 1. Movement Prediction (`lib/game3d/utils/movement_prediction.dart`)

**MovementPredictor** - Tracks entity positions over time and predicts future locations

- Maintains position history (last 5 positions)
- Calculates velocity and acceleration
- Predicts linear and acceleration-based future positions
- Calculates intercept points for targeting moving entities

**PlayerMovementTracker** - Specialized tracker for player movement

- Provides convenient interface for AI to query player movement
- Used by monster and ally AI for predictive targeting

**Key Features:**
- Linear prediction: `predictLinear(timeAhead)`
- Acceleration-aware prediction: `predictWithAcceleration(timeAhead)`
- Intercept calculation: `calculateInterceptionPoint(interceptorPos, speed)`

###  2. Bezier Path System (`lib/game3d/utils/bezier_path.dart`)

**BezierPath** - Smooth curve interpolation for natural movement

Supports multiple curve types:
- Linear (2 points)
- Quadratic (3 points)
- Cubic (4 points)
- Higher-order curves via De Casteljau's algorithm

**Factory Constructors:**
- `BezierPath.quadratic()` - Simple curved paths
- `BezierPath.cubic()` - Complex smooth paths
- `BezierPath.interception()` - Creates curves for intercepting moving targets

**Key Methods:**
- `getPointAt(t)` - Get position at parameter t (0.0 to 1.0)
- `getTangentAt(t)` - Get direction vector at parameter t
- `advance(distance)` - Move along curve by distance
- `getLength()` - Get approximate curve length

**Use Cases:**
- Monster movement towards predicted player position
- Ally following player with buffer distance
- Smooth strafing/circling movements
- Natural-looking approach paths

### 3. MCP Tools (`lib/game3d/ai/mcp_tools.dart`)

**Tool Categories:**

#### Tactical Tools (Real-time, < 100ms)
- `assessThreat()` - Immediate danger response
- `selectQuickAbility()` - Fast ability selection

#### Strategic Tools (Planning, 1-2s)
- `planCombatStrategy()` - Comprehensive strategy analysis
- `analyzePositioning()` - Positioning and flanking opportunities

#### Movement Tools
- `calculateInterceptPath()` - Create Bezier path to intercept target
- `calculateStrafePath()` - Create circular/strafing movement

#### Combat Tools
- `evaluateAbilityEffectiveness()` - Rate abilities based on range/state

**AIContext** - Context object passed to tools containing:
- Self position, health, abilities
- Player position, velocity, health
- Ally positions and states
- Current combat state

**MCPToolResponse** - Standard response format:
```dart
MCPToolResponse(
  action: 'ACTION_NAME',
  parameters: {...},
  confidence: 0.85, // 0.0 to 1.0
  reasoning: 'Why this decision was made'
)
```

## Data Model Updates

### GameState (`lib/game3d/state/game_state.dart`)

Added:
```dart
// Player movement tracking for AI
final PlayerMovementTracker playerMovementTracker = PlayerMovementTracker();

// Monster pathfinding
BezierPath? monsterCurrentPath;
double monsterMoveSpeed = 3.0;
String monsterCurrentStrategy = 'BALANCED';
```

### Ally Model (`lib/models/ally.dart`)

Added movement modes:
```dart
enum AllyMovementMode {
  stationary,    // Stays in place
  followPlayer,  // Follows with buffer distance
  commanded,     // Moves to commanded position
  tactical,      // AI-controlled movement
}
```

Added fields:
```dart
AllyMovementMode movementMode;
BezierPath? currentPath;
double moveSpeed;
double followBufferDistance;
bool isMoving;
```

## Implementation Phases

### Phase 1: Foundation (COMPLETED)
- ✅ Movement prediction system
- ✅ Bezier curve pathfinding
- ✅ MCP tool architecture
- ✅ Data model updates

### Phase 2: Monster AI Integration (IN PROGRESS)
- Refactor `ai_system.dart` to use MCP tools
- Implement smooth movement with Bezier paths
- Add player movement tracking to game loop
- Integrate predictive targeting for abilities

### Phase 3: Ally AI Integration (PENDING)
- Apply MCP tools to ally decision-making
- Implement follow mode with buffer distance
- Add tactical positioning for allies
- Command system for ally movement

### Phase 4: Testing and Tuning (PENDING)
- Balance movement speeds
- Tune prediction accuracy
- Test pathfinding edge cases
- Performance optimization

## Usage Example: Monster Intercept Movement

```dart
// Update player movement tracking (in game loop)
gameState.playerMovementTracker.update(
  playerPosition,
  currentTime
);

// Get player velocity
final playerVelocity = gameState.playerMovementTracker.getVelocity();

// Create intercept path
final interceptPath = MCPTools.calculateInterceptPath(
  currentPosition: monsterPosition,
  targetPosition: playerPosition,
  targetVelocity: playerVelocity,
  currentVelocity: monsterVelocity,
  interceptorSpeed: 3.0,
);

gameState.monsterCurrentPath = interceptPath;

// Move along path (in update loop)
if (gameState.monsterCurrentPath != null) {
  final newPos = gameState.monsterCurrentPath!.advance(
    moveSpeed * dt
  );
  if (newPos != null) {
    monsterTransform.position = newPos;
  }
}
```

## Usage Example: Ally Follow Mode

```dart
// Set ally to follow mode
ally.movementMode = AllyMovementMode.followPlayer;
ally.followBufferDistance = Random().nextDouble() * 2 + 3.0; // 3-5 units

// Update ally movement (when player moves)
if (playerIsMoving && distanceToPlayer > ally.followBufferDistance) {
  // Create follow path with buffer distance
  final targetPos = playerPosition +
    (ally.position - playerPosition).normalized() * ally.followBufferDistance;

  ally.currentPath = BezierPath.interception(
    start: ally.position,
    target: targetPos,
    velocity: ally.currentVelocity,
  );

  ally.isMoving = true;
}

// Stop when player stops and within buffer
if (!playerIsMoving && distanceToPlayer <= ally.followBufferDistance * 1.2) {
  ally.isMoving = false;
  ally.currentPath = null;
  // Re-randomize buffer distance for next movement
  ally.followBufferDistance = Random().nextDouble() * 2 + 3.0;
}
```

## Performance Considerations

- Movement prediction uses rolling window (5 positions) for memory efficiency
- Bezier curves use approximation (20 samples) for length calculation
- MCP tactical tools designed for sub-100ms execution
- Strategic tools can take 1-2 seconds for complex analysis
- Pathfinding not called every frame - only on decision intervals

## Future Enhancements

- A* pathfinding for obstacle avoidance
- Formation movement for multiple allies
- Threat prioritization system
- Learning/adaptive AI based on player behavior
- Group tactics and coordinated attacks
