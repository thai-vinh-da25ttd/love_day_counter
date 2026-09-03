import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/couple_model.dart';
import '../../repositories/couple_repository.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../services/widget_service.dart';
import '../../widgets/bottom_nav.dart';
import '../bucket/bucket_screen.dart';
import '../canvas/canvas_screen.dart';
import '../memories/memories_screen.dart';
import '../settings/settings_screen.dart';

import 'widgets/background_view.dart';
import 'widgets/couple_profile.dart';
import 'widgets/love_counter.dart';
import 'widgets/love_button.dart';

class HomeScreen extends StatefulWidget {
  final String coupleId;

  const HomeScreen({
    super.key,
    required this.coupleId,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  User get _user => FirebaseAuth.instance.currentUser!;

  Future<void> _editNickname(CoupleModel couple, String uid) async {
    final member = couple.memberFor(uid);
    final controller = TextEditingController(text: member?.nickname ?? '');

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đổi nickname'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nickname mới',
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

    if (result == null || result.isEmpty) return;

    await FirestoreService.instance.updateMember(
      coupleId: couple.id,
      uid: uid,
      nickname: result,
    );
  }

  Future<void> _editAvatar(CoupleModel couple, String uid) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (picked == null) return;

    final url = await StorageService.instance.uploadAvatar(
      coupleId: couple.id,
      uid: uid,
      file: File(picked.path),
    );

    await FirestoreService.instance.updateMember(
      coupleId: couple.id,
      uid: uid,
      avatarUrl: url,
    );
  }

  Future<void> _editBackground(CoupleModel couple) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked == null) return;

    final url = await StorageService.instance.uploadBackground(
      coupleId: couple.id,
      file: File(picked.path),
    );

    await FirestoreService.instance.updateBackground(
      coupleId: couple.id,
      url: url,
    );
  }

  Future<void> _sendLove(CoupleModel couple) async {
    final partner = couple.partnerFor(_user.uid);

    if (partner == null || partner.uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có người yêu được ghép đôi.')),
      );
      return;
    }

    await FirestoreService.instance.sendLove(
      coupleId: couple.id,
      fromUid: _user.uid,
      toUid: partner.uid,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã gửi yêu thương ❤️')),
    );
  }

  Future<void> _syncWidget(CoupleModel couple) async {
    final days = DateTime.now().difference(couple.startDate).inDays + 1;
    final photo = couple.person1.avatarUrl.isNotEmpty
        ? couple.person1.avatarUrl
        : couple.person2.avatarUrl;

    await WidgetService.instance.update(
      loveDays: days,
      couplePhotoUrl: photo,
    );
  }

  Widget _buildContent(CoupleModel couple) {
    switch (_index) {
      case 1:
        return CanvasScreen(coupleId: couple.id);
      case 2:
        return MemoriesScreen(coupleId: couple.id);
      case 3:
        return BucketScreen(coupleId: couple.id);
      case 4:
        return SettingsScreen(couple: couple);
      default:
        return Stack(
          fit: StackFit.expand,
          children: [
            BackgroundView(
              imageUrl: couple.backgroundUrl,
              onChangeBackground: () => _editBackground(couple),
            ),
            Container(color: Colors.black.withOpacity(0.28)),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 36, 20, 120),
                child: Column(
                  children: [
                    LoveCounter(startDate: couple.startDate),
                    const SizedBox(height: 28),
                    CoupleProfile(
                      me: couple.memberFor(_user.uid),
                      partner: couple.partnerFor(_user.uid),
                      onEditMeAvatar: () => _editAvatar(couple, _user.uid),
                      onEditMeNickname: () =>
                          _editNickname(couple, _user.uid),
                    ),
                    const SizedBox(height: 24),
                    LoveButton(
                      onPressed: () => _sendLove(couple),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Mã ghép đôi: ${couple.pairCode}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () => _syncWidget(couple),
                      icon: const Icon(Icons.widgets_outlined),
                      label: const Text(
                        'Cập nhật widget',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: CoupleRepository.instance.stream(widget.coupleId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text('Không tìm thấy dữ liệu cặp đôi.')),
          );
        }

        final couple = CoupleModel.fromFirestore(snapshot.data!);

        return Scaffold(
          extendBody: _index == 0,
          body: _buildContent(couple),
          bottomNavigationBar: AppBottomNav(
            currentIndex: _index,
            onChanged: (value) => setState(() => _index = value),
          ),
        );
      },
    );
  }
}
