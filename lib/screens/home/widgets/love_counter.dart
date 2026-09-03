import 'package:flutter/material.dart';

class LoveCounter extends StatelessWidget {
  final DateTime startDate;

  const LoveCounter({
    super.key,
    required this.startDate,
  });

  @override
  Widget build(BuildContext context) {
    final days = DateTime.now().difference(startDate).inDays + 1;

    return Column(
      children: [
        const Text(
          'CHÚNG TA ĐÃ BÊN NHAU',
          style: TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$days',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 72,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Text(
          'NGÀY',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
          ),
        ),
      ],
    );
  }
}
