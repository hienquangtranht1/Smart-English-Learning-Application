import 'package:flutter/material.dart';
import '../models/quiz_models.dart';
import '../services/quiz_storage_service.dart';
import '../services/quiz_loader.dart';
import 'quiz_from_pack_page.dart';
import 'quiz_edit_exercise_page.dart';

class QuizPackExercisesPage extends StatefulWidget {
  final String assetPath;
  final String? title;
  const QuizPackExercisesPage({super.key, required this.assetPath, this.title});

  @override
  State<QuizPackExercisesPage> createState() => _QuizPackExercisesPageState();
}

class _QuizPackExercisesPageState extends State<QuizPackExercisesPage> {
  final QuizStorageService _store = QuizStorageService();
  final QuizLoader _loader = QuizLoader();

  QuizPack? _pack;
  bool _loading = true;
  String? _error;

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

      final p = await _store.loadPack(widget.assetPath, defaultPack: defaultPack);
      if (!mounted) return;
      setState(() {
        _pack = p;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Lỗi: Không thể tải gói Quiz. Vui lòng kiểm tra file dữ liệu.';
      });
    }
  }

  Future<void> _startAll() async {
    if (_pack == null) return;
    final all = <QuestionItem>[];
    for (final e in _pack!.exercises) {
      all.addAll(e.questions);
    }
    if (all.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không có câu hỏi nào để làm.')));
      return;
    }
    await Navigator.push(context, MaterialPageRoute(builder: (_) => QuizFromPackPage(assetPath: widget.assetPath, questionsOverride: all)));
    await _loadPack();
  }

  Future<void> _openExercise(Exercise ex) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => QuizFromPackPage(assetPath: widget.assetPath, exerciseId: ex.id)));
    await _loadPack();
  }

  Future<void> _addExercise() async {
    final newEx = Exercise(
      id: 0,
      title: 'Bài mới',
      instructions: '',
      questions: [QuestionItem(id: 1, question: '', choices: {'A': '', 'B': '', 'C': '', 'D': ''}, answer: 'A')],
    );

    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => QuizEditExercisePage(exercise: newEx, isNew: true, packLevel: _pack?.level, allLevels: _pack != null ? [_pack!.level] : const [])),
    );

    if (result != null && result.containsKey('exercise')) {
      final Exercise added = result['exercise'] as Exercise;
      await _store.addExercise(widget.assetPath, added, defaultPack: _pack);
      await _loadPack();
    }
  }

  Future<void> _editExercise(Exercise ex) async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => QuizEditExercisePage(exercise: ex, isNew: false, packLevel: _pack?.level, allLevels: _pack != null ? [_pack!.level] : const [])),
    );

    if (result != null && result.containsKey('exercise')) {
      final Exercise updated = result['exercise'] as Exercise;
      await _store.editExercise(widget.assetPath, updated, defaultPack: _pack);
      await _loadPack();
    }
  }

  Future<void> _deleteExercise(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa bài tập'),
        content: const Text('Bạn có chắc muốn xóa bài tập này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa')),
        ],
      ),
    );

    if (ok == true) {
      await _store.deleteExercise(widget.assetPath, id, defaultPack: _pack);
      await _loadPack();
    }
  }

  Widget _buildSummaryCard(QuizPack pack) {
    final totalQuestions = pack.exercises.fold<int>(0, (p, e) => p + e.questions.length);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Cấp độ: ${pack.level}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
          const Divider(height: 16, thickness: 1),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Tổng số bài tập:', style: TextStyle(color: Colors.grey.shade700)), Text('${pack.exercises.length} bài', style: const TextStyle(fontWeight: FontWeight.w600))]),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Tổng số câu hỏi:', style: TextStyle(color: Colors.grey.shade700)), Text('$totalQuestions câu', style: const TextStyle(fontWeight: FontWeight.w600))]),
        ]),
      ),
    );
  }

  Widget _buildStartAllButton(QuizPack pack) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        icon: const Icon(Icons.play_arrow),
        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), backgroundColor: Colors.deepOrange),
        onPressed: _startAll,
        label: const Text('LÀM TOÀN BỘ GÓI QUIZ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? (_pack?.level ?? 'Quiz pack')),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadPack, tooltip: 'Tải lại gói Quiz')],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addExercise,
        child: const Icon(Icons.add),
        tooltip: 'Thêm bài tập mới',
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.red.shade700, fontSize: 16)),
        ),
      )
          : _pack == null || _pack!.exercises.isEmpty
          ? const Center(child: Text('Không có bài tập nào trong gói này.'))
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildSummaryCard(_pack!),
          _buildStartAllButton(_pack!),
          const SizedBox(height: 20),
          const Text('Hoặc chọn từng bài tập:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: _pack!.exercises.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, idx) {
                final ex = _pack!.exercises[idx];
                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: CircleAvatar(backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1), child: Text('${idx + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor))),
                    title: Text(ex.title.isEmpty ? 'Bài ${ex.id}' : ex.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${ex.questions.length} câu • ${ex.instructions}', style: TextStyle(color: Colors.grey.shade700)),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'open') {
                          await _openExercise(ex);
                        } else if (v == 'edit') {
                          await _editExercise(ex);
                        } else if (v == 'delete') {
                          await _deleteExercise(ex.id);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'open', child: Text('Làm bài')),
                        const PopupMenuItem(value: 'edit', child: Text('Sửa')),
                        const PopupMenuItem(value: 'delete', child: Text('Xóa')),
                      ],
                    ),
                    onTap: () => _openExercise(ex),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}
