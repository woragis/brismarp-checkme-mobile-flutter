import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/motion.dart';

class CheckMark extends StatefulWidget {
  const CheckMark({super.key, this.size = 88});

  final double size;

  @override
  State<CheckMark> createState() => _CheckMarkState();
}

class _CheckMarkState extends State<CheckMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: CheckmeMotion.check)
      ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: CurvedAnimation(parent: _ctrl, curve: CheckmeMotion.easeOutBack),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return CustomPaint(
            size: Size.square(widget.size),
            painter: _CheckPainter(progress: _ctrl.value),
          );
        },
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 4;
    final circlePaint = Paint()
      ..color = CheckmeColors.sucesso
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -1.2,
      progress * 6.28318,
      false,
      circlePaint,
    );

    final fill = Paint()
      ..color = CheckmeColors.sucesso.withValues(alpha: 0.12 * progress)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(c, r, fill);

    final path = Path()
      ..moveTo(size.width * 0.28, size.height * 0.52)
      ..lineTo(size.width * 0.44, size.height * 0.68)
      ..lineTo(size.width * 0.74, size.height * 0.34);
    final metric = path.computeMetrics().first;
    final extract = metric.extractPath(0, metric.length * progress);
    final checkPaint = Paint()
      ..color = CheckmeColors.sucesso
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(extract, checkPaint);
  }

  @override
  bool shouldRepaint(covariant _CheckPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
