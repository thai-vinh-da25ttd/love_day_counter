import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final GoogleSignIn googleSignIn = GoogleSignIn();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const LoveCounterApp());
}

class LoveCounterApp extends StatelessWidget {
  const LoveCounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chúng ta đã bên nhau',
      debugShowCheckedModeBanner: false,
      locale: const Locale('vi', 'VN'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('vi', 'VN'),
        Locale('en', 'US'),
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFE75480),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  GoogleSignInAccount? _user;
  bool _checkingAuth = true;

  @override
  void initState() {
    super.initState();
    googleSignIn.onCurrentUserChanged.listen((account) {
      if (mounted) {
        setState(() {
          _user = account;
          _checkingAuth = false;
        });
      }
    });

    googleSignIn.signInSilently().then((account) {
      if (mounted) {
        setState(() {
          _user = account;
          _checkingAuth = false;
        });
      }
    }).catchError((_) {
      if (mounted) setState(() => _checkingAuth = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingAuth) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_user == null) {
      return const LoginScreen();
    } else {
      return PairCheckWrapper(user: _user!);
    }
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoggingIn = false;

  Future<void> _handleSignIn() async {
    setState(() => _isLoggingIn = true);
    try {
      await googleSignIn.signIn();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đăng nhập thất bại: $error')),
      );
    } finally {
      if (mounted) setState(() => _isLoggingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF0F3), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.favorite, size: 80, color: Color(0xFFE75480)),
              const SizedBox(height: 24),
              const Text(
                'Love Day Counter',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFB03052),
                ),
              ),
              const SizedBox(height: 8),
              const Text('Đăng nhập để kết nối cặp đôi',
                  style: TextStyle(fontSize: 15, color: Colors.black54)),
              const SizedBox(height: 48),
              _isLoggingIn
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      icon: Image.network(
                        'https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg',
                        height: 22,
                        width: 22,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.account_circle),
                      ),
                      label: const Text('Đăng nhập bằng Google',
                          style: TextStyle(fontSize: 16)),
                      onPressed: _handleSignIn,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// Kiểm tra xem tài khoản đã có Mã ghép đôi chưa
class PairCheckWrapper extends StatefulWidget {
  final GoogleSignInAccount user;
  const PairCheckWrapper({super.key, required this.user});

  @override
  State<PairCheckWrapper> createState() => _PairCheckWrapperState();
}

class _PairCheckWrapperState extends State<PairCheckWrapper> {
  String? _pairCode;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkPairStatus();
  }

  Future<void> _checkPairStatus() async {
    try {
      // 1. Kiểm tra trên Firestore trước (ưu tiên dữ liệu Đám mây theo Email Google)
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.email)
          .get();

      if (userDoc.exists && userDoc.data()!.containsKey('pair_code')) {
        String cloudCode = userDoc.data()!['pair_code'];

        // Cập nhật lại bộ nhớ máy
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('pair_code', cloudCode);

        if (mounted) {
          setState(() {
            _pairCode = cloudCode;
            _loading = false;
          });
        }
        return;
      }

      // 2. Nếu Firestore chưa có, kiểm tra bộ nhớ máy (SharedPreferences)
      final prefs = await SharedPreferences.getInstance();
      String? localCode = prefs.getString('pair_code');

      if (mounted) {
        setState(() {
          _pairCode = localCode;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_pairCode == null) {
      return PairSetupScreen(
        user: widget.user,
        onPairSuccess: (code) {
          setState(() => _pairCode = code);
        },
      );
    }
    return HomeScreen(user: widget.user, pairCode: _pairCode!);
  }
}

// Màn hình Tạo hoặc Nhập mã kết nối cặp đôi
class PairSetupScreen extends StatefulWidget {
  final GoogleSignInAccount user;
  final Function(String) onPairSuccess;

  const PairSetupScreen(
      {super.key, required this.user, required this.onPairSuccess});

  @override
  State<PairSetupScreen> createState() => _PairSetupScreenState();
}

class _PairSetupScreenState extends State<PairSetupScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isProcessing = false;

  String _generateRandomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random();
    return String.fromCharCodes(Iterable.generate(
        6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  // Tạo phòng đếm ngày mới
  Future<void> _createPair() async {
    setState(() => _isProcessing = true);
    String code = _generateRandomCode();

    final roomRef = FirebaseFirestore.instance.collection('rooms').doc(code);
    await roomRef.set({
      'pair_code': code,
      'start_date': DateTime(2024, 2, 17).millisecondsSinceEpoch,
      'bg_color_index': 0,
      'user1_email': widget.user.email,
      'user1_name': widget.user.displayName ?? 'Anh',
      'user1_photo': widget.user.photoUrl ?? '',
      'user2_email': '',
      'user2_name': 'Em',
      'user2_photo': '',
    });

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.email)
        .set({'pair_code': code, 'role': 1});

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pair_code', code);

    setState(() => _isProcessing = false);
    widget.onPairSuccess(code);
  }

  // Nhập mã để tham gia vào phòng có sẵn
  Future<void> _joinPair() async {
    String code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() => _isProcessing = true);
    final roomRef = FirebaseFirestore.instance.collection('rooms').doc(code);
    final doc = await roomRef.get();

    if (!doc.exists) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mã kết nối không hợp lệ!')),
      );
      setState(() => _isProcessing = false);
      return;
    }

    await roomRef.update({
      'user2_email': widget.user.email,
      'user2_name': widget.user.displayName ?? 'Em',
      'user2_photo': widget.user.photoUrl ?? '',
    });

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.email)
        .set({'pair_code': code, 'role': 2});

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pair_code', code);

    setState(() => _isProcessing = false);
    widget.onPairSuccess(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết nối cặp đôi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => googleSignIn.disconnect(),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: _isProcessing ? null : _createPair,
              child: const Text('Tạo mã ghép đôi mới'),
            ),
            const SizedBox(height: 32),
            const Text('Hoặc nhập mã ghép đôi từ đối phương:'),
            const SizedBox(height: 12),
            TextField(
              controller: _codeController,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Nhập mã 6 ký tự',
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: _isProcessing ? null : _joinPair,
              child: const Text('Xác nhận ghép đôi'),
            ),
          ],
        ),
      ),
    );
  }
}

