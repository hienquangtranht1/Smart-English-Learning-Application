import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/vocab.dart';
import '../services/storage_service.dart';

class DetailPage extends StatefulWidget {
  final Vocab vocab;
  final bool? isFavorite;
  final VoidCallback? onToggleFav;

  const DetailPage({
    super.key,
    required this.vocab,
    this.isFavorite,
    this.onToggleFav,
  });

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final FlutterTts _tts = FlutterTts();
  final StorageService _storage = StorageService();
  bool _speaking = false;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _initFavorite();
    _initTts();
  }

  @override
  void dispose() {
    _tts.stop();
    _tts.awaitSpeakCompletion(true);
    super.dispose();
  }

  Future<void> _initFavorite() async {
    if (widget.isFavorite != null) {
      setState(() => _isFavorite = widget.isFavorite!);
      return;
    }
    final favs = await _storage.loadFavorites();
    setState(() => _isFavorite = favs.contains(widget.vocab.id));
  }

  Future<void> _initTts() async {
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _tts.setStartHandler(() {
      if (mounted) setState(() => _speaking = true);
    });
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _speaking = false);
    });
    _tts.setErrorHandler((msg) {
      if (mounted) setState(() => _speaking = false);
    });
  }

  Future<void> _speakEn() async {
    final text = widget.vocab.en;
    if (text.isEmpty) return;
    await _tts.setLanguage('en-US');
    await _tts.speak(text);
  }

  Future<void> _speakVi() async {
    final text = widget.vocab.vi;
    if (text.isEmpty) return;
    await _tts.setLanguage('vi-VN');
    await _tts.speak(text);
  }

  Future<void> _stopSpeak() async {
    await _tts.stop();
    if (mounted) setState(() => _speaking = false);
  }

  Future<void> _toggleFavorite() async {
    final favs = Set<String>.from(await _storage.loadFavorites());
    if (favs.contains(widget.vocab.id)) {
      favs.remove(widget.vocab.id);
      _isFavorite = false;
    } else {
      favs.add(widget.vocab.id);
      _isFavorite = true;
    }
    await _storage.saveFavorites(favs.toList());
    if (mounted) setState(() {});
    if (widget.onToggleFav != null) widget.onToggleFav!();
    final snackText = _isFavorite ? 'Đã thêm vào yêu thích' : 'Đã xóa khỏi yêu thích';
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(snackText)));
  }

  @override
  Widget build(BuildContext context) {
    final vocab = widget.vocab;
    return Scaffold(
      appBar: AppBar(
        title: Text(vocab.en),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
            onPressed: _toggleFavorite,
            tooltip: _isFavorite ? 'Xóa yêu thích' : 'Thêm yêu thích',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(vocab.en, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(vocab.vi, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            children: [
              ElevatedButton.icon(
                onPressed: _speaking ? null : _speakEn,
                icon: const Icon(Icons.volume_up),
                label: const Text('Phát âm EN'),
              ),
              ElevatedButton.icon(
                onPressed: _speaking ? null : _speakVi,
                icon: const Icon(Icons.record_voice_over),
                label: const Text('Phát âm VI'),
              ),
              ElevatedButton.icon(
                onPressed: _speaking ? _stopSpeak : null,
                icon: const Icon(Icons.stop),
                label: const Text('Dừng'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  final clip = '${vocab.en} — ${vocab.vi}';
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copied: $clip')));
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copy'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Nguồn: ${vocab.userAdded ? 'Người dùng' : 'Danh sách gốc'}', style: const TextStyle(color: Colors.grey)),
        ]),
      ),
    );
  }
}
