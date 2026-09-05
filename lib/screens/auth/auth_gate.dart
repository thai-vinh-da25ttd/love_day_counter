import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/couple_model.dart';
import '../../repositories/couple_repository.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/loading_view.dart';
import '../home/home_screen.dart';
import 'login_screen.dart';
import 'pair_setup_screen.dart';

/// Widget gốc quyết định người dùng sẽ thấy màn hình nào mỗi khi mở app:
///  - Chưa đăng nhập            -> LoginScreen
///  - Đã đăng nhập, chưa ghép đôi -> PairSetupScreen
///  - Đã đăng nhập, đã ghép đôi   -> HomeScreen
///
/// Đây là bản thay thế cho việc app.dart hard-code `home: LoginScreen()`.
/// Firebase Auth tự lưu phiên đăng nhập trên máy, nên `authStateChanges()`
/// sẽ tự phát ra user hiện tại ngay khi app khởi động lại — không cần người
/// dùng bấm "Đăng nhập bằng Google" lại từ đầu mỗi lần mở app.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: LoadingView());
        }

        final user = snapshot.data;
        if (user == null) {
          return const LoginScreen();
        }

        return _CoupleResolver(user: user);
      },
    );
  }
}

/// Sau khi biết chắc đã có user, tra tiếp xem user đó đã ghép đôi chưa, rồi
/// điều hướng. Tách riêng thành StatefulWidget để cache Future này (không
/// gọi lại Firestore mỗi lần AuthGate rebuild).
class _CoupleResolver extends StatefulWidget {
  final User user;

  const _CoupleResolver({required this.user});

  @override
  State<_CoupleResolver> createState() => _CoupleResolverState();
}

class _CoupleResolverState extends State<_CoupleResolver> {
  late Future<CoupleModel?> _future;

  @override
  void initState() {
    super.initState();
    _future = _resolve();
  }

  @override
  void didUpdateWidget(covariant _CoupleResolver oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Người dùng đăng xuất rồi đăng nhập tài khoản khác trong cùng phiên app
    // -> phải tra lại từ đầu cho user mới.
    if (oldWidget.user.uid != widget.user.uid) {
      setState(() => _future = _resolve());
    }
  }

  Future<CoupleModel?> _resolve() async {
    // Đăng ký nhận thông báo cho MỌI phiên đăng nhập hợp lệ (kể cả phiên
    // được khôi phục tự động từ lần mở app trước), không chỉ lúc vừa bấm
    // "Đăng nhập bằng Google". Trước đây initialize() chỉ được gọi trong
    // login_screen.dart nên có thể góp phần khiến token FCM không được lưu
    // lại cho những phiên đăng nhập cũ.
    try {
      await NotificationService.instance.initialize(widget.user.uid);
    } catch (e) {
      debugPrint('NotificationService.initialize lỗi: $e');
    }

    final couple =
        await CoupleRepository.instance.getCurrentCouple(widget.user.uid);

    final prefs = await SharedPreferences.getInstance();
    if (couple != null) {
      await prefs.setString('current_couple_id', couple.id);
    } else {
      await prefs.remove('current_couple_id');
    }

    return couple;
  }

  void _refresh() {
    setState(() => _future = _resolve());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CoupleModel?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: LoadingView());
        }

        if (snapshot.hasError) {
          return _AuthGateError(
            message: 'Không tải được dữ liệu tài khoản.\n${snapshot.error}',
            onRetry: _refresh,
          );
        }

        final couple = snapshot.data;
        if (couple == null) {
          // onPaired: sau khi tạo/tham gia cặp đôi thành công, yêu cầu
          // AuthGate tra lại thay vì tự Navigator.push sang HomeScreen —
          // giữ đúng nguyên tắc "1 nơi duy nhất quyết định điều hướng".
          return PairSetupScreen(onPaired: _refresh);
        }

        return HomeScreen(coupleId: couple.id);
      },
    );
  }
}

class _AuthGateError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _AuthGateError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
            ],
          ),
        ),
      ),
    );
  }
}
