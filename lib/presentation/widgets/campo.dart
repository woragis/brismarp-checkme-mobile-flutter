import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/motion.dart';

class Campo extends StatefulWidget {
  const Campo({
    super.key,
    this.controller,
    this.hint,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.minLines = 1,
    this.maxLines = 1,
    this.autofillHints,
  });

  final TextEditingController? controller;
  final String? hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final int minLines;
  final int maxLines;
  final Iterable<String>? autofillHints;

  @override
  State<Campo> createState() => _CampoState();
}

class _CampoState extends State<Campo> {
  bool _foco = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: CheckmeMotion.press,
      curve: CheckmeMotion.easeOut,
      decoration: BoxDecoration(
        color: CheckmeColors.cartao,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _foco ? CheckmeColors.care : CheckmeColors.borda,
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        controller: widget.controller,
        obscureText: widget.obscure,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        onSubmitted: widget.onSubmitted,
        minLines: widget.minLines,
        maxLines: widget.maxLines,
        autofillHints: widget.autofillHints,
        onTapOutside: (_) => FocusScope.of(context).unfocus(),
        style: const TextStyle(color: CheckmeColors.texto, fontSize: 14),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: const TextStyle(color: Color(0xFF8A9BB5)),
          border: InputBorder.none,
        ),
        focusNode: _node,
      ),
    );
  }

  final _node = FocusNode();

  @override
  void initState() {
    super.initState();
    _node.addListener(() => setState(() => _foco = _node.hasFocus));
  }

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }
}
