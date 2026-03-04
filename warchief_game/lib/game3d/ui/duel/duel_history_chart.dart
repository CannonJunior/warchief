part of 'duel_history_detail.dart';

// ── Health timeline point ─────────────────────────────────────────────────────

class _HealthPoint {
  final double t;
  final double chalPct;  // challenger party HP fraction 0–1
  final double enemyPct; // enemy party HP fraction 0–1
  const _HealthPoint(this.t, this.chalPct, this.enemyPct);
}

// ── Individual series point ───────────────────────────────────────────────────

class _ChartPoint {
  final double t;
  final double hpPct; // combatant HP fraction 0–1
  const _ChartPoint(this.t, this.hpPct);
}

// ── Individual series ─────────────────────────────────────────────────────────

class _ChartSeries {
  final List<_ChartPoint> points;
  final Color color;
  final String label;
  const _ChartSeries({required this.points, required this.color, required this.label});
}

// ── Party HP chart painter ────────────────────────────────────────────────────

class _HealthChartPainter extends CustomPainter {
  final List<_HealthPoint> timeline;
  final double duration;

  const _HealthChartPainter({required this.timeline, required this.duration});

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    _drawLine(canvas, size, _blue, (p) => p.chalPct);
    _drawLine(canvas, size, _red,  (p) => p.enemyPct);
    _drawYLabels(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 0.5;
    // 4 horizontal grid lines at 25 / 50 / 75 / 100 %
    for (int i = 1; i <= 4; i++) {
      final y = size.height * (1 - i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawLine(Canvas canvas, Size size, Color color,
      double Function(_HealthPoint) getValue) {
    if (timeline.length < 2) return;

    final path = Path();
    for (int i = 0; i < timeline.length; i++) {
      final p = timeline[i];
      final x = (p.t / duration) * size.width;
      final y = (1.0 - getValue(p)) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Translucent fill under the line
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..color = color.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill,
    );

    // The line itself
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawYLabels(Canvas canvas, Size size) {
    final style = TextStyle(
        color: Colors.white.withValues(alpha: 0.25), fontSize: 7.5);
    const labels = ['100%', '75%', '50%', '25%'];
    for (int idx = 0; idx < labels.length; idx++) {
      final y = size.height * idx / 4;
      final tp = TextPainter(
        text: TextSpan(text: labels[idx], style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(2, y + 1));
    }
  }

  @override
  bool shouldRepaint(_HealthChartPainter old) =>
      old.timeline != timeline || old.duration != duration;
}

// ── Individual HP chart painter ───────────────────────────────────────────────

class _IndividualChartPainter extends CustomPainter {
  final List<_ChartSeries> series;
  final double duration;

  const _IndividualChartPainter({required this.series, required this.duration});

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    for (final s in series) {
      if (s.points.length < 2) continue;
      _drawSeriesLine(canvas, size, s);
    }
    _drawYLabels(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 0.5;
    for (int i = 1; i <= 4; i++) {
      final y = size.height * (1 - i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawSeriesLine(Canvas canvas, Size size, _ChartSeries s) {
    final path = Path();
    for (int i = 0; i < s.points.length; i++) {
      final pt = s.points[i];
      final x = (pt.t / duration) * size.width;
      final y = (1.0 - pt.hpPct) * size.height;
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = s.color
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawYLabels(Canvas canvas, Size size) {
    final style = TextStyle(
        color: Colors.white.withValues(alpha: 0.25), fontSize: 7.5);
    const labels = ['100%', '75%', '50%', '25%'];
    for (int idx = 0; idx < labels.length; idx++) {
      final y = size.height * idx / 4;
      final tp = TextPainter(
        text: TextSpan(text: labels[idx], style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(2, y + 1));
    }
  }

  @override
  bool shouldRepaint(_IndividualChartPainter old) =>
      old.series != series || old.duration != duration;
}
