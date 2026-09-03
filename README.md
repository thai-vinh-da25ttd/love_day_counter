# love_day_counter

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Phần backend + Android đã bổ sung

Project hiện có thêm:
- PIN + sinh trắc học + khóa app khi đưa app xuống nền.
- Khôi phục PIN bằng Google re-authentication.
- FCM + local notification foreground cho "Gửi yêu thương".
- Firebase Cloud Function gửi notification tới FCM token của người yêu.
- Firestore Rules + Storage Rules.
- Android Home Widget hiển thị số ngày yêu và ảnh cặp đôi.
- Pair code lookup qua `pair_codes/{code}` để không cần mở quyền query toàn bộ `couples`.

### Firebase deploy

```bash
firebase login
firebase use love-day-counter-d127
cd functions
npm install
cd ..
firebase deploy --only firestore:rules,storage,functions
```

### Android

```bash
flutter pub get
flutter run
```

Sau khi đăng nhập và ghép đôi, vào **Cài đặt → Widget** để đồng bộ dữ liệu rồi thêm widget Love Day Counter từ màn hình chính Android.
