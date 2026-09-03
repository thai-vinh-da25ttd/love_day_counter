import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../repositories/couple_repository.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import 'pair_setup_screen.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _login(BuildContext context) async {
    try {
      final credential = await AuthService.instance.signInWithGoogle();
      final user = credential?.user;

      if (user == null || !context.mounted) return;

      await NotificationService.instance.initialize(user.uid);

      final couple = await CoupleRepository.instance.getCurrentCouple(user.uid);

      if (!context.mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => couple == null
              ? const PairSetupScreen()
              : HomeScreen(coupleId: couple.id),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đăng nhập lỗi: $e')),
      );
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
                  onPressed: () => _login(context),
                  icon: const Icon(Icons.login),
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
