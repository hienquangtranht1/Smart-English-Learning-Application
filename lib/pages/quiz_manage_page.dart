import 'package:flutter/material.dart';
import '../models/quiz_models.dart';
import '../services/quiz_storage_service.dart';
import '../services/quiz_loader.dart';
import 'quiz_edit_exercise_page.dart';
import 'quiz_from_pack_page.dart';

class QuizManagePage extends StatefulWidget {
  final String assetPath;
  final String title;
  const QuizManagePage({super.key, required this.assetPath, required this.title});

  @override
  State<QuizManagePage> createState() => _QuizManagePageState();
}

class _QuizManagePageState extends State<QuizManagePage> {
  final QuizStorageService _storage = QuizStorageService();
  final QuizLoader _loader = QuizLoader();

  QuizPack? _pack;
  bool _loading = true;
  String? _error;

  static const Map<String, String> _levelAssetMap = {
    'Nhập môn': 'assets/data/bai_tap_tieng_anh_nhap_mon.json',
    'Trung cấp': 'assets/data/bai_tap_tieng_anh_trung_cap.json',
    'Nâng cao': 'assets/data/bai_tap_tieng_anh_nang_cao.json',
  };

  String _assetPathToLevel(String path) {
    return _levelAssetMap.entries
        .firstWhere((e) => e.value == path, orElse: () => const MapEntry('', ''))
        .key;
  }

  @override
  void initState() {
    super.initState();
    _loadPack();
  }

  Future<void> _loadPack() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      QuizPack? defaultPack;
      try {
        defaultPack = await _loader.tryLoadFromAsset(widget.assetPath);
      } catch (_) {
        defaultPack = null;
      }

      final p = await _storage.loadPack(widget.assetPath, defaultPack: defaultPack);
      if (!mounted) return;
      setState(() {
        _pack = p;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Lỗi: Không thể tải gói Quiz. Kiểm tra file assets.';
        _loading = false;
      });
    }
  }

  Future<void> _onAdd() async {
    final currentLevel = _pack?.level ?? _assetPathToLevel(widget.assetPath);

    final ex = Exercise(
      id: 0,
      title: 'Bài tập mới',
      instructions: 'Chọn đáp án đúng (Sửa lại sau)',
      questions: List.generate(
        5,
            (i) => QuestionItem(
          id: i + 1,
          question: 'Câu hỏi mẫu ${i + 1}?',
          choices: {
            'A': 'Lựa chọn A',
            'B': 'Lựa chọn B',
            'C': 'Lựa chọn C',
            'D': 'Lựa chọn D'
          },
          answer: 'A',
        ),
      ),
    );

    final res = await Navigator.of(context).push<Map<String, dynamic>?>(
      MaterialPageRoute(
        builder: (context) => QuizEditExercisePage(
          exercise: ex,
          isNew: true,
          packLevel: currentLevel,
          allLevels: _levelAssetMap.keys.toList(),
        ),
      ),
    );

    if (res is Map<String, dynamic>) {
      final updatedEx = res['exercise'] as Exercise;
      final newLevel = (res['newLevel'] as String?) ?? currentLevel;
      final targetAssetPath = _levelAssetMap[newLevel] ?? widget.assetPath;

      await _storage.addExercise(targetAssetPath, updatedEx, defaultPack: _pack);
      await _loadPack();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã thêm bài tập mới vào cấp độ $newLevel.')),
        );
      }
    }
  }

  Future<void> _onEdit(Exercise ex) async {
    final currentLevel = _pack?.level ?? _assetPathToLevel(widget.assetPath);

    final res = await Navigator.of(context).push<Map<String, dynamic>?>(
      MaterialPageRoute(
        builder: (context) => QuizEditExercisePage(
          exercise: ex,
          isNew: false,
          packLevel: currentLevel,
          allLevels: _levelAssetMap.keys.toList(),
        ),
      ),
    );

    if (res is Map<String, dynamic>) {
      final updatedEx = res['exercise'] as Exercise;
      final newLevel = (res['newLevel'] as String?) ?? currentLevel;
      final newAssetPath = _levelAssetMap[newLevel];

      if (newAssetPath == null) return;

      if (newAssetPath == widget.assetPath) {
        await _storage.editExercise(widget.assetPath, updatedEx, defaultPack: _pack);
      } else {
        await _storage.deleteExercise(widget.assetPath, updatedEx.id, defaultPack: _pack);
        await _storage.addExercise(newAssetPath, updatedEx);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã chuyển và sửa bài tập "${updatedEx.title}" sang cấp độ $newLevel.')),
          );
        }
      }

      await _loadPack();
    }
  }

  Future<void> _onDelete(Exercise ex) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận Xóa', style: TextStyle(color: Colors.red)),
        content: Text('Bạn có chắc muốn xóa vĩnh viễn bài "${ex.title}" không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _storage.deleteExercise(widget.assetPath, ex.id, defaultPack: _pack);
      await _loadPack();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã xóa bài "${ex.title}"')));
      }
    }
  }

  Future<void> _onResetPack() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận Khôi phục Gốc', style: TextStyle(color: Colors.red)),
        content: const Text(
          'Thao tác này sẽ xóa toàn bộ các thay đổi (thêm/sửa/xóa) của bạn và khôi phục gói Quiz về trạng thái ban đầu từ file assets. Bạn có chắc chắn muốn tiếp tục?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Khôi phục', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _storage.deleteUserPack(widget.assetPath);
      await _loadPack();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã khôi phục gói Quiz về trạng thái gốc.')));
      }
    }
  }

  Widget _buildSummaryCard(QuizPack pack) {
    final totalQuestions = pack.exercises.fold<int>(0, (p, e) => p + e.questions.length);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Cấp độ: ${pack.level}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
            const SizedBox(height: 4),
            Text('${pack.exercises.length} bài tập', style: const TextStyle(color: Colors.black54)),
          ]),
          Text('$totalQuestions câu hỏi', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadPack, tooltip: 'Tải lại'),
          IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: _onAdd, tooltip: 'Thêm bài tập mới'),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 16)))
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_pack != null) _buildSummaryCard(_pack!),
            const Text('Danh sách Bài tập:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: _pack!.exercises.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, idx) {
                  final ex = _pack!.exercises[idx];
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                        child: Text('${idx + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                      ),
                      title: Text(ex.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${ex.questions.length} câu • ${ex.instructions}', style: TextStyle(color: Colors.grey.shade600)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _onEdit(ex), tooltip: 'Sửa bài tập'),
                          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _onDelete(ex), tooltip: 'Xóa bài tập'),
                        ],
                      ),
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => QuizFromPackPage(assetPath: widget.assetPath, exerciseId: ex.id)));
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.restore_page),
                onPressed: _onResetPack,
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), backgroundColor: Colors.red.shade400),
                label: const Text('KHÔI PHỤC VỀ GỐC (RESET)', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
