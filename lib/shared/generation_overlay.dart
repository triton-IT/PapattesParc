import 'package:flutter/material.dart';
import 'generation_service.dart';
import 'game_stage_layout.dart';

class GenerationBoundary extends StatelessWidget {
  const GenerationBoundary({
    required this.service,
    required this.child,
    this.onCancel,
    super.key,
  });
  final GenerationService service;
  final Widget child;
  final VoidCallback? onCancel;
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: service,
    child: child,
    builder: (context, busy, child) => Stack(
      children: [
        ExcludeFocus(excluding: busy, child: child!),
        if (busy)
          Positioned.fill(
            child: GenerationOverlay(
              onCancel: () {
                service.cancel();
                onCancel?.call();
              },
            ),
          ),
      ],
    ),
  );
}

class GenerationOverlay extends StatelessWidget {
  const GenerationOverlay({required this.onCancel, super.key});
  final VoidCallback onCancel;
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xcc245b4a),
    child: GameResultViewport(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Préparation du niveau…'),
              TextButton(onPressed: onCancel, child: const Text('Annuler')),
            ],
          ),
        ),
      ),
    ),
  );
}
