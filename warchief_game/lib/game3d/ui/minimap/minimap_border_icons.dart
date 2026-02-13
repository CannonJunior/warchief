import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../state/wind_state.dart';
import '../../state/minimap_config.dart';

/// Border decorations for the minimap: orbiting sun icons, zoom buttons,
/// and a wind direction arrow.
///
/// Positioned as an overlay on the minimap Stack with Clip.none so icons
/// can extend beyond the circular border.
class MinimapBorderIcons extends StatelessWidget {
  /// Diameter of the minimap circle.
  final double size;

  /// Total elapsed game time for orbital calculations.
  final double elapsedTime;

  /// Wind state for the wind direction arrow.
  final WindState windState;

  /// Current zoom level index.
  final int zoomLevel;

  /// Total number of zoom levels.
  final int zoomLevelCount;

  /// Callback for zoom in button.
  final VoidCallback onZoomIn;

  /// Callback for zoom out button.
  final VoidCallback onZoomOut;

  /// Player facing rotation in degrees (for North indicator positioning).
  final double playerRotation;

  /// Whether the minimap is in rotating mode (true) or fixed-north (false).
  final bool isRotatingMode;

  /// Callback to toggle between rotating and fixed-north mode.
  final VoidCallback onToggleRotation;

  const MinimapBorderIcons({
    Key? key,
    required this.size,
    required this.elapsedTime,
    required this.windState,
    required this.zoomLevel,
    required this.zoomLevelCount,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.playerRotation,
    required this.isRotatingMode,
    required this.onToggleRotation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final config = globalMinimapConfig;
    final sunDefs = config?.suns ?? [];
    final radius = size / 2;

    return SizedBox(
      width: size + 20,
      height: size + 20,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Orbiting sun icons
          ...sunDefs.map((sunDef) => _buildSunIcon(sunDef, radius)),

          // North indicator on border
          _buildNorthIndicator(radius),

          // Wind direction arrow on border
          if (config?.showWindOnBorder ?? true) _buildWindArrow(radius),

          // Rotation mode toggle at bottom-left
          Positioned(
            left: 0,
            bottom: 0,
            child: _buildRotationToggle(),
          ),

          // Zoom buttons at bottom-right
          Positioned(
            right: 0,
            bottom: 0,
            child: _buildZoomButtons(),
          ),
        ],
      ),
    );
  }

  /// Build a single orbiting sun icon positioned on the minimap border.
  Widget _buildSunIcon(Map<String, dynamic> sunDef, double radius) {
    final name = sunDef['name'] as String? ?? 'Sun';
    final colorList = sunDef['color'] as List<dynamic>? ?? [1.0, 0.95, 0.6, 1.0];
    final period = (sunDef['orbitalPeriod'] as num?)?.toDouble() ?? 600.0;
    final startAngle = (sunDef['startAngle'] as num?)?.toDouble() ?? 0.0;
    final iconSize = (sunDef['iconSize'] as num?)?.toDouble() ?? 14.0;

    final color = Color.fromRGBO(
      ((colorList[0] as num).toDouble() * 255).round(),
      ((colorList[1] as num).toDouble() * 255).round(),
      ((colorList[2] as num).toDouble() * 255).round(),
      (colorList.length > 3 ? (colorList[3] as num).toDouble() : 1.0),
    );

    // Calculate orbital angle from elapsed time
    final angleDeg = startAngle + (elapsedTime % period) / period * 360.0;
    final angleRad = angleDeg * math.pi / 180.0;

    // Position on border circle (offset by center of parent SizedBox)
    final orbitRadius = radius + 4; // Just outside the minimap border
    final centerX = (size + 20) / 2 + math.cos(angleRad - math.pi / 2) * orbitRadius;
    final centerY = (size + 20) / 2 + math.sin(angleRad - math.pi / 2) * orbitRadius;

    return Positioned(
      left: centerX - iconSize / 2,
      top: centerY - iconSize / 2,
      child: Tooltip(
        message: name,
        child: Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color,
                color.withOpacity(0.6),
                color.withOpacity(0.0),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: iconSize * 0.4,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: iconSize * 0.5,
              height: iconSize * 0.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build the wind direction arrow on the minimap border.
  Widget _buildWindArrow(double radius) {
    final config = globalMinimapConfig;
    final arrowSize = (config?.windArrowSize ?? 10).toDouble();
    final windAngleDeg = windState.windAngleDegrees;
    final windAngleRad = windAngleDeg * math.pi / 180.0;
    final isDerecho = windState.isDerechoActive;
    final derechoInt = windState.derechoIntensity;
    final strength = windState.windStrength;

    // Position on border
    final orbitRadius = radius + 2;
    final centerX = (size + 20) / 2 +
        math.cos(windAngleRad - math.pi / 2) * orbitRadius;
    final centerY = (size + 20) / 2 +
        math.sin(windAngleRad - math.pi / 2) * orbitRadius;

    // Color: silver-white normally, orange during derecho
    Color arrowColor;
    if (isDerecho) {
      arrowColor = Color.lerp(
        const Color(0xFFE0E0E0),
        const Color(0xFFFF8800),
        derechoInt,
      )!;
    } else {
      arrowColor = Color.lerp(
        const Color(0xFF888899),
        const Color(0xFFF0F0FF),
        strength,
      )!;
    }

    return Positioned(
      left: centerX - arrowSize / 2,
      top: centerY - arrowSize / 2,
      child: Transform.rotate(
        angle: windAngleRad,
        child: CustomPaint(
          size: Size(arrowSize, arrowSize),
          painter: _SmallArrowPainter(color: arrowColor),
        ),
      ),
    );
  }

  /// Build the North ("N") indicator on the minimap border.
  /// In rotating mode, it orbits to show where north is relative to the player.
  /// In fixed-north mode, it stays at the top.
  Widget _buildNorthIndicator(double radius) {
    // In rotating mode, north's position depends on player rotation.
    // At rotation 0 (facing south), north is at 180° (bottom).
    // The pattern is: angle = 180 + playerRotation (CW from top).
    // In fixed-north mode, north is always at the top (0°).
    final angleDeg = isRotatingMode ? 180.0 + playerRotation : 0.0;
    final angleRad = (angleDeg - 90.0) * math.pi / 180.0;

    final orbitRadius = radius + 4;
    final centerX = (size + 20) / 2 + math.cos(angleRad) * orbitRadius;
    final centerY = (size + 20) / 2 + math.sin(angleRad) * orbitRadius;
    const indicatorSize = 16.0;

    return Positioned(
      left: centerX - indicatorSize / 2,
      top: centerY - indicatorSize / 2,
      child: Container(
        width: indicatorSize,
        height: indicatorSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF0A0A1A).withOpacity(0.7),
          border: Border.all(
            color: const Color(0xFFCCA040),
            width: 1,
          ),
        ),
        child: const Center(
          child: Text(
            'N',
            style: TextStyle(
              color: Color(0xFFCCA040),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }

  /// Build the rotation mode toggle button.
  Widget _buildRotationToggle() {
    return GestureDetector(
      onTap: onToggleRotation,
      child: Tooltip(
        message: isRotatingMode ? 'Switch to fixed north' : 'Switch to rotating',
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A1A).withOpacity(0.8),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: isRotatingMode
                  ? const Color(0xFF4cc9f0)
                  : const Color(0xFFCCA040),
              width: 1,
            ),
          ),
          child: Center(
            child: Icon(
              isRotatingMode ? Icons.explore : Icons.north,
              color: isRotatingMode
                  ? const Color(0xFF4cc9f0)
                  : const Color(0xFFCCA040),
              size: 12,
            ),
          ),
        ),
      ),
    );
  }

  /// Build zoom in/out buttons.
  Widget _buildZoomButtons() {
    final canZoomIn = zoomLevel > 0;
    final canZoomOut = zoomLevel < zoomLevelCount - 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildZoomButton('+', canZoomIn, onZoomIn),
        const SizedBox(height: 2),
        _buildZoomButton('-', canZoomOut, onZoomOut),
      ],
    );
  }

  /// Build a single zoom button.
  Widget _buildZoomButton(String label, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A1A).withOpacity(0.8),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: enabled
                ? const Color(0xFF555577)
                : const Color(0xFF333344),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: enabled
                  ? const Color(0xFFCCCCCC)
                  : const Color(0xFF666666),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

/// Tiny arrow painter for the wind direction indicator on the border.
class _SmallArrowPainter extends CustomPainter {
  final Color color;

  _SmallArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final halfW = size.width * 0.3;
    final halfH = size.height * 0.45;

    final path = Path()
      ..moveTo(cx, cy - halfH)
      ..lineTo(cx + halfW, cy + halfH * 0.4)
      ..lineTo(cx, cy + halfH * 0.1)
      ..lineTo(cx - halfW, cy + halfH * 0.4)
      ..close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SmallArrowPainter oldDelegate) =>
      oldDelegate.color != color;
}
