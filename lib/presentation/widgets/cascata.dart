import 'package:flutter/material.dart';

import '../theme/motion.dart';

class Cascata extends StatefulWidget {
  const Cascata({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<Cascata> createState() => _CascataState();
}

class _CascataState extends State<Cascata> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: CheckmeMotion.appear,
    );
    Future<void>.delayed(
      Duration(milliseconds: CheckmeMotion.cascataPasso * widget.index),
      () {
        if (mounted) _controller.forward();
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curva = CurvedAnimation(
      parent: _controller,
      curve: CheckmeMotion.easeOutCubic,
    );
    return FadeTransition(
      opacity: curva,
      child: AnimatedBuilder(
        animation: curva,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 12 * (1 - curva.value)),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

class EntradaLateral extends StatefulWidget {
  const EntradaLateral({super.key, required this.child});

  final Widget child;

  @override
  State<EntradaLateral> createState() => _EntradaLateralState();
}

class _EntradaLateralState extends State<EntradaLateral>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: CheckmeMotion.appear,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curva = CurvedAnimation(
      parent: _controller,
      curve: CheckmeMotion.easeOutCubic,
    );
    return FadeTransition(
      opacity: curva,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.08, 0),
          end: Offset.zero,
        ).animate(curva),
        child: widget.child,
      ),
    );
  }
}
