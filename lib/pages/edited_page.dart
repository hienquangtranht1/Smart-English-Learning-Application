import 'package:flutter/material.dart';

class EditedPage extends StatelessWidget {
  const EditedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log sửa (không lưu file)')),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'Ứng dụng hiện không lưu log sửa vào file. '
                'Chỉ lưu thay đổi vào SharedPreferences. '
                'Nếu bạn muốn bật log sửa, cập nhật StorageService để lưu ghi chú.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
