// lib/pages/quiz_edit_exercise_page.dart

import 'package:flutter/material.dart';
import '../models/quiz_models.dart';

class QuizEditExercisePage extends StatefulWidget {
  final Exercise exercise;
  final bool isNew;
  final String? packLevel;
  final List<String> allLevels;

  const QuizEditExercisePage({
    super.key,
    required this.exercise,
    required this.isNew,
    this.packLevel,
    this.allLevels = const [],
  });

  @override
  State<QuizEditExercisePage> createState() => _QuizEditExercisePageState();
}

class _QuizEditExercisePageState extends State<QuizEditExercisePage> {
  late Exercise _ex;
  final _formKey = GlobalKey<FormState>();
  late String _selectedLevel;

  @override
  void initState() {
    super.initState();

    // Deep copy exercise to avoid mutating original until saved
    _ex = Exercise(
      id: widget.exercise.id,
      title: widget.exercise.title,
      instructions: widget.exercise.instructions,
      passages: widget.exercise.passages
          .map((p) => Passage(id: p.id, title: p.title, text: p.text))
          .toList(),
      questions: widget.exercise.questions
          .map((q) => QuestionItem(
        id: q.id,
        question: q.question,
        choices: Map<String, String>.from(q.choices),
        answer: q.answer,
        explanation: q.explanation,
        type: q.type,
        passageId: q.passageId,
      ))
          .toList(),
    );

    // ensure question ids are contiguous
    _normalizeQuestionIds();

    // prepare selected level safely
    final validLevels = widget.allLevels.map((l) => l.trim()).where((s) => s.isNotEmpty).toList();
    final initialLevel = (widget.packLevel ?? '').trim();
    if (initialLevel.isNotEmpty && validLevels.contains(initialLevel)) {
      _selectedLevel = initialLevel;
    } else if (validLevels.isNotEmpty) {
      _selectedLevel = validLevels.first;
    } else {
      _selectedLevel = '';
    }
  }

  void _normalizeQuestionIds() {
    for (int i = 0; i < _ex.questions.length; i++) {
      _ex.questions[i].id = i + 1;
    }
  }

  void _addQuestion() {
    setState(() {
      final nextId = _ex.questions.length + 1;
      _ex.questions.add(QuestionItem(
        id: nextId,
        question: '',
        choices: {'A': '', 'B': '', 'C': '', 'D': ''},
        answer: 'A',
        type: _ex.passages.isNotEmpty ? QuestionType.basedOnPassage : QuestionType.standalone,
        passageId: _ex.passages.isNotEmpty ? _ex.passages.first.id : null,
      ));
    });
  }

  void _insertQuestionAt(int index) {
    setState(() {
      _ex.questions.insert(
        index,
        QuestionItem(
          id: 0,
          question: '',
          choices: {'A': '', 'B': '', 'C': '', 'D': ''},
          answer: 'A',
        ),
      );
      _normalizeQuestionIds();
    });
  }

  void _removeQuestionAt(int index) {
    if (_ex.questions.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phải có ít nhất 1 câu hỏi trong bài.')));
      return;
    }
    setState(() {
      _ex.questions.removeAt(index);
      _normalizeQuestionIds();
    });
  }

  void _saveAndReturn() {
    if (!_formKey.currentState!.validate()) return;

    for (final q in _ex.questions) {
      if (q.question.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Có câu chưa nhập nội dung')));
        return;
      }
      final keys = q.choices.keys.toSet();
      if (!keys.containsAll({'A', 'B', 'C', 'D'})) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mỗi câu phải có 4 phương án A,B,C,D')));
        return;
      }
      if (!{'A', 'B', 'C', 'D'}.contains(q.answer)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đáp án phải là A/B/C/D')));
        return;
      }
      // if question is basedOnPassage but no passageId and there's exactly one passage, assign it
      if (q.type == QuestionType.basedOnPassage && (q.passageId == null || q.passageId!.isEmpty) && _ex.passages.length == 1) {
        q.passageId = _ex.passages.first.id;
      }
    }

    // ensure ids are normalized
    _normalizeQuestionIds();

