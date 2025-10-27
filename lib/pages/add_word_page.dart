import 'package:flutter/material.dart';

class AddWordPage extends StatefulWidget {
  const AddWordPage({super.key});

  @override
  State<AddWordPage> createState() => _AddWordPageState();
}

class _AddWordPageState extends State<AddWordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _enController = TextEditingController();
  final TextEditingController _viController = TextEditingController();

  @override
  void dispose() {
    _enController.dispose();
    _viController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final en = _enController.text.trim();
    final vi = _viController.text.trim();
    Navigator.of(context).pop({'en': en, 'vi': vi});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm từ mới (Admin)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nhập từ vựng Anh - Việt',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _enController,
                    decoration: const InputDecoration(
                      labelText: 'Từ tiếng Anh',
                      hintText: 'Ví dụ: amazing',
                      prefixIcon: Icon(Icons.abc),
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.none,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Vui lòng nhập từ tiếng Anh';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _viController,
                    decoration: const InputDecoration(
                      labelText: 'Nghĩa tiếng Việt',
                      hintText: 'Ví dụ: Tuyệt vời, kinh ngạc',
                      prefixIcon: Icon(Icons.translate),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Vui lòng nhập nghĩa tiếng Việt';
                      return null;
                    },
                    maxLines: 3,
                    minLines: 1,
                  ),
                  const SizedBox(height: 30),

                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _save,
                          icon: const Icon(Icons.save),
                          label: const Text('Lưu từ'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.cancel),
                          label: const Text('Hủy'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}