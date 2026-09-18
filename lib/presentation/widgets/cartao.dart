import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/colors.dart';
import '../theme/motion.dart';

class Cartao extends StatelessWidget {
  const Cartao({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.animate = true,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? CheckmeColors.cartao,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CheckmeColors.borda),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140D47A1),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
    if (!animate) return box;
    return box
        .animate()
        .fadeIn(duration: CheckmeMotion.appear, curve: CheckmeMotion.easeOutCubic)
        .slideY(
          begin: 0.04,
          end: 0,
          duration: CheckmeMotion.appear,
          curve: CheckmeMotion.easeOutCubic,
        );
  }
}
