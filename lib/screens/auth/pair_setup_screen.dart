import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../repositories/couple_repository.dart';
import '../home/home_screen.dart';

class PairSetupScreen extends StatefulWidget {
  const PairSetupScreen({super.key});

  @override
  State<PairSetupScreen> createState() => _PairSetupScreenState();
}

class _PairSetupScreenState extends State<PairSetupScreen> {
  final _nicknameController = TextEditingController();
  final _codeController = TextEditingController();
  DateTime _startDate = DateTime.now();
  bool _loading = false;

  User get _user => FirebaseAuth.instance.currentUser!;

  @override
  void dispose() {
    _nicknameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_nicknameController.text.trim().isEmpty) return;

    setState(() => _loading = true);
    try {
      final coupleId = await CoupleRepository.instance.create(
        user: _user,
        nickname: _nicknameController.text.trim(),
        startDate: _startDate,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomeScreen(coupleId: coupleId),
        ),
      );
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _join() async {
    final code = _codeController.text.trim().toUpperCase();

    if (code.length != 6 || _nicknameController.text.trim().isEmpty) {
      _showError('Nhập nickname và mã ghép đôi 6 ký tự.');
      return;
    }

    setState(() => _loading = true);
    try {
      final coupleId = await CoupleRepository.instance.join(
        user: _user,
        pairCode: code,
        nickname: _nicknameController.text.trim(),
      );

      if (coupleId == null) {
        _showError('Không tìm thấy mã ghép đôi.');
        return;
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomeScreen(coupleId: coupleId),
        ),
      );
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDate: _startDate,
    );
    if (selected != null) {
      setState(() => _startDate = selected);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ghép đôi')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Tên của m',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nicknameController,
            decoration: const InputDecoration(
              hintText: 'Ví dụ: Yui',
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Ngày bắt đầu yêu'),
            subtitle: Text(
              '${_startDate.day}/${_startDate.month}/${_startDate.year}',
            ),
            trailing: IconButton(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_month),
            ),
          ),
          const Divider(height: 32),
          FilledButton(
            onPressed: _loading ? null : _create,
            child: _loading
                ? const CircularProgressIndicator()
                : const Text('Tạo cặp đôi mới'),
          ),
          const SizedBox(height: 24),
          const Center(child: Text('HOẶC')),
          const SizedBox(height: 24),
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Mã ghép đôi',
              hintText: 'ABC123',
              prefixIcon: Icon(Icons.key),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _loading ? null : _join,
            child: const Text('Tham gia cặp đôi'),
          ),
        ],
      ),
    );
  }
}
