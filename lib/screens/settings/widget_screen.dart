import 'package:flutter/material.dart';

import '../../models/couple_model.dart';
import '../../services/widget_service.dart';

class WidgetScreen extends StatelessWidget {
  final CoupleModel couple;

  const WidgetScreen({
    super.key,
    required this.couple,
  });

  @override
  Widget build(BuildContext context) {
    final days = DateTime.now().difference(couple.startDate).inDays + 1;
    final photo = couple.person1.avatarUrl.isNotEmpty
        ? couple.person1.avatarUrl
        : couple.person2.avatarUrl;

    return Scaffold(
      appBar: AppBar(title: const Text('Widget')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Widget Android',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sau khi thêm AppWidget native vào android/, bấm nút dưới để cập nhật dữ liệu.',
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () async {
                await WidgetService.instance.update(
                  loveDays: days,
                  couplePhotoUrl: photo,
                );

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã cập nhật dữ liệu widget.'),
                  ),
                );
              },
              icon: const Icon(Icons.sync),
              label: Text('Cập nhật $days ngày'),
            ),
          ],
        ),
      ),
    );
  }
}
