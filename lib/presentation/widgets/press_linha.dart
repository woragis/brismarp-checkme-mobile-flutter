import 'package:flutter/material.dart';

import '../theme/motion.dart';

class PressLinha extends StatefulWidget {
  const PressLinha({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<PressLinha> createState() => _PressLinhaState();
}

class _PressLinhaState extends State<PressLinha> {
  var _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapUp: enabled ? (_) => setState(() => _down = false) : null,
      onTapCancel: enabled ? () => setState(() => _down = false) : null,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.98 : 1,
        duration: CheckmeMotion.press,
        curve: CheckmeMotion.easeOut,
        child: widget.child,
      ),
    );
  }
}
