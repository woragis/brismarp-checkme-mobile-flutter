import 'package:flutter/material.dart';

import '../../widgets/ir_para_cuidar.dart';
import '../../widgets/logo.dart';
import 'tela_interna.dart';

class PortaScreen extends StatelessWidget {
  const PortaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TelaInterna(
      titulo: 'Conta',
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Logo(size: 28),
            SizedBox(height: 24),
            IrParaCuidar(
              texto: 'Isso aparece depois que você entra. Volte para Cuidar e toque em Já tenho conta.',
            ),
          ],
        ),
      ),
    );
  }
}
