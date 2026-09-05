import 'package:flutter/material.dart';

import '../screens/auth/auth_gate.dart';
import 'theme.dart';

class LoveDayCounterApp extends StatelessWidget {
  const LoveDayCounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Love Day Counter',
      theme: AppTheme.light,
      // AuthGate tự quyết định Login / Ghép đôi / Home dựa trên
      // FirebaseAuth.authStateChanges() — sửa lỗi phải đăng nhập lại mỗi
      // lần mở app.
      home: const AuthGate(),
    );
  }
}
