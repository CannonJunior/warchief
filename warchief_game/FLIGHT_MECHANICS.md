# Flight Mechanics - Context Document

Reference for Claude Code sessions working on the Warchief flight system.

## Flight State Fields (`game_state.dart`)

| Field | Type | Description |
|-------|------|-------------|
| `isFlying` | `bool` | Whether player is currently in flight |
| `flightPitchAngle` | `double` | Pitch in degrees (-45 to +45). Positive = climb, negative = dive |
| `flightBankAngle` | `double` | Bank/roll in degrees. Positive = right, negative = left |
| `flightSpeed` | `double` | Current flight speed (modified by boost/brake) |
| `flightAltitude` | `double` | Height above terrain (computed each frame by physics) |
| `sovereignBuffActive` | `bool` | Sovereign of the Sky speed buff (1.5x) |
| `windWarpSpeedActive` | `bool` | Wind Warp speed buff (2.0x) |

Flight starts via `startFlight()` (spends initial White Mana cost) and ends via `endFlight()`. Both reset `flightPitchAngle`, `flightBankAngle`, and `playerTransform.rotation.z` to 0.

## Input Mapping

| Key | Ground Action | Flight Action |
|-----|---------------|---------------|
| W | Move forward | Pitch up (climb) |
| S | Move backward | Pitch down (dive) |
| A | Rotate left (yaw) | Yaw left (bank-enhanced turn rate) |
| D | Rotate right (yaw) | Yaw right (bank-enhanced turn rate) |
| Q | Strafe left | Bank left (tilt) |
| E | Strafe right | Bank right (tilt) |
| Q+A | N/A | Barrel roll left (continuous) |
| E+D | N/A | Barrel roll right (continuous) |
| ALT | Sprint | Speed boost (1.5x) |
| Space | Jump | Air brake + upward bump |

## Config Values (`wind_config.json` > `flight` section)

### Original Flight Config (11 values)

| Key | Default | Description |
|-----|---------|-------------|
| `flightSpeed` | 7.0 | Base forward flight speed |
| `pitchRate` | 60.0 | Degrees/second pitch changes |
| `maxPitchAngle` | 45.0 | Max pitch angle in degrees |
| `boostMultiplier` | 1.5 | ALT boost speed multiplier |
| `brakeMultiplier` | 0.6 | Space brake speed multiplier |
| `brakeJumpForce` | 3.0 | Upward bump when braking |
| `manaDrainRate` | 3.0 | White Mana drained per second while flying |
| `lowManaThreshold` | 33.0 | Below this mana, descent begins |
| `lowManaDescentRate` | 2.0 | Descent speed when low on mana |
| `minAltitudeForDescent` | 10.0 | Minimum altitude for low-mana descent |
| `initialManaCost` | 15.0 | White Mana cost to start flight |

### Banking Config (6 values)

| Key | Default | Description |
|-----|---------|-------------|
| `bankRate` | 120.0 | Degrees/second bank angle increases while Q/E held |
| `maxBankAngle` | 60.0 | Max bank angle for normal banking. Does NOT cap barrel rolls |
| `autoLevelRate` | 90.0 | Degrees/second bank returns to 0 when keys released |
| `autoLevelThreshold` | 90.0 | If |bankAngle| >= this, auto-level is suppressed |
| `bankToTurnMultiplier` | 2.5 | How much banking amplifies A/D turn rate |
| `barrelRollRate` | 360.0 | Degrees/second for barrel roll rotation (Q+A or E+D) |

## Banking Physics

### Normal Banking (Q or E alone)
- Holding Q banks left at `bankRate` deg/s, clamped to `[-maxBankAngle, maxBankAngle]`
- Holding E banks right at `bankRate` deg/s, clamped to `[-maxBankAngle, maxBankAngle]`
- Releasing Q/E auto-levels toward 0 at `autoLevelRate` deg/s
- Exception: if `|bankAngle| >= autoLevelThreshold` (90 deg), auto-level is suppressed

### Bank-Enhanced Turn Rate
Turn rate formula when A/D is held:
```
bankAngleRad = clamp(|bankAngle|, 0, 90) * (pi / 180)
turnMultiplier = 1.0 + sin(bankAngleRad) * bankToTurnMultiplier
effectiveTurnRate = 180.0 * turnMultiplier
```

| Bank Angle | sin(angle) | Multiplier (2.5x) | Effective Turn Rate |
|-----------|-----------|-------------------|-------------------|
| 0 deg | 0.0 | 1.0x | 180 deg/s (unchanged) |
| 30 deg | 0.5 | 2.25x | 405 deg/s |
| 45 deg | 0.71 | 2.77x | 499 deg/s |
| 60 deg (max normal) | 0.87 | 3.17x | 570 deg/s |
| 90 deg | 1.0 | 3.5x | 630 deg/s |

## Barrel Roll Mechanics

### Combo Detection
- Q+A held simultaneously = barrel roll left
- E+D held simultaneously = barrel roll right
- Barrel roll combos take priority over individual banking or yaw

### Rotation
- Barrel roll rotates at `barrelRollRate` deg/s (default 360 = one full rotation per second)
- Bank angle is **uncapped** during barrel rolls (wraps at +/-360)
- During barrel rolls, A/D yaw is suppressed (the keys are consumed by the combo)

### Recovery
- When barrel roll keys are released, if `|bankAngle| < autoLevelThreshold`, auto-level engages
- If `|bankAngle| >= autoLevelThreshold` after a barrel roll exit, the player must manually bank back below 90 deg before auto-level will help

## Visual Rendering

`Transform3d.rotation` axis mapping:
- `rotation.x` = pitch (set by physics system)
- `rotation.y` = yaw (player facing direction in degrees)
- `rotation.z` = roll/bank (set by input system from `flightBankAngle`)

Rotation application order in the renderer: Y (yaw) -> X (pitch) -> Z (roll).

The visual roll is applied as:
```dart
playerTransform.rotation.z = flightBankAngle; // degrees (same unit as rotation.y for yaw)
```

**Sign convention**: Positive `flightBankAngle` = positive `rotateZ` = counter-clockwise from behind = bank LEFT. Q increases angle (bank left), E decreases (bank right).

### Camera Roll (Cockpit-Style)

During flight, the camera's up vector is rotated by `flightBankAngle` around the view direction using Rodrigues' rotation formula. This tilts the horizon like a cockpit view, making banking feel immersive.

```dart
camera.rollAngle = gameState.isFlying ? gameState.flightBankAngle : 0.0;
```

When not flying, `rollAngle` resets to 0 (level horizon). The roll is applied in `Camera3D.getViewMatrix()` via `_getCameraUpVector()`.

## Code Locations

| File | Responsibility |
|------|---------------|
| `lib/game3d/systems/input_system.dart` : `_handleFlightMovement()` | Flight input: pitch, banking, barrel rolls, yaw, boost, brake |
| `lib/game3d/systems/physics_system.dart` : `_updateFlight()` | Flight physics: altitude from pitch, ground collision, terrain following |
| `lib/game3d/state/game_state.dart` | Flight state fields, `startFlight()`, `endFlight()`, `toggleFlight()` |
| `lib/game3d/state/wind_config.dart` | Config getters for all flight values |
| `assets/data/wind_config.json` > `flight` | All flight config values (17 total) |
