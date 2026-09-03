import 'package:flutter/material.dart';

class LoveButton extends StatelessWidget {
  final VoidCallback onPressed;

  const LoveButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 14,
        ),
      ),
      icon: const Icon(Icons.favorite),
      label: const Text('Gửi yêu thương'),
    );
  }
}
