import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/colors.dart';
import '../../widgets/cascata.dart';

class TelaInterna extends StatelessWidget {
  const TelaInterna({super.key, required this.titulo, required this.child});

  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return EntradaLateral(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/conta');
                    }
                  },
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                  color: CheckmeColors.navy,
                ),
                Text(titulo, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
