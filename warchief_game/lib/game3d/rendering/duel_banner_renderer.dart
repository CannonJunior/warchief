import 'package:vector_math/vector_math.dart' hide Colors;
import '../../rendering3d/webgl_renderer.dart';
import '../../rendering3d/camera3d.dart';
import '../../rendering3d/math/transform3d.dart';
import '../../rendering3d/mesh.dart';
import '../state/duel_banner_state.dart';

/// Renders the duel arena banner: a pole that drops from the sky, a cloth
/// banner that flutters in the wind, and a coloured victory flag that rises
/// up the pole when the duel concludes.
///
/// All geometry is built lazily on first use and reused each frame.
/// Static [Transform3d] objects are mutated each frame to avoid allocation.
class DuelBannerRenderer {
  DuelBannerRenderer._();

  // ── Pole ──────────────────────────────────────────────────────────────────
  static Mesh? _poleMesh;
  static final Transform3d _poleT = Transform3d();

  // ── Banner cloth ──────────────────────────────────────────────────────────
  static Mesh? _bannerMesh;
  static final Transform3d _bannerT = Transform3d();

  // ── Victory flag ──────────────────────────────────────────────────────────
  static Mesh? _flagMesh;
  static String? _lastWinnerId;
  static final Transform3d _flagT = Transform3d();

  // ── Public render entry ───────────────────────────────────────────────────

  static void render(
    WebGLRenderer renderer,
    Camera3D camera,
    DuelBannerState state,
  ) {
    if (state.phase == DuelBannerPhase.idle) return;

    _ensurePole();
    _ensureBanner();

    final poleTopY = state.poleBaseY + DuelBannerState.poleHeight;

    // ── Pole ─────────────────────────────────────────────────────────────
    _poleT.position = Vector3(
      state.centerX,
      state.poleBaseY + DuelBannerState.poleHeight / 2.0,
      state.centerZ,
    );
    _poleT.scale    = Vector3(0.3, DuelBannerState.poleHeight, 0.3);
    _poleT.rotation = Vector3.zero();
    renderer.render(_poleMesh!, _poleT, camera);

    // ── Banner cloth ──────────────────────────────────────────────────────
    // Reason: pitch=-90 turns the horizontal XZ plane into a vertical XY plane.
    // Yaw rotates it to face the wind direction; roll creates the flutter.
    _bannerT.position = Vector3(
      state.centerX,
      poleTopY - 1.0, // cloth centre is 1 unit below the pole tip
      state.centerZ,
    );
    _bannerT.rotation = Vector3(-90.0, state.bannerYawDeg, state.bannerRollDeg);
    _bannerT.scale    = Vector3(1.0, 1.0, 1.0);
    renderer.render(_bannerMesh!, _bannerT, camera);

    // ── Victory flag ──────────────────────────────────────────────────────
    if (state.winnerId != null) {
      _ensureFlag(state.winnerId!);
      _flagT.position = Vector3(
        state.centerX,
        state.poleBaseY + state.flagHeightY + 0.6,
        state.centerZ,
      );
      _flagT.rotation = Vector3(-90.0, state.bannerYawDeg, state.bannerRollDeg);
      _flagT.scale    = Vector3(1.0, 1.0, 1.0);
      renderer.render(_flagMesh!, _flagT, camera);
    }
  }

  // ── Lazy mesh builders ────────────────────────────────────────────────────

  static void _ensurePole() {
    // Reason: cube scaled thin+tall reads as a pole in isometric view without
    // requiring a cylinder mesh factory.
    _poleMesh ??= Mesh.cube(
      size:  1.0,
      color: Vector3(0.55, 0.35, 0.15), // warm wood brown
    );
  }

  static void _ensureBanner() {
    // Double-sided plane; pitch=-90° in the transform makes it stand vertical.
    _bannerMesh ??= Mesh.plane(
      width:  3.0,
      height: 2.0,
      color:  Vector3(0.75, 0.60, 0.10), // gold/ochre cloth
    );
  }

  static void _ensureFlag(String winnerId) {
    if (_lastWinnerId == winnerId) return;
    _lastWinnerId = winnerId;
    final color = switch (winnerId) {
      'challenger' => Vector3(0.25, 0.55, 1.00), // blue side wins
      'enemy'      => Vector3(1.00, 0.25, 0.25), // red side wins
      _            => Vector3(1.00, 0.85, 0.10), // draw → gold
    };
    _flagMesh = Mesh.plane(width: 1.8, height: 1.2, color: color);
  }
}
