import 'package:flutter/material.dart';

import '../screens/auth/login_screen.dart';
import 'theme.dart';

class LoveDayCounterApp extends StatelessWidget {
  const LoveDayCounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Love Day Counter',
      theme: AppTheme.light,
      home: const LoginScreen(),
    );
  }
}
