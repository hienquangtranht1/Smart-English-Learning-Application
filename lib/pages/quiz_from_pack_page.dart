import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/quiz_models.dart';
import '../models/quiz_result.dart';
import '../models/quiz_exercise_attempt.dart';
import '../services/quiz_storage_service.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import 'history_detail_page.dart';

class QuizFromPackPage extends StatefulWidget {
  final String assetPath;
  final int? exerciseId;
  final List<QuestionItem>? questionsOverride;
  final int questionCount;

  const QuizFromPackPage({
    super.key,
    required this.assetPath,
    this.exerciseId,
    this.questionsOverride,
    this.questionCount = 10,
  });

  @override
  State<QuizFromPackPage> createState() => _QuizFromPackPageState();
}

class _QuizFromPackPageState extends State<QuizFromPackPage> {
  final QuizStorageService _store = QuizStorageService();
  final StorageService _storage = StorageService();

  QuizPack? _pack;
  Exercise? _exercise;
  List<QuestionItem> _qs = [];
  Map<int, String> _answers = {};
  bool _loading = true;
  bool _submitted = false;
  int _score = 0;
  QuizResult? _lastResult;

  @override
  void initState() {
    super.initState();
    _loadSource();
  }

  Future<void> _loadSource() async {
    setState(() {
      _loading = true;
      _submitted = false;
      _answers = {};
      _score = 0;
      _qs = [];
      _exercise = null;
      _pack = null;
      _lastResult = null;
    });

    try {
      final pack = await _store.loadPack(widget.assetPath);

      if (widget.questionsOverride != null && widget.questionsOverride!.isNotEmpty) {
        _qs = List<QuestionItem>.from(widget.questionsOverride!);
      } else if (widget.exerciseId != null) {
        final exList = pack.exercises.where((e) => e.id == widget.exerciseId).toList();
        _exercise = exList.isNotEmpty ? exList.first : null;
        _qs = _exercise != null ? List<QuestionItem>.from(_exercise!.questions) : [];
      } else {
        final all = <QuestionItem>[];
        for (final e in pack.exercises) all.addAll(e.questions);
        all.shuffle();
        final takeCount = widget.questionCount.clamp(1, all.length);
        _qs = all.take(takeCount).toList();
      }

      final Map<String, int> counts = {};
      for (final q in _qs) {
        if (q.passageId != null && q.passageId!.isNotEmpty) {
          counts[q.passageId!] = (counts[q.passageId!] ?? 0) + 1;
        }
      }
      if (counts.isNotEmpty) {
        final chosenPassageId = counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
        for (final ex in pack.exercises) {
          final matches = ex.passages.where((pp) => pp.id == chosenPassageId);
          if (matches.isNotEmpty) {
            _exercise = ex;
            break;
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _pack = pack;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _qs = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể tải dữ liệu Quiz.')));
    }
  }

  void _selectAnswer(QuestionItem q, String choiceKey) {
    if (_submitted) return;
    setState(() {
      _answers[q.id] = choiceKey;
    });
  }

  Future<void> _submit() async {
    if (_submitted) return;

    final unanswered = _qs.where((q) => !_answers.containsKey(q.id)).toList();
    if (unanswered.isNotEmpty) {
      final cnt = unanswered.length;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Xác nhận nộp bài'),
          content: Text('Bạn chưa trả lời $cnt câu. Bạn có muốn nộp bài ngay không?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Hủy')),
            ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Nộp ngay')),
          ],
        ),
      );
      if (confirm != true) return;
    }

    int correct = 0;
    for (final q in _qs) {
      final picked = _answers[q.id];
      if (picked != null && picked.toUpperCase() == q.answer.toUpperCase()) correct++;
    }

    setState(() {
      _submitted = true;
      _score = correct;
    });

    final Map<String, String> userAnswersMap = {};
    for (final q in _qs) {
      final picked = _answers[q.id];
      if (picked != null) userAnswersMap[q.id.toString()] = picked;
    }

    final attempt = QuizExerciseAttempt(questions: _qs, userAnswers: userAnswersMap);

