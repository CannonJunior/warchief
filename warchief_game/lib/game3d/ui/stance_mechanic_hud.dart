import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/stances/stance_types.dart';
import '../data/stances/stance_mechanics.dart';
import '../state/game_state.dart';
import '../state/stance_runtime_state.dart';

/// Compact HUD widget showing active stance mechanic state above the action bar.
///
/// Displays different indicators based on the active stance:
/// - **Cadence**: Beat pulse arc + Groove stack dots
/// - **Tempest**: Chain depth counter (1-4)
/// - **Warden**: Directional arrow + Predator's Eye indicator
/// - **Crucible**: Heat gauge (0-10 bars)
/// - **Momentum**: Stack counter (0-8) with splash indicator
/// - **Pressure**: Pressure gauge fill on current target
/// - **Flux**: Transition/Weave/Stagnation status
class StanceMechanicHud extends StatelessWidget {
  final GameState gameState;

  const StanceMechanicHud({super.key, required this.gameState});

  @override
  Widget build(BuildContext context) {
    final stanceId = gameState.playerStance;
    final m = gameState.activeStance.mechanics;
    if (m == null) return const SizedBox.shrink();
    final s = gameState.stanceRuntime;

    return switch (stanceId) {
      StanceId.cadence => _buildCadence(m, s),
      StanceId.tempest => _buildTempest(m, s),
      StanceId.warden => _buildWarden(m, s),
      StanceId.crucible => _buildCrucible(m, s),
      StanceId.momentum => _buildMomentum(m, s),
      StanceId.pressure => _buildPressure(m, s),
      StanceId.flux => _buildFlux(m, s),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildCadence(StanceMechanics m, StanceRuntimeState s) {
    final beatProgress = m.rhythmPulseInterval > 0
        ? s.cadenceBeatTimer / m.rhythmPulseInterval
        : 0.0;
    final onBeat = s.cadenceLastCastOnBeat;
    return _hudRow(
      const Color(0xFFE69833),
      children: [
        SizedBox(
          width: 24, height: 24,
          child: CustomPaint(painter: _BeatPulsePainter(beatProgress, onBeat)),
        ),
        const SizedBox(width: 6),
        ...List.generate(m.grooveMaxStacks, (i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < s.cadenceGrooveStacks
                  ? const Color(0xFFFFD700)
                  : const Color(0x44FFFFFF),
              border: Border.all(color: const Color(0x88FFD700), width: 0.5),
            ),
          ),
        )),
        const SizedBox(width: 6),
        Text(
          'Groove ${s.cadenceGrooveStacks}',
          style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildTempest(StanceMechanics m, StanceRuntimeState s) {
    final inChain = s.tempestChainDepth > 0;
    return _hudRow(
      const Color(0xFFFF7320),
      children: [
        Icon(
          Icons.speed,
          size: 16,
          color: inChain ? const Color(0xFFFF9944) : const Color(0x88FFFFFF),
        ),
        const SizedBox(width: 6),
        ...List.generate(m.cancelMaxChain, (i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Container(
            width: 10, height: 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: i < s.tempestChainDepth
                  ? Color.lerp(
                      const Color(0xFFFF7320),
                      const Color(0xFFFFDD00),
                      i / m.cancelMaxChain.toDouble(),
                    )
                  : const Color(0x33FFFFFF),
              border: Border.all(
                color: i < s.tempestChainDepth
                    ? const Color(0xCCFFAA44)
                    : const Color(0x22FFFFFF),
                width: 0.5,
              ),
            ),
          ),
        )),
        if (inChain) ...[
          const SizedBox(width: 6),
          Text(
            'x${s.tempestChainDepth} CHAIN',
            style: const TextStyle(
              color: Color(0xFFFFDD00), fontSize: 11, fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWarden(StanceMechanics m, StanceRuntimeState s) {
    final dir = s.wardenInputTimer > 0
        ? s.wardenLastDirection
        : WardenDirection.stationary;
    final predator = s.wardenInPredatorMode;

    final (icon, label) = switch (dir) {
      WardenDirection.forward => (Icons.arrow_upward, 'FWD'),
      WardenDirection.backward => (Icons.arrow_downward, 'BACK'),
      WardenDirection.strafeLeft => (Icons.arrow_back, 'LEFT'),
      WardenDirection.strafeRight => (Icons.arrow_forward, 'RIGHT'),
      WardenDirection.sprint => (Icons.fast_forward, 'SPRINT'),
      WardenDirection.stationary => (Icons.gps_fixed, 'STILL'),
      WardenDirection.none => (Icons.remove, '—'),
    };

    return _hudRow(
      predator ? const Color(0xFF44BB44) : const Color(0xFF4D8C59),
      children: [
        Icon(icon, size: 16, color: const Color(0xCCFFFFFF)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 11)),
        if (predator) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFF228B22),
              borderRadius: BorderRadius.circular(3),
            ),
            child: const Text(
              'PREDATOR',
              style: TextStyle(
                color: Color(0xFFFFFFFF), fontSize: 10, fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCrucible(StanceMechanics m, StanceRuntimeState s) {
    final heat = s.crucibleHeatStacks;
    final max = m.heatMaxStacks;
    final overheated = s.crucibleOverheated;
    final atZero = s.crucibleAtZeroHeat;
    return _hudRow(
      overheated ? const Color(0xFFFF2200) : const Color(0xFFCC4400),
      children: [
        Icon(
          overheated ? Icons.warning_amber : Icons.local_fire_department,
          size: 16,
          color: overheated ? const Color(0xFFFF4444) : const Color(0xFFFF8844),
        ),
        const SizedBox(width: 6),
        ...List.generate(max, (i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0.5),
          child: Container(
            width: 6, height: 14,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1),
              color: i < heat
                  ? Color.lerp(const Color(0xFFFF8800), const Color(0xFFFF0000), i / max.toDouble())!
                  : const Color(0x22FFFFFF),
            ),
          ),
        )),
        const SizedBox(width: 6),
        Text(
          overheated ? 'OVERHEAT!'
              : atZero ? 'PAYOFF READY'
              : '$heat/$max',
          style: TextStyle(
            color: overheated ? const Color(0xFFFF4444)
                : atZero ? const Color(0xFF44FF44)
                : const Color(0xCCFFFFFF),
            fontSize: 11,
            fontWeight: overheated || atZero ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildMomentum(StanceMechanics m, StanceRuntimeState s) {
    final stacks = s.momentumStacks;
    final max = m.momentumMaxStacks;
    final atMax = stacks >= max;
    return _hudRow(
      atMax ? const Color(0xFF3366FF) : const Color(0xFF335599),
      children: [
        Icon(
          Icons.trending_up, size: 16,
          color: atMax ? const Color(0xFF66AAFF) : const Color(0x88FFFFFF),
        ),
        const SizedBox(width: 6),
        ...List.generate(max, (i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0.5),
          child: Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < stacks
                  ? const Color(0xFF4488FF)
                  : const Color(0x22FFFFFF),
              border: Border.all(
                color: i < stacks ? const Color(0xAA66AAFF) : const Color(0x11FFFFFF),
                width: 0.5,
              ),
            ),
          ),
        )),
        const SizedBox(width: 6),
        Text(
          atMax ? 'MAX — SPLASH' : '$stacks/$max',
          style: TextStyle(
            color: atMax ? const Color(0xFF66DDFF) : const Color(0xCCFFFFFF),
            fontSize: 11,
            fontWeight: atMax ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildPressure(StanceMechanics m, StanceRuntimeState s) {
    final targetId = gameState.currentTargetId;
    final pressure = targetId != null
        ? (s.pressurePerTarget[targetId.hashCode] ?? 0.0)
        : 0.0;
    final pct = (pressure * 100).round();
    return _hudRow(
      const Color(0xFFCC2222),
      children: [
        Icon(Icons.compress, size: 16, color: const Color(0xCCFFFFFF)),
        const SizedBox(width: 6),
        SizedBox(
          width: 80, height: 10,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: pressure.clamp(0.0, 1.0),
              backgroundColor: const Color(0x33FFFFFF),
              valueColor: AlwaysStoppedAnimation(
                Color.lerp(const Color(0xFFCC4444), const Color(0xFFFF2200), pressure)!,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$pct%',
          style: TextStyle(
            color: pct >= 80 ? const Color(0xFFFF4444) : const Color(0xCCFFFFFF),
            fontSize: 11,
            fontWeight: pct >= 80 ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        if (pct >= 80)
          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Text('BREAK!', style: TextStyle(
              color: Color(0xFFFF6644), fontSize: 10, fontWeight: FontWeight.bold,
            )),
          ),
      ],
    );
  }

  Widget _buildFlux(StanceMechanics m, StanceRuntimeState s) {
    final hasTransition = s.fluxTransitionBonusAvailable;
    final weave = s.fluxWeaveActive;
    final stagnant = s.fluxStagnant;
    return _hudRow(
      weave ? const Color(0xFF9944FF) : const Color(0xFF6633AA),
      children: [
        Icon(Icons.swap_horiz, size: 16, color: const Color(0xCCFFFFFF)),
        const SizedBox(width: 6),
        if (hasTransition)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFF9955FF),
              borderRadius: BorderRadius.circular(3),
            ),
            child: const Text('FREE CAST', style: TextStyle(
              color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold,
            )),
          ),
        if (weave) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFFAA66FF),
              borderRadius: BorderRadius.circular(3),
            ),
            child: const Text('WEAVE', style: TextStyle(
              color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold,
            )),
          ),
        ],
        if (stagnant) ...[
          const SizedBox(width: 4),
          const Text('STAGNANT', style: TextStyle(
            color: Color(0xFFFF6644), fontSize: 10, fontWeight: FontWeight.bold,
          )),
        ],
        if (!hasTransition && !weave && !stagnant)
          const Text('Switch stance!', style: TextStyle(
            color: Color(0x88FFFFFF), fontSize: 11,
          )),
      ],
    );
  }

  Widget _hudRow(Color borderColor, {required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xCC111111),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor.withValues(alpha: 0.6), width: 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

/// Paints a circular beat arc for Cadence stance.
class _BeatPulsePainter extends CustomPainter {
  final double progress;
  final bool onBeat;

  _BeatPulsePainter(this.progress, this.onBeat);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    // Background ring
    canvas.drawCircle(
      center, radius,
      Paint()
        ..color = const Color(0x33FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Progress arc
    final sweep = progress * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..color = onBeat ? const Color(0xFFFFD700) : const Color(0xFFE69833)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // Beat indicator dot at top
    final nearBeat = progress < 0.1 || progress > 0.9;
    if (nearBeat) {
      canvas.drawCircle(
        Offset(center.dx, center.dy - radius),
        3,
        Paint()..color = const Color(0xFFFFD700),
      );
    }
  }

  @override
  bool shouldRepaint(_BeatPulsePainter old) => true;
}
