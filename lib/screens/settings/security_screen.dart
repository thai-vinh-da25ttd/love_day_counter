import 'package:flutter/material.dart';

import '../../models/couple_model.dart';
import '../../services/biometric_service.dart';
import '../../services/firestore_service.dart';

class SecurityScreen extends StatefulWidget {
  final CoupleModel couple;

  const SecurityScreen({
    super.key,
    required this.couple,
  });

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  late bool _pinEnabled;
  late bool _biometricEnabled;

  @override
  void initState() {
    super.initState();
    _pinEnabled = widget.couple.pinEnabled;
    _biometricEnabled = widget.couple.biometricEnabled;
  }

  Future<void> _setPin() async {
    final controller = TextEditingController();

    final pin = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đặt PIN'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: '4-6 chữ số',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              controller.text.trim(),
            ),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (pin == null || pin.length < 4) return;

    await BiometricService.instance.savePin(pin);
    setState(() => _pinEnabled = true);

    await FirestoreService.instance.updateSecurity(
      coupleId: widget.couple.id,
      pinEnabled: true,
      biometricEnabled: _biometricEnabled,
    );
  }

  Future<void> _togglePin(bool value) async {
    if (value) {
      await _setPin();
      return;
    }

    await BiometricService.instance.clearPin();
    setState(() => _pinEnabled = false);

    await FirestoreService.instance.updateSecurity(
      coupleId: widget.couple.id,
      pinEnabled: false,
      biometricEnabled: _biometricEnabled,
    );
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      final available =
          await BiometricService.instance.canCheckBiometrics();

      if (!available) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thiết bị chưa hỗ trợ sinh trắc học.'),
          ),
        );
        return;
      }
    }

    setState(() => _biometricEnabled = value);

    await FirestoreService.instance.updateSecurity(
      coupleId: widget.couple.id,
      pinEnabled: _pinEnabled,
      biometricEnabled: value,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bảo mật')),
      body: ListView(
        children: [
          SwitchListTile(
            value: _pinEnabled,
            onChanged: _togglePin,
            title: const Text('Khoá bằng PIN'),
            subtitle: const Text('PIN được lưu trong secure storage'),
          ),
          SwitchListTile(
            value: _biometricEnabled,
            onChanged: _toggleBiometric,
            title: const Text('Sinh trắc học'),
            subtitle: const Text('Vân tay / khuôn mặt nếu thiết bị hỗ trợ'),
          ),
        ],
      ),
    );
  }
}
