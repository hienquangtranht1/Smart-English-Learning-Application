import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../services/storage_service.dart';
import '../services/auth_service.dart';
import '../models/quiz_result.dart';
import 'history_detail_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final StorageService _storage = StorageService();
  List<QuizResult> _history = [];
  bool _loading = true;
  String? _ownerUsername;

  @override
  void initState() {
    super.initState();
    _loadForCurrentUser();
  }

  Future<void> _loadForCurrentUser() async {
    setState(() {
      _loading = true;
      _history = [];
    });

    final auth = context.read<AuthService>();
    final username = auth.currentUsername;
    _ownerUsername = username ?? 'guest';
    final list = await _storage.loadQuizHistory(username: username);
    if (!mounted) return;
    setState(() {
      _history = list.reversed.toList();
      _loading = false;
    });
  }

  Color _getScoreColor(double score) {
    if (score >= 0.9) return Colors.green.shade700;
    if (score >= 0.7) return Colors.lightGreen.shade700;
    if (score >= 0.5) return Colors.orange.shade700;
    return Colors.red.shade700;
  }

  Future<void> _clearHistory() async {
    final auth = context.read<AuthService>();
    final username = auth.currentUsername;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận Xóa Lịch Sử', style: TextStyle(color: Colors.red)),
        content: const Text('Bạn có chắc chắn muốn xóa toàn bộ lịch sử làm bài Quiz của mình không? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa Hết', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _storage.clearQuizHistory(username: username);
    await _loadForCurrentUser();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa toàn bộ lịch sử làm bài.')));
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.history_toggle_off,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          const Text(
            'Lịch sử làm bài trống',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              'Các kết quả làm Quiz của bạn sẽ được lưu tại đây.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final accountDisplay = _ownerUsername == 'guest' ? 'Khách' : (_ownerUsername ?? '');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử làm bài'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24.0),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Tài khoản: $accountDisplay',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: _clearHistory,
              tooltip: 'Xóa toàn bộ lịch sử',
            ),
          if (!auth.isLoggedIn)
            IconButton(
              icon: const Icon(Icons.person_pin_circle_outlined),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đăng nhập để lưu lịch sử vĩnh viễn theo tài khoản')));
              },
              tooltip: 'Thông tin tài khoản',
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
          ? _buildEmptyState(context)
          : ListView.separated(
        itemCount: _history.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
        itemBuilder: (context, idx) {
          final r = _history[idx];
          final scorePercent = (r.score * 100).toStringAsFixed(0);
          final scoreColor = _getScoreColor(r.score);
          final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(r.timestamp.toLocal());

          return ListTile(
            leading: Icon(Icons.check_circle, color: scoreColor),
            title: Text(
              r.quizTitle,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Đúng: ${r.correctAnswers} / ${r.totalQuestions} câu'),
                Text('Thời gian: $formattedDate', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: scoreColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: scoreColor, width: 0.5),
              ),
              child: Text(
                '$scorePercent%',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: scoreColor,
                  fontSize: 16,
                ),
              ),
            ),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => HistoryDetailPage(result: r))),
          );
        },
      ),
    );
  }
}