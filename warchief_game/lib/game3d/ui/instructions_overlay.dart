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
              '1: Sword ${gameState.ability1Cooldown > 0 ? "(${gameState.ability1Cooldown.toStringAsFixed(1)}s)" : "READY"}',
              style: TextStyle(
                color: gameState.ability1Cooldown > 0 ? Colors.red : Colors.green,
                fontSize: 10,
              ),
            ),
            Text(
              '2: Fireball ${gameState.ability2Cooldown > 0 ? "(${gameState.ability2Cooldown.toStringAsFixed(1)}s)" : "READY"}',
              style: TextStyle(
                color: gameState.ability2Cooldown > 0 ? Colors.red : Colors.green,
                fontSize: 10,
              ),
            ),
            Text(
              '3: Heal ${gameState.ability3Cooldown > 0 ? "(${gameState.ability3Cooldown.toStringAsFixed(1)}s)" : "READY"}',
              style: TextStyle(
                color: gameState.ability3Cooldown > 0 ? Colors.red : Colors.green,
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
    );
  }
}