    Navigator.of(context).pop({
      'exercise': _ex,
      'newLevel': _selectedLevel,
    });
  }

  Widget _buildPassagesEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Text('Passages', style: TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          TextButton.icon(onPressed: _addPassage, icon: const Icon(Icons.add), label: const Text('Thêm Passage')),
        ]),
        const SizedBox(height: 8),
        if (_ex.passages.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Không có passage. Thêm passage nếu bài yêu cầu đọc hiểu.'),
          ),
        ..._ex.passages.map((p) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: p.title,
                      decoration: const InputDecoration(labelText: 'Tiêu đề Passage', isDense: true),
                      onChanged: (v) => p.title = v,
                    ),
                  ),
                  IconButton(onPressed: () => _removePassage(p.id), icon: const Icon(Icons.delete_outline, color: Colors.red)),
                ]),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: p.text,
                  decoration: const InputDecoration(labelText: 'Nội dung Passage', alignLabelWithHint: true),
                  maxLines: 6,
                  onChanged: (v) => p.text = v,
                ),
                const SizedBox(height: 6),
                Text('ID: ${p.id}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
              ]),
            ),
          );
        }).toList(),
      ],
    );
  }

  void _addPassage() {
    final nextIndex = _ex.passages.length + 1;
    final id = 'p$nextIndex';
    setState(() {
      _ex.passages = List<Passage>.from(_ex.passages)..add(Passage(id: id, title: 'Passage $nextIndex', text: ''));
      // if there are questions and they were defaulting to passage-based, ensure passageId assigned where missing
      if (_ex.passages.length == 1) {
        final pid = _ex.passages.first.id;
        for (final q in _ex.questions) {
          if (q.type == QuestionType.basedOnPassage && (q.passageId == null || q.passageId!.isEmpty)) q.passageId = pid;
        }
      }
    });
  }

  void _removePassage(String id) {
    setState(() {
      _ex.passages = _ex.passages.where((p) => p.id != id).toList();
      // clear passage references in questions that pointed to this passage
      _ex.questions = _ex.questions.map((q) {
        if (q.passageId == id) {
          return QuestionItem(
            id: q.id,
            question: q.question,
            choices: Map<String, String>.from(q.choices),
            answer: q.answer,
            explanation: q.explanation,
            type: QuestionType.standalone,
            passageId: null,
          );
        }
        return q;
      }).toList();
    });
  }

  Widget _buildQuestionEditor(int idx) {
    final q = _ex.questions[idx];
    final isAnswered = q.question.trim().isNotEmpty &&
        q.answer.isNotEmpty &&
        q.choices.values.every((v) => v.trim().isNotEmpty);
    final color = isAnswered ? Colors.green.shade50 : Colors.red.shade50;
    final icon = isAnswered ? Icons.check_circle_outline : Icons.error_outline;
    final iconColor = isAnswered ? Colors.green.shade700 : Colors.red.shade700;

    final passageOptions = _ex.passages;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: iconColor.withOpacity(0.5)),
      ),
      color: color,
      child: ExpansionTile(
        key: ValueKey(q.id),
        initiallyExpanded: !isAnswered,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        leading: Icon(icon, color: iconColor),
        title: Text(
          'Câu ${idx + 1}: ${q.question.isNotEmpty ? (q.question.length <= 30 ? q.question : q.question.substring(0, 30) + '...') : 'Chưa nhập câu hỏi'}',
          style: TextStyle(fontWeight: FontWeight.bold, color: iconColor),
        ),
        subtitle: Text('Đáp án: ${q.answer} - Trạng thái: ${isAnswered ? 'OK' : 'Chưa hoàn tất'}'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // question
              TextFormField(
                initialValue: q.question,
                decoration: const InputDecoration(
                  labelText: 'Nội dung Câu hỏi',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => q.question = v,
                validator: (s) => (s == null || s.trim().isEmpty) ? 'Nhập câu hỏi' : null,
                maxLines: null,
              ),
              const SizedBox(height: 16),
              // passage selector for based-on-passage type
              Row(children: [
                const Text('Loại câu:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                DropdownButton<QuestionType>(
                  value: q.type,
                  items: const [
                    DropdownMenuItem(value: QuestionType.standalone, child: Text('Standalone')),
                    DropdownMenuItem(value: QuestionType.basedOnPassage, child: Text('Dựa trên Passage')),
                  ],
                  onChanged: (v) {
                    setState(() {
                      q.type = v ?? QuestionType.standalone;
                      if (q.type == QuestionType.basedOnPassage && (q.passageId == null || q.passageId!.isEmpty) && passageOptions.isNotEmpty) {
                        q.passageId = passageOptions.first.id;
                      }
                      if (q.type == QuestionType.standalone) q.passageId = null;
                    });
                  },
                ),
                const SizedBox(width: 12),
                if (passageOptions.isNotEmpty && q.type == QuestionType.basedOnPassage)
                  DropdownButton<String>(
                    value: q.passageId ?? passageOptions.first.id,
                    items: passageOptions.map((p) => DropdownMenuItem(value: p.id, child: Text(p.title.isNotEmpty ? p.title : p.id))).toList(),
                    onChanged: (v) => setState(() => q.passageId = v),
                  ),
                if (passageOptions.isEmpty && q.type == QuestionType.basedOnPassage)
                  const Padding(padding: EdgeInsets.only(left: 8), child: Text('Thêm passage trước')),
              ]),
              const SizedBox(height: 16),
              const Text('Phương án trả lời:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              for (final key in ['A', 'B', 'C', 'D'])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    Container(width: 30, alignment: Alignment.center, child: Text('$key.', style: const TextStyle(fontWeight: FontWeight.bold))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: q.choices[key] ?? '',
                        decoration: InputDecoration(
                          hintText: 'Phương án $key',
                          border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                          isDense: true,
                        ),
                        onChanged: (v) => q.choices[key] = v,
                        validator: (s) => (s == null || s.trim().isEmpty) ? 'Nhập đáp án $key' : null,
                        maxLines: null,
                      ),
                    ),
                  ]),
                ),
              const SizedBox(height: 16),
              const Divider(),
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                const Text('Đáp án đúng:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(border: Border.all(color: Colors.blue), borderRadius: BorderRadius.circular(8)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: q.answer,
                      items: ['A', 'B', 'C', 'D'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => q.answer = v);
                      },
                      icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                      style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Chèn câu trước câu này',
                  icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                  onPressed: () => _insertQuestionAt(idx),
                ),
                IconButton(
                  tooltip: 'Xóa câu hỏi',
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _removeQuestionAt(idx),
                ),
              ]),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: q.explanation ?? '',
                decoration: const InputDecoration(labelText: 'Giải thích (tùy chọn)', border: OutlineInputBorder(), isDense: true),
                onChanged: (v) => q.explanation = v,
                maxLines: null,
              ),
              const SizedBox(height: 8),
            ]),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final levelsItems = widget.allLevels.map((l) => l.trim()).where((s) => s.isNotEmpty).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew ? 'Tạo Bài Tập Mới' : 'Sửa Bài Tập'),
        actions: [
          TextButton(onPressed: _saveAndReturn, child: const Text('LƯU', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            color: Colors.grey.shade50,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Cấp độ Quiz:', style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  value: _selectedLevel.isEmpty ? null : _selectedLevel,
                  hint: const Text('Chọn cấp độ'),
                  items: levelsItems.map((level) => DropdownMenuItem(value: level, child: Text(level))).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedLevel = v);
                  },
                ),
              ]),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _ex.title,
                decoration: const InputDecoration(labelText: 'Tiêu đề bài tập', border: OutlineInputBorder(), isDense: true),
                onChanged: (v) => _ex.title = v,
                validator: (s) => (s == null || s.trim().isEmpty) ? 'Nhập tiêu đề' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _ex.instructions,
                decoration: const InputDecoration(labelText: 'Hướng dẫn ngắn (Ví dụ: Chọn 1 đáp án đúng)', border: OutlineInputBorder(), isDense: true),
                onChanged: (v) => _ex.instructions = v,
                maxLines: null,
              ),
              const SizedBox(height: 8),
              Row(children: [
                Text('Số câu hiện tại: ${_ex.questions.length}', style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                ElevatedButton.icon(onPressed: _addQuestion, icon: const Icon(Icons.add), label: const Text('Thêm câu')),
              ]),
            ]),
          ),
          // questions list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                const SizedBox(height: 8),
                _buildPassagesEditor(),
                const SizedBox(height: 12),
                ...List.generate(_ex.questions.length, (i) => _buildQuestionEditor(i)),
                const SizedBox(height: 16),
              ],
            ),
          ),
          // action buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 5)]),
            child: Row(children: [
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.save),
                  onPressed: _saveAndReturn,
                  label: const Text('LƯU TẤT CẢ'),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.undo),
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Xác nhận Reset'),
                        content: const Text('Bạn có chắc muốn reset hết câu hỏi và để bài trống 1 câu mẫu không?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
                          ElevatedButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                setState(() {
                                  _ex.questions = [QuestionItem(id: 1, question: '', choices: {'A': '', 'B': '', 'C': '', 'D': ''}, answer: 'A')];
                                });
                              },
                              child: const Text('Reset')),
                        ],
                      ));
                },
                label: const Text('Reset Câu'),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
