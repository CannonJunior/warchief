import 'package:flutter/material.dart';
import '../state/game_state.dart';
import '../../rendering3d/camera3d.dart';

/// Instructions overlay showing camera controls, movement, and abilities with cooldown status
class InstructionsOverlay extends StatelessWidget {
  final Camera3D? camera;
  final GameState gameState;

  const InstructionsOverlay({
    Key? key,
    required this.camera,
    required this.gameState,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 10,
      left: 10,
      child: Container(
        padding: EdgeInsets.all(8),
        color: Colors.black54,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Camera: J/L=Yaw | N/M=Pitch | I/K=Zoom | V=Toggle Mode',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
            SizedBox(height: 2),
            Text(
              'Mode: ${camera?.mode == CameraMode.thirdPerson ? "Third-Person (90° FOV)" : "Static Orbit"}',
              style: TextStyle(
                color: camera?.mode == CameraMode.thirdPerson ? Colors.cyan : Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
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
              '1: Sword ${gameState.ability1Cooldown > 0 ? "(${gameState.ability1Cooldown.toStringAsFixed(1)}s)" : "READY"}',
              style: TextStyle(
                color: gameState.ability1Cooldown > 0 ? Colors.red : Colors.green,
                fontSize: 10,
              ),
            ),
            Text(
              '2: Fireball ${gameState.ability2Cooldown > 0 ? "(${gameState.ability2Cooldown.toStringAsFixed(1)}s)" : "READY"} [15 mana]',
              style: TextStyle(
                color: gameState.ability2Cooldown > 0 ? Colors.red : Colors.green,
                fontSize: 10,
              ),
            ),
            Text(
              '3: Heal ${gameState.ability3Cooldown > 0 ? "(${gameState.ability3Cooldown.toStringAsFixed(1)}s)" : "READY"} [20 mana]',
              style: TextStyle(
                color: gameState.ability3Cooldown > 0 ? Colors.red : Colors.green,
                fontSize: 10,
              ),
            ),
            SizedBox(height: 4),
            // Mana status
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Color(0xFF4080FF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                SizedBox(width: 4),
                Text(
                  'Mana: ${gameState.blueMana.toInt()}/${gameState.maxBlueMana.toInt()}',
                  style: TextStyle(
                    color: Color(0xFF80B0FF),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (gameState.currentManaRegenRate > 0)
                  Text(
                    ' (+${gameState.currentManaRegenRate.toStringAsFixed(1)}/s)',
                    style: TextStyle(
                      color: Color(0xFF60FF60),
                      fontSize: 9,
                    ),
                  ),
              ],
            ),
            if (gameState.currentLeyLineInfo != null && gameState.currentLeyLineInfo!.isInRange)
              Text(
                'Near Ley Line (${gameState.currentLeyLineInfo!.distance.toStringAsFixed(1)}m)',
                style: TextStyle(
                  color: Color(0xFF4080FF),
                  fontSize: 9,
                  fontStyle: FontStyle.italic,
                ),
              ),
            SizedBox(height: 4),
            // Casting/Windup status
            if (gameState.isCasting)
              Text(
                'Casting: ${gameState.castingAbilityName} (${(gameState.currentCastTime - gameState.castProgress).toStringAsFixed(1)}s)',
                style: TextStyle(
                  color: Color(0xFF4A90D9),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (gameState.isWindingUp)
              Text(
                'Windup: ${gameState.windupAbilityName} (${(gameState.currentWindupTime - gameState.windupProgress).toStringAsFixed(1)}s)',
                style: TextStyle(
                  color: Color(0xFFD97B4A),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            SizedBox(height: 8),
            Text(
              'Ally Commands:',
              style: TextStyle(color: Colors.cyan, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2),
            Text(
              'T=Attack | F=Follow | G=Hold | R=Formation',
              style: TextStyle(color: Colors.white, fontSize: 10),
            ),
            Text(
              'SHIFT+key = Show/Hide panel (draggable)',
              style: TextStyle(color: Colors.white60, fontSize: 9),
            ),
            SizedBox(height: 4),
            Text(
              'UI Panels:',
              style: TextStyle(color: Colors.cyan, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2),
            Text(
              'C=Character | B=Bag | P=Abilities | ESC=Close',
              style: TextStyle(color: Colors.white, fontSize: 10),
            ),
            Text(
              'SHIFT+D = DPS Testing (Target Dummy)',
              style: TextStyle(color: Color(0xFFFF6B35), fontSize: 10),
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
    );
  }
}
