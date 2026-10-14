import 'package:flutter/material.dart';

import '../theme/colors.dart';

enum LogoLayout { icone, checkme }

class Logo extends StatelessWidget {
  const Logo({
    super.key,
    this.size = 36,
    this.layout = LogoLayout.checkme,
    this.inverted = false,
  });

  final double size;
  final LogoLayout layout;

  /// Use the white variant on dark backgrounds, including brand purple.
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final format = layout == LogoLayout.icone ? 'short' : 'extended';
    final background = inverted ? 'dark' : 'light';
    return Image.asset(
      'assets/brand/checkme-$format-logo-$background-bg.png',
      height: size,
      width: layout == LogoLayout.icone ? size : size * 4.8,
      semanticLabel: 'CheckMe',
      fit: BoxFit.contain,
      alignment: Alignment.centerLeft,
      filterQuality: FilterQuality.high,
    );
  }
}

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: CheckmeColors.roxoEscuro,
        borderRadius: BorderRadius.circular(CheckmeRadius.lg),
      ),
      child: const Row(
        children: [
          Expanded(child: Logo(size: 40, inverted: true)),
          SizedBox(width: 12),
          ExcludeSemantics(
            child: Icon(Icons.favorite_outline, color: CheckmeColors.ciano),
          ),
        ],
      ),
    );
  }
}