// Màn hình đếm ngày - Tự động đồng bộ thời gian thực
class HomeScreen extends StatefulWidget {
  final GoogleSignInAccount user;
  final String pairCode;

  const HomeScreen({super.key, required this.user, required this.pairCode});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();

  final List<List<Color>> _backgrounds = [
    [const Color(0xFFFFF0F3), Colors.white],
    [const Color(0xFFFFE1E6), const Color(0xFFFFF6F8)],
    [const Color(0xFFFFD6D6), Colors.white],
    [const Color(0xFFE8D9FF), const Color(0xFFFFF6F8)],
    [const Color(0xFFD9E8FF), Colors.white],
  ];

  DocumentReference get _roomRef =>
      FirebaseFirestore.instance.collection('rooms').doc(widget.pairCode);

  Future<void> _updateData(Map<String, dynamic> data) async {
    await _roomRef.update(data);
  }

  Future<void> _pickStartDate(DateTime current) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      helpText: 'Chọn ngày bắt đầu yêu',
    );
    if (picked != null) {
      await _updateData({'start_date': picked.millisecondsSinceEpoch});
    }
  }

  Future<void> _editName(int userRole, String currentName) async {
    final controller = TextEditingController(text: currentName);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Đổi tên người thứ $userRole'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nhập tên mới...'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy')),
          FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Lưu')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await _updateData({'user${userRole}_name': result});
    }
  }

  Map<String, int> _calculateDuration(DateTime start, DateTime end) {
    int years = end.year - start.year;
    int months = end.month - start.month;
    int days = end.day - start.day;

    if (days < 0) {
      months -= 1;
      final prevMonthLastDay = DateTime(end.year, end.month, 0).day;
      days += prevMonthLastDay;
    }
    if (months < 0) {
      years -= 1;
      months += 12;
    }
    return {'years': years, 'months': months, 'days': days};
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _roomRef.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        var data = snapshot.data!.data() as Map<String, dynamic>;

        DateTime startDate =
            DateTime.fromMillisecondsSinceEpoch(data['start_date']);
        String name1 = data['user1_name'] ?? 'Anh';
        String name2 = data['user2_name'] ?? 'Em';
        String photo1 = data['user1_photo'] ?? '';
        String photo2 = data['user2_photo'] ?? '';
        int bgColorIndex = data['bg_color_index'] ?? 0;

        final now = DateTime.now();
        final startOnly =
            DateTime(startDate.year, startDate.month, startDate.day);
        final nowOnly = DateTime(now.year, now.month, now.day);

        final totalDays = nowOnly.difference(startOnly).inDays;
        final duration = _calculateDuration(startOnly, nowOnly);
        final bgColors = _backgrounds[bgColorIndex];

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text('Mã cặp đôi: ${widget.pairCode}',
                style: const TextStyle(fontSize: 14, color: Colors.black54)),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.black54),
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('pair_code');
                  await googleSignIn.disconnect();
                },
              ),
            ],
          ),
          extendBodyBehindAppBar: true,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: bgColors,
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    const Text(
                      'Chúng ta đã bên nhau',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB03052),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildAvatar(photo1, () {}),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Icon(Icons.favorite,
                              color: Color(0xFFE75480), size: 32),
                        ),
                        _buildAvatar(photo2, () {}),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildNameChip(name1, () => _editName(1, name1)),
                        const SizedBox(width: 8),
                        const Text('&',
                            style: TextStyle(color: Colors.black54)),
                        const SizedBox(width: 8),
                        _buildNameChip(name2, () => _editName(2, name2)),
                      ],
                    ),
                    const SizedBox(height: 40),
                    Text(
                      '$totalDays',
                      style: const TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE75480),
                      ),
                    ),
                    const Text('ngày yêu nhau',
                        style: TextStyle(fontSize: 18, color: Colors.black54)),
                    const SizedBox(height: 8),
                    Text(
                      '${duration['years']} năm ${duration['months']} tháng ${duration['days']} ngày',
                      style:
                          const TextStyle(fontSize: 14, color: Colors.black45),
                    ),
                    const SizedBox(height: 32),
                    GestureDetector(
                      onTap: () => _pickStartDate(startDate),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 16, color: Color(0xFFE75480)),
                            const SizedBox(width: 8),
                            Text(
                              'Bắt đầu: ${DateFormat('dd/MM/yyyy').format(startDate)}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text('Nền',
                        style: TextStyle(fontSize: 13, color: Colors.black45)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_backgrounds.length, (index) {
                        final colors = _backgrounds[index];
                        final selected = index == bgColorIndex;
                        return GestureDetector(
                          onTap: () => _updateData({'bg_color_index': index}),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(colors: colors),
                              border: Border.all(
                                color: selected
                                    ? const Color(0xFFE75480)
                                    : Colors.white,
                                width: selected ? 3 : 1,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatar(String url, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 48,
        backgroundColor: Colors.white,
        backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
        child: url.isEmpty
            ? const Icon(Icons.person, color: Color(0xFFE75480), size: 36)
            : null,
      ),
    );
  }

  Widget _buildNameChip(String name, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(name,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
