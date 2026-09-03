import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:google_sign_in/google_sign_in.dart';

final GoogleSignIn googleSignIn = GoogleSignIn();

void main() {
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

// ================= MÀN HÌNH KIỂM TRA TRẠNG THÁI ĐĂNG NHẬP =================
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
    // Lắng nghe sự kiện đăng nhập / đăng xuất
    googleSignIn.onCurrentUserChanged.listen((account) {
      if (mounted) {
        setState(() {
          _user = account;
          _checkingAuth = false;
        });
      }
    });

    // Tự động kiểm tra xem đã từng đăng nhập trước đó chưa
    googleSignIn.signInSilently().then((account) {
      if (mounted) {
        setState(() {
          _user = account;
          _checkingAuth = false;
        });
      }
    }).catchError((_) {
      if (mounted) {
        setState(() => _checkingAuth = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingAuth) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Nếu chưa đăng nhập -> Hiện màn hình Login
    // Nếu đã đăng nhập -> Vào thẳng màn hình Home
    if (_user == null) {
      return const LoginScreen();
    } else {
      return HomeScreen(user: _user!);
    }
  }
}

// ================= MÀN HÌNH ĐĂNG NHẬP (LOGIN SCREEN) =================
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
              const Icon(
                Icons.favorite,
                size: 80,
                color: Color(0xFFE75480),
              ),
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
              const Text(
                'Đăng nhập để xem số ngày bên nhau',
                style: TextStyle(fontSize: 15, color: Colors.black54),
              ),
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
                      label: const Text(
                        'Đăng nhập bằng Google',
                        style: TextStyle(fontSize: 16),
                      ),
                      onPressed: _handleSignIn,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================= MÀN HÌNH CHÍNH (HOME SCREEN) =================
class HomeScreen extends StatefulWidget {
  final GoogleSignInAccount user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _startDate = DateTime(2024, 2, 17);
  String _name1 = 'Anh';
  String _name2 = 'Em';
  String? _imagePath1;
  String? _imagePath2;
  int _bgColorIndex = 0;
  bool _isLoading = true;

  final ImagePicker _picker = ImagePicker();

  final List<List<Color>> _backgrounds = [
    [const Color(0xFFFFF0F3), Colors.white],
    [const Color(0xFFFFE1E6), const Color(0xFFFFF6F8)],
    [const Color(0xFFFFD6D6), Colors.white],
    [const Color(0xFFE8D9FF), const Color(0xFFFFF6F8)],
    [const Color(0xFFD9E8FF), Colors.white],
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    // Ưu tiên lấy tên và avatar từ tài khoản Google đã đăng nhập
    String savedName1 =
        prefs.getString('name1') ?? widget.user.displayName ?? 'Anh';
    String? savedImage1 =
        prefs.getString('image1_path') ?? widget.user.photoUrl;

    setState(() {
      final savedMillis = prefs.getInt('start_date');
      _startDate = savedMillis != null
          ? DateTime.fromMillisecondsSinceEpoch(savedMillis)
          : DateTime(2024, 2, 17);
      _name1 = savedName1;
      _name2 = prefs.getString('name2') ?? 'Em';
      _imagePath1 = savedImage1;
      _imagePath2 = prefs.getString('image2_path');
      _bgColorIndex = prefs.getInt('bg_color_index') ?? 0;
      _isLoading = false;
    });
  }

  Future<void> _saveStartDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('start_date', date.millisecondsSinceEpoch);
  }

  Future<void> _saveNames() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name1', _name1);
    await prefs.setString('name2', _name2);
  }

  Future<void> _saveImagePath(int person, String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(person == 1 ? 'image1_path' : 'image2_path', path);
  }

  Future<void> _saveBgIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('bg_color_index', index);
  }

  Future<void> _handleSignOut() async {
    await googleSignIn.disconnect();
  }

  Future<void> _pickImage(int person) async {
    final XFile? picked =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    final appDir = await getApplicationDocumentsDirectory();
    final fileName =
        'avatar_$person${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedImage = await File(picked.path).copy('${appDir.path}/$fileName');

    if (!mounted) return;
    setState(() {
      if (person == 1) {
        _imagePath1 = savedImage.path;
      } else {
        _imagePath2 = savedImage.path;
      }
    });
    await _saveImagePath(person, savedImage.path);
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      helpText: 'Chọn ngày bắt đầu yêu',
      confirmText: 'CHỌN',
      cancelText: 'HỦY',
    );
    if (picked == null) return;
    if (!mounted) return;
    setState(() => _startDate = picked);
    await _saveStartDate(picked);
  }

  Future<void> _editName(int person) async {
    final controller =
        TextEditingController(text: person == 1 ? _name1 : _name2);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(person == 1 ? 'Tên người thứ nhất' : 'Tên người thứ hai'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nhập tên...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    if (!mounted) return;
    setState(() {
      if (person == 1) {
        _name1 = result;
      } else {
        _name2 = result;
      }
    });
    await _saveNames();
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
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final now = DateTime.now();
    final startOnly =
        DateTime(_startDate.year, _startDate.month, _startDate.day);
    final nowOnly = DateTime(now.year, now.month, now.day);

    final totalDays = nowOnly.difference(startOnly).inDays;
    final duration = _calculateDuration(startOnly, nowOnly);

    final bgColors = _backgrounds[_bgColorIndex];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black54),
            tooltip: 'Đăng xuất',
            onPressed: _handleSignOut,
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                const SizedBox(height: 12),
                const Text(
                  'Chúng ta đã bên nhau',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB03052),
                  ),
                ),
                const SizedBox(height: 32),

                // ----- Ảnh đại diện -----
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildAvatar(_imagePath1, () => _pickImage(1)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Icon(Icons.favorite,
                          color: Color(0xFFE75480), size: 32),
                    ),
                    _buildAvatar(_imagePath2, () => _pickImage(2)),
                  ],
                ),
                const SizedBox(height: 12),

                // ----- Tên hai người -----
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildNameChip(_name1, () => _editName(1)),
                    const SizedBox(width: 8),
                    const Text('&', style: TextStyle(color: Colors.black54)),
                    const SizedBox(width: 8),
                    _buildNameChip(_name2, () => _editName(2)),
                  ],
                ),

                const SizedBox(height: 40),

                // ----- Số ngày yêu -----
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
                  style: const TextStyle(fontSize: 14, color: Colors.black45),
                ),

                const SizedBox(height: 32),

                // ----- Ngày bắt đầu -----
                GestureDetector(
                  onTap: _pickStartDate,
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
                          'Bắt đầu: ${DateFormat('dd/MM/yyyy').format(_startDate)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ----- Chọn màu nền -----
                const Text('Nền',
                    style: TextStyle(fontSize: 13, color: Colors.black45)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_backgrounds.length, (index) {
                    final colors = _backgrounds[index];
                    final selected = index == _bgColorIndex;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _bgColorIndex = index);
                        _saveBgIndex(index);
                      },
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

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String? path, VoidCallback onTap) {
    ImageProvider? imageProvider;
    if (path != null && path.isNotEmpty) {
      if (path.startsWith('http://') || path.startsWith('https://')) {
        imageProvider = NetworkImage(path);
      } else {
        imageProvider = FileImage(File(path));
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 48,
        backgroundColor: Colors.white,
        backgroundImage: imageProvider,
        child: imageProvider == null
            ? const Icon(Icons.add_a_photo, color: Color(0xFFE75480), size: 28)
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
