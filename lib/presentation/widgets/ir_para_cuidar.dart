import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/colors.dart';
import 'botao.dart';
import 'cartao.dart';

class IrParaCuidar extends StatelessWidget {
  const IrParaCuidar({super.key, required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Cartao(
      animate: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CheckmeColors.azulNeve,
              borderRadius: BorderRadius.circular(14),
              border: const Border(
                left: BorderSide(color: CheckmeColors.navy, width: 4),
              ),
            ),
            child: Text(
              texto,
              style: const TextStyle(
                color: CheckmeColors.texto,
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F6EE),
              borderRadius: BorderRadius.circular(14),
              border: const Border(
                left: BorderSide(color: CheckmeColors.sucesso, width: 4),
              ),
            ),
            child: const Text(
              'O login fica em Cuidar.',
              style: TextStyle(
                color: CheckmeColors.sucesso,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Botao(
            titulo: 'Ir para Cuidar',
            onPressed: () => context.go('/cuidar'),
          ),
        ],
      ),
    );
  }
}
