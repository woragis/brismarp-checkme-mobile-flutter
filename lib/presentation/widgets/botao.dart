import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/motion.dart';

enum BotaoVariante { primario, inverso, secundario, perigo, terciario }

class Botao extends StatefulWidget {
  const Botao({
    super.key,
    required this.titulo,
    this.onPressed,
    this.variante = BotaoVariante.primario,
    this.seta = false,
    this.expand = true,
  });

  final String titulo;
  final VoidCallback? onPressed;
  final BotaoVariante variante;
  final bool seta;
  final bool expand;

  @override
  State<Botao> createState() => _BotaoState();
}

class _BotaoState extends State<Botao> {
  bool _down = false;

  Color get _bg => switch (widget.variante) {
        BotaoVariante.primario => CheckmeColors.navy,
        BotaoVariante.inverso => Colors.white,
        BotaoVariante.secundario => Colors.transparent,
        BotaoVariante.perigo => Colors.transparent,
        BotaoVariante.terciario => Colors.transparent,
      };

  Color get _fg => switch (widget.variante) {
        BotaoVariante.primario => Colors.white,
        BotaoVariante.inverso => CheckmeColors.navy,
        BotaoVariante.secundario => CheckmeColors.navy,
        BotaoVariante.perigo => CheckmeColors.alerta,
        BotaoVariante.terciario => CheckmeColors.navy,
      };

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final terciario = widget.variante == BotaoVariante.terciario;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTapCancel: enabled ? () => setState(() => _down = false) : null,
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _down ? 0.97 : 1,
          duration: CheckmeMotion.press,
          curve: CheckmeMotion.easeOut,
          child: AnimatedContainer(
            duration: CheckmeMotion.press,
            width: widget.expand ? double.infinity : null,
            padding: EdgeInsets.symmetric(
              vertical: terciario ? 8 : 14,
              horizontal: terciario ? 4 : 20,
            ),
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(14),
              border: switch (widget.variante) {
                BotaoVariante.secundario =>
                  Border.all(color: CheckmeColors.navy, width: 1.5),
                BotaoVariante.perigo =>
                  Border.all(color: CheckmeColors.alerta, width: 1.5),
                _ => null,
              },
            ),
            child: Row(
              mainAxisSize:
                  widget.expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    widget.titulo,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: _fg,
                    ),
                  ),
                ),
                if (widget.seta) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 16, color: _fg),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
