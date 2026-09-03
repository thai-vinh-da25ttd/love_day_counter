import 'package:flutter/material.dart';

class BackgroundView extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onChangeBackground;

  const BackgroundView({
    super.key,
    required this.imageUrl,
    required this.onChangeBackground,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: onChangeBackground,
      child: imageUrl.isEmpty
          ? Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFF8FAF),
                    Color(0xFFD94F70),
                  ],
                ),
              ),
            )
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFF7E2946),
              ),
            ),
    );
  }
}
