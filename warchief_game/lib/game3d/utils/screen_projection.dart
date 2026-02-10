import 'dart:ui';
import 'package:vector_math/vector_math.dart';

/// Project a 3D world position to 2D screen coordinates.
///
/// Uses the standard world → view → clip → NDC → screen pipeline.
/// Returns null if the point is behind the camera (clipVec.w <= 0).
///
/// Args:
///   worldPos: The 3D position to project.
///   viewMatrix: Camera view matrix.
///   projMatrix: Camera projection matrix.
///   screenSize: Current screen/viewport size in pixels.
///
/// Returns:
///   Offset in screen pixels, or null if behind camera.
Offset? worldToScreen(
  Vector3 worldPos,
  Matrix4 viewMatrix,
  Matrix4 projMatrix,
  Size screenSize,
) {
  // Transform world position to clip space
  final worldVec = Vector4(worldPos.x, worldPos.y, worldPos.z, 1.0);
  final viewVec = viewMatrix.transform(worldVec);
  final clipVec = projMatrix.transform(viewVec);

  // Behind camera check
  if (clipVec.w <= 0.0) return null;

  // Perspective divide to NDC (-1 to 1)
  final ndcX = clipVec.x / clipVec.w;
  final ndcY = clipVec.y / clipVec.w;

  // NDC to screen pixels (Y is flipped: WebGL top=-1, Flutter top=0)
  final screenX = ((ndcX + 1.0) / 2.0) * screenSize.width;
  final screenY = ((1.0 - ndcY) / 2.0) * screenSize.height;

  return Offset(screenX, screenY);
}
