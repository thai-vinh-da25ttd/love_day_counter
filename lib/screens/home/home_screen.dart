import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/app_lock_service.dart';
import '../../services/biometric_service.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/couple_model.dart';
import '../../repositories/couple_repository.dart';
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

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _index = 0;

  // Lưu lại settings mới nhất từ stream của couple để có thể khoá app đồng
  // bộ (không cần gọi lại Firestore) mỗi khi app quay lại từ nền.
  bool _pinEnabled = false;
  bool _biometricEnabled = false;
  bool _initialLockEvaluated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      AppLockService.instance.lockIfEnabled(
        pinEnabled: _pinEnabled,
        biometricEnabled: _biometricEnabled,
      );
      // Nếu app bị đưa xuống nền giữa lúc hộp thoại vân tay đang mở, huỷ nó
      // đi để tránh plugin bị kẹt trạng thái ở lần mở lại sau.
      BiometricService.instance.cancelAuthentication();
    }
  }

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
                      onEditMeNickname: () => _editNickname(couple, _user.uid),
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
        _pinEnabled = couple.pinEnabled;
        _biometricEnabled = couple.biometricEnabled;

        if (!_initialLockEvaluated) {
          _initialLockEvaluated = true;
          // SỬA LỖI: trước đây chỉ khoá app khi app bị đưa xuống nền, nên mở
          // app từ trạng thái tắt hẳn sẽ KHÔNG bị khoá dù đã bật PIN/vân tay.
          // Giờ đánh giá khoá ngay khi có dữ liệu couple đầu tiên. Dùng
          // addPostFrameCallback để không gọi notifyListeners() (bên trong
          // lockIfEnabled) ngay giữa lúc widget này đang build.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            AppLockService.instance.lockIfEnabled(
              pinEnabled: couple.pinEnabled,
              biometricEnabled: couple.biometricEnabled,
            );
          });
        }

        return AnimatedBuilder(
          animation: AppLockService.instance,
          builder: (context, _) => Stack(
            fit: StackFit.expand,
            children: [
              Scaffold(
                extendBody: _index == 0,
                body: _buildContent(couple),
                bottomNavigationBar: AppBottomNav(
                  currentIndex: _index,
                  onChanged: (value) => setState(() => _index = value),
                ),
              ),
              if (AppLockService.instance.locked)
                AppLockOverlay(coupleId: couple.id),
            ],
          ),
        );
      },
    );
  }
}

class AppLockOverlay extends StatefulWidget {
  final String coupleId;

  const AppLockOverlay({super.key, required this.coupleId});

  @override
  State<AppLockOverlay> createState() => _AppLockOverlayState();
}

class _AppLockOverlayState extends State<AppLockOverlay> {
  final _pin = TextEditingController();
  bool _busy = false;
  bool _biometricReady = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  Future<void> _checkBiometric() async {
    // Chỉ hiện nút "Dùng sinh trắc học" khi máy thật sự hỗ trợ VÀ đã đăng ký
    // vân tay/khuôn mặt — trước đây nút này luôn hiện vô điều kiện nên bấm
    // vào là lỗi ngay trên máy chưa cài vân tay, tạo cảm giác "hay bị lỗi".
    final ready = await BiometricService.instance.isBiometricReady();
    if (mounted) setState(() => _biometricReady = ready);
  }

  Future<void> _bio() async {
    setState(() => _busy = true);
    final result = await AppLockService.instance.unlockWithBiometric();
    if (mounted) setState(() => _busy = false);
    final message = _messageFor(result);
    if (message != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  String? _messageFor(BiometricAuthResult result) {
    switch (result) {
      case BiometricAuthResult.success:
        return null;
      case BiometricAuthResult.cancelled:
        return null; // Người dùng tự bấm huỷ, không cần báo lỗi.
      case BiometricAuthResult.notAvailable:
        return 'Thiết bị không hỗ trợ sinh trắc học. Hãy dùng PIN.';
      case BiometricAuthResult.notEnrolled:
        return 'Máy chưa đăng ký vân tay/khuôn mặt. Hãy dùng PIN.';
      case BiometricAuthResult.lockedOut:
        return 'Sai quá nhiều lần, thử lại sau ít phút hoặc dùng PIN.';
      case BiometricAuthResult.permanentlyLockedOut:
        return 'Sinh trắc học đã bị khoá do sai quá nhiều lần. Hãy mở khoá thiết bị bằng vân tay/khuôn mặt trong Cài đặt máy trước, hoặc dùng PIN.';
      case BiometricAuthResult.passcodeNotSet:
        return 'Thiết bị chưa đặt mã khoá màn hình. Hãy dùng PIN.';
      case BiometricAuthResult.error:
        return 'Xác thực sinh trắc học thất bại. Hãy dùng PIN.';
    }
  }

  Future<void> _pinUnlock() async {
    if (_pin.text.length < 4) return;
    setState(() => _busy = true);
    final ok = await AppLockService.instance.unlockWithPin(_pin.text);
    if (mounted) setState(() => _busy = false);
    if (!ok && mounted) {
      _pin.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN không đúng.')),
      );
    }
  }

  Future<void> _forgot() async {
    setState(() => _busy = true);
    try {
      await AppLockService.instance.recoverPinWithGoogle(
        coupleId: widget.coupleId,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Khôi phục PIN thất bại: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(.96),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_rounded, color: Colors.white, size: 64),
                const SizedBox(height: 16),
                const Text('Love Day Counter đang khoá',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  _biometricReady
                      ? 'Nhập PIN hoặc dùng vân tay / khuôn mặt.'
                      : 'Nhập PIN để mở khoá.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _pin,
                  enabled: !_busy,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 28, letterSpacing: 8),
                  decoration: const InputDecoration(
                      hintText: '••••',
                      hintStyle: TextStyle(color: Colors.white38),
                      counterText: '',
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white38))),
                  onSubmitted: (_) => _pinUnlock(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                        onPressed: _busy ? null : _pinUnlock,
                        child: const Text('Mở khoá'))),
                if (_biometricReady) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                      onPressed: _busy ? null : _bio,
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('Dùng sinh trắc học')),
                ],
                TextButton(
                    onPressed: _busy ? null : _forgot,
                    child:
                        const Text('Quên PIN? Đăng nhập Google để khôi phục')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
