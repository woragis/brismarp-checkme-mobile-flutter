import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final asset = switch (layout) {
      LogoLayout.icone =>
        inverted ? 'assets/brand/logo-white.svg' : 'assets/brand/logo.svg',
      LogoLayout.checkme => inverted
          ? 'assets/brand/logo-checkme-white.svg'
          : 'assets/brand/logo-checkme.svg',
    };
    final ratio = layout == LogoLayout.icone ? 1.0 : 252 / 64;
    return SvgPicture.asset(
      asset,
      height: size,
      width: layout == LogoLayout.icone ? size : size * ratio,
      semanticsLabel: 'CheckMe',
      fit: BoxFit.contain,
      alignment: Alignment.centerLeft,
    );
  }
}
