import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const LoveCounterApp());
}

/// Widget gốc của ứng dụng - cấu hình theme màu hồng/đỏ nhẹ nhàng
class LoveCounterApp extends StatelessWidget {
  const LoveCounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chúng ta đã bên nhau',
      debugShowCheckedModeBanner: false,
      // Đặt tiếng Việt làm ngôn ngữ mặc định (để DatePicker hiện đúng tiếng Việt)
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
        colorSchemeSeed: const Color(0xFFE75480), // tông hồng/đỏ chủ đạo
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ----- Trạng thái mặc định (dùng khi lần đầu mở app) -----
  DateTime _startDate = DateTime(2024, 2, 17); // mốc ngày mặc định 17/02/2024
  String _name1 = 'Anh';
  String _name2 = 'Em';
  String? _imagePath1;
  String? _imagePath2;
  int _bgColorIndex = 0;
  bool _isLoading = true;

  final ImagePicker _picker = ImagePicker();

  // Danh sách nền (gradient 2 màu) để người dùng chọn thay đổi
  final List<List<Color>> _backgrounds = [
    [const Color(0xFFFFF0F3), Colors.white], // hồng nhạt
    [const Color(0xFFFFE1E6), const Color(0xFFFFF6F8)], // hồng phấn
    [const Color(0xFFFFD6D6), Colors.white], // đỏ nhạt
    [const Color(0xFFE8D9FF), const Color(0xFFFFF6F8)], // tím pastel
    [const Color(0xFFD9E8FF), Colors.white], // xanh pastel
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ================= LƯU / ĐỌC DỮ LIỆU (shared_preferences) =================

  // Đọc toàn bộ dữ liệu đã lưu khi mở app
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      final savedMillis = prefs.getInt('start_date');
      _startDate = savedMillis != null
          ? DateTime.fromMillisecondsSinceEpoch(savedMillis)
          : DateTime(2024, 2, 17);
      _name1 = prefs.getString('name1') ?? 'Anh';
      _name2 = prefs.getString('name2') ?? 'Em';
      _imagePath1 = prefs.getString('image1_path');
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

  // ================= CÁC HÀNH ĐỘNG NGƯỜI DÙNG =================

  // Chọn ảnh từ thư viện, copy vào thư mục nội bộ của app để không bị mất
  // (ảnh gốc image_picker trả về nằm ở cache, có thể bị hệ thống dọn dẹp)
  Future<void> _pickImage(int person) async {
    final XFile? picked =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    final appDir = await getApplicationDocumentsDirectory();
    final fileName =
        'avatar_$person${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedImage =
        await File(picked.path).copy('${appDir.path}/$fileName');

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

  // Mở DatePicker để chọn lại ngày bắt đầu yêu
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

  // Hộp thoại chỉnh sửa tên của 1 người
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

  // Tính chính xác "X năm Y tháng Z ngày" giữa 2 mốc thời gian (không chỉ chia đơn giản)
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

  // ================= GIAO DIỆN =================

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Chỉ tính theo ngày (bỏ qua giờ/phút) để số ngày luôn tròn và chính xác
    final now = DateTime.now();
    final startOnly = DateTime(_startDate.year, _startDate.month, _startDate.day);
    final nowOnly = DateTime(now.year, now.month, now.day);

    // ---- LOGIC CHÍNH: lấy hiện tại trừ ngày bắt đầu ----
    final totalDays = nowOnly.difference(startOnly).inDays;
    final duration = _calculateDuration(startOnly, nowOnly);

    final bgColors = _backgrounds[_bgColorIndex];

    return Scaffold(
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

                // ----- Hai ảnh đại diện (chạm để đổi ảnh) -----
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

                // ----- Tên hai người (chạm để chỉnh sửa) -----
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

                // ----- Số ngày yêu (kết quả tính toán chính) -----
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

                // ----- Ngày bắt đầu (chạm để đổi ngày) -----
                GestureDetector(
                  onTap: _pickStartDate,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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

                const SizedBox(height: 40),

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
                            color:
                                selected ? const Color(0xFFE75480) : Colors.white,
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

  // Widget avatar tròn - hiện ảnh đã chọn hoặc icon placeholder
  Widget _buildAvatar(String? path, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 48,
        backgroundColor: Colors.white,
        backgroundImage: path != null ? FileImage(File(path)) : null,
        child: path == null
            ? const Icon(Icons.add_a_photo, color: Color(0xFFE75480), size: 28)
            : null,
      ),
    );
  }

  // Widget nhãn tên dạng "chip" bo tròn
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
