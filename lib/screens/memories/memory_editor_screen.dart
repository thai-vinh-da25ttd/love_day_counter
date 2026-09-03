import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../repositories/memory_repository.dart';
import '../../services/storage_service.dart';

class MemoryEditorScreen extends StatefulWidget {
  final String coupleId;

  const MemoryEditorScreen({
    super.key,
    required this.coupleId,
  });

  @override
  State<MemoryEditorScreen> createState() => _MemoryEditorScreenState();
}

class _MemoryEditorScreenState extends State<MemoryEditorScreen> {
  final _title = TextEditingController();
  final _note = TextEditingController();
  final _uuid = const Uuid();

  DateTime _date = DateTime.now();
  File? _image;
  bool _loading = false;

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) return;

    setState(() => _loading = true);

    try {
      final memoryId = _uuid.v4();
      var imageUrl = '';

      if (_image != null) {
        imageUrl = await StorageService.instance.uploadMemory(
          coupleId: widget.coupleId,
          memoryId: memoryId,
          file: _image!,
        );
      }

      await MemoryRepository.instance.add(
        coupleId: widget.coupleId,
        title: _title.text.trim(),
        note: _note.text.trim(),
        date: _date,
        imageUrl: imageUrl,
        createdBy: FirebaseAuth.instance.currentUser!.uid,
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lưu kỷ niệm thất bại: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDate: _date,
    );

    if (selected != null) {
      setState(() => _date = selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm kỷ niệm')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _title,
            decoration: const InputDecoration(
              labelText: 'Tiêu đề',
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _note,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Ghi chú',
            ),
          ),
          const SizedBox(height: 14),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Ngày'),
            subtitle: Text(
              '${_date.day}/${_date.month}/${_date.year}',
            ),
            trailing: IconButton(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_month),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.image_outlined),
            label: const Text('Chọn ảnh'),
          ),
          if (_image != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                _image!,
                height: 220,
                fit: BoxFit.cover,
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const CircularProgressIndicator()
                : const Text('Lưu kỷ niệm'),
          ),
        ],
      ),
    );
  }
}