    final title = widget.exerciseId != null
        ? 'Bài: ${_exercise?.title ?? 'ID ${widget.exerciseId}'}'
        : 'Quiz ngẫu nhiên (${widget.assetPath.split('/').last})';

    final result = QuizResult.create(
      quizTitle: title,
      totalQuestions: _qs.length,
      correctAnswers: correct,
      attemptDetails: attempt,
    );

    _lastResult = result;

    try {
      final auth = context.read<AuthService>();
      final username = auth.currentUsername;
      await _storage.appendQuizHistory(result, username: username);
    } catch (_) {
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã nộp: $correct / ${_qs.length} câu đúng')));
  }

  Widget _buildPassageCard() {
    if (_exercise == null || _exercise!.passages.isEmpty) return const SizedBox.shrink();

    final passage = _exercise!.passages.first;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (passage.title.isNotEmpty) Text(passage.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(passage.text),
        ]),
      ),
    );
  }

  Widget _buildQuestionCard(QuestionItem q, int idx) {
    final picked = _answers[q.id];
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (q.type == QuestionType.basedOnPassage)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Chip(label: const Text('Dựa trên đoạn văn'), backgroundColor: Colors.orange.shade50),
            ),
          Text('Câu ${idx + 1}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(q.question, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 12),
          ...q.choices.entries.map((e) {
            final key = e.key;
            final text = e.value;
            final selected = picked == key;
            Color bg = Colors.transparent;
            Color border = Colors.grey.shade300;
            Color txt = Colors.black87;

            if (!_submitted && selected) {
              bg = Theme.of(context).primaryColor.withOpacity(0.08);
              border = Theme.of(context).primaryColor;
            } else if (_submitted) {
              final isCorrect = key.toUpperCase() == q.answer.toUpperCase();
              if (isCorrect) {
                bg = Colors.green.shade50;
                border = Colors.green.shade500;
                txt = Colors.green.shade900;
              }
              if (selected && !isCorrect) {
                bg = Colors.red.shade50;
                border = Colors.red.shade500;
                txt = Colors.red.shade900;
              }
            }

            return InkWell(
              onTap: () => _selectAnswer(q, key),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: border, width: 1.2),
                ),
                child: Row(children: [
                  Text('$key. ', style: TextStyle(fontWeight: FontWeight.w600, color: txt)),
                  Expanded(child: Text(text, style: TextStyle(color: txt))),
                ]),
              ),
            );
          }).toList(),
          if (_submitted && q.explanation != null && q.explanation!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Giải thích:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
            const SizedBox(height: 4),
            Text(q.explanation!, style: TextStyle(color: Colors.grey.shade800)),
          ],
        ]),
      ),
    );
  }

  Widget _buildResultBanner() {
    if (!_submitted) return const SizedBox.shrink();
    final percent = _qs.isEmpty ? 0 : (_score / _qs.length * 100).toStringAsFixed(0);
    final color = _score == _qs.length ? Colors.green : Colors.red;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Kết quả: $_score / ${_qs.length} ($percent%)', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          Row(children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.info_outline, size: 18),
              label: const Text('Xem chi tiết'),
              onPressed: _lastResult == null
                  ? null
                  : () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => HistoryDetailPage(result: _lastResult!, isImmediateResult: true)));
              },
              style: ElevatedButton.styleFrom(backgroundColor: color),
            ),
          ]),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_qs.isEmpty) return Scaffold(appBar: AppBar(title: const Text('Quiz')), body: const Center(child: Text('Không có câu hỏi')));

    final title = _exercise?.title ?? _pack?.title ?? 'Quiz';
    return Scaffold(
      appBar: AppBar(title: Text('$title (${_qs.length} câu)')),
      body: Column(
        children: [
          _buildPassageCard(),
          _buildResultBanner(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _qs.length,
              itemBuilder: (_, idx) => _buildQuestionCard(_qs[idx], idx),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(12),
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _submitted ? () => Navigator.of(context).pop() : _submit,
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: Text(_submitted ? 'Hoàn tất & Quay lại' : 'Nộp bài', style: const TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(width: 12),
              if (_submitted)
                OutlinedButton(
                  onPressed: _loadSource,
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('Làm lại'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
