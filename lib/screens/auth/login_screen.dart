import 'package:flutter/material.dart';

import '../../services/auth_service.dart';

/// Chỉ còn nhiệm vụ duy nhất: gọi đăng nhập Google.
///
/// Trước đây màn hình này tự lo luôn việc lấy couple, lưu SharedPreferences
/// và Navigator.push sang PairSetupScreen/HomeScreen — bị trùng lặp logic
/// với AuthGate. Giờ chỉ cần đăng nhập xong, AuthGate (đang lắng nghe
/// authStateChanges() ở phía trên) sẽ tự động rebuild và điều hướng đúng
/// màn hình, nên ở đây không cần Navigator gì cả.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      await AuthService.instance.signInWithGoogle();
      // Không Navigator.push ở đây — AuthGate sẽ tự chuyển màn hình.
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đăng nhập lỗi: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.favorite_rounded,
                  size: 88,
                  color: Color(0xFFE75480),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Love Day Counter',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ứng dụng riêng cho hai đứa mình ❤️',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                FilledButton.icon(
                  onPressed: _loading ? null : _login,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.login),
                  label: const Text('Đăng nhập bằng Google'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
