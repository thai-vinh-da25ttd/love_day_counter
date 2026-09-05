import 'dart:typed_data';

import 'package:home_widget/home_widget.dart';
import 'package:http/http.dart' as http;

class WidgetService {
  WidgetService._();
  static final WidgetService instance = WidgetService._();

  Future<void> update({
    required int loveDays,
    required String couplePhotoUrl,
  }) async {
    await HomeWidget.saveWidgetData<int>('love_days', loveDays);

    if (couplePhotoUrl.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(couplePhotoUrl));
        if (response.statusCode >= 200 && response.statusCode < 300) {
          final path = await HomeWidget.saveFile(
            'couple_photo',
            Uint8List.fromList(response.bodyBytes),
          );
          await HomeWidget.saveWidgetData<String>('couple_photo_path', path);
        }
      } catch (_) {
        // Widget still works with the love-day counter when the photo fails.
      }
    }

    await HomeWidget.updateWidget(androidName: 'LoveDayWidgetProvider');
  }
}
