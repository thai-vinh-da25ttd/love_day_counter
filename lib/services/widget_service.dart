import 'package:home_widget/home_widget.dart';

class WidgetService {
  WidgetService._();
  static final WidgetService instance = WidgetService._();

  Future<void> update({
    required int loveDays,
    required String couplePhotoUrl,
  }) async {
    await HomeWidget.saveWidgetData<int>('love_days', loveDays);
    await HomeWidget.saveWidgetData<String>(
      'couple_photo_url',
      couplePhotoUrl,
    );

    await HomeWidget.updateWidget(
      androidName: 'LoveDayWidgetProvider',
    );
  }
}
