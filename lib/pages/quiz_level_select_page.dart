import 'package:flutter/material.dart';
import 'quiz_pack_exercises_page.dart';

class QuizLevelSelectPage extends StatelessWidget {
  const QuizLevelSelectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chọn Cấp Độ Quiz')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'Bắt đầu hành trình học tập của bạn:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)
            ),
            const SizedBox(height: 16),

            Expanded(
              child: ListView(
                children: [
                  _levelCard(context, 'Nhập môn', 'assets/data/bai_tap_tieng_anh_nhap_mon.json', Icons.school, Colors.green),
                  _levelCard(context, 'Trung cấp', 'assets/data/bai_tap_tieng_anh_trung_cap.json', Icons.trending_up, Colors.orange),
                  _levelCard(context, 'Nâng cao', 'assets/data/bai_tap_tieng_anh_nang_cao.json', Icons.rocket_launch, Colors.red),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _levelCard(BuildContext ctx, String title, String asset, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.5), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        leading: Icon(icon, size: 36, color: color),
        title: Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
        subtitle: Text(
          _getSubtitle(title),
          style: const TextStyle(color: Colors.black54),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
        onTap: () => Navigator.push(
            ctx,
            MaterialPageRoute(
                builder: (_) => QuizPackExercisesPage(assetPath: asset, title: title)
            )
        ),
      ),
    );
  }

  String _getSubtitle(String title) {
    switch (title) {
      case 'Nhập môn':
        return 'Xây dựng nền tảng từ vựng và ngữ pháp cơ bản.';
      case 'Trung cấp':
        return 'Luyện tập các cấu trúc phức tạp và từ vựng thông dụng.';
      case 'Nâng cao':
        return 'Thử thách với các câu hỏi chuyên sâu và học thuật.';
      default:
        return 'Bắt đầu làm bài Quiz ngay!';
    }
  }
}