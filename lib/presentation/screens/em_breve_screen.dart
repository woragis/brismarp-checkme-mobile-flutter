import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../widgets/logo.dart';

class EmBreveScreen extends StatelessWidget {
  const EmBreveScreen({
    super.key,
    required this.titulo,
    required this.texto,
  });

  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Logo(size: 28),
            const Spacer(),
            Text(titulo, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            Text(
              texto,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Em breve',
              style: TextStyle(
                color: CheckmeColors.care,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
