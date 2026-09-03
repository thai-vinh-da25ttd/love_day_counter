import 'package:flutter/material.dart';

import '../../models/couple_model.dart';
import '../../services/auth_service.dart';
import 'security_screen.dart';
import 'widget_screen.dart';

class SettingsScreen extends StatelessWidget {
  final CoupleModel couple;

  const SettingsScreen({
    super.key,
    required this.couple,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Bảo mật ứng dụng'),
            subtitle: const Text('PIN và sinh trắc học'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SecurityScreen(couple: couple),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.widgets_outlined),
            title: const Text('Widget'),
            subtitle: const Text('Đếm ngày yêu trên màn hình chính'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => WidgetScreen(couple: couple),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Đăng xuất'),
            onTap: () => AuthService.instance.signOut(),
          ),
        ],
      ),
    );
  }
}
