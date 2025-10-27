import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/vocab.dart';

class FlashcardPage extends StatefulWidget {
  final List<Vocab> all;
  const FlashcardPage({super.key, required this.all});
  @override
  State<FlashcardPage> createState() => _FlashcardPageState();
}

class _FlashcardPageState extends State<FlashcardPage> {
  late List<Vocab> _cards;
  int _index = 0;
  bool _showBack = false;
  final FlutterTts _tts = FlutterTts();
  bool _speaking = false;
  bool _autoplay = false;

  @override
  void initState() {
    super.initState();
    _cards = List.from(widget.all);
    _cards.shuffle();
    _initTts();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _initTts() async {
    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.45);
      _tts.setStartHandler(() {
        if (mounted) setState(() => _speaking = true);
      });
      _tts.setCompletionHandler(() {
        if (mounted) setState(() => _speaking = false);
      });
      _tts.setCancelHandler(() {
        if (mounted) setState(() => _speaking = false);
      });
      _tts.setErrorHandler((msg) {
        if (mounted) setState(() => _speaking = false);
      });
    } catch (_) {
    }
  }

  void _next() => setState(() {
    if (_cards.isEmpty) return;
    _index = (_index + 1) % _cards.length;
    _showBack = false;
    if (_autoplay) _speakEnCurrent();
  });

  void _prev() => setState(() {
    if (_cards.isEmpty) return;
    _index = (_index - 1 + _cards.length) % _cards.length;
    _showBack = false;
    if (_autoplay) _speakEnCurrent();
  });

  void _flip() {
    setState(() {
      _showBack = !_showBack;
      if (_autoplay || (_showBack == false)) _speakEnCurrent();
    });
  }

  Future<void> _speakEnCurrent() async {
    if (_cards.isEmpty) return;
    final text = _cards[_index].en;
    if (text.isEmpty) return;
    await _stopSpeak();
    try {
      await _tts.setLanguage('en-US');
      await _tts.speak(text);
    } catch (_) {
      try {
        await _tts.speak(text);
      } catch (_) {}
    }
  }

  Future<void> _speakViCurrent() async {
    if (_cards.isEmpty) return;
    final text = _cards[_index].vi;
    if (text.isEmpty) return;
    await _stopSpeak();
    try {
      await _tts.setLanguage('vi-VN');
      await _tts.speak(text);
    } catch (_) {
      try {
        await _tts.speak(text);
      } catch (_) {}
    }
  }


  Future<void> _stopSpeak() async {
    try {
      await _tts.stop();
    } catch (_) {}
    if (mounted) setState(() => _speaking = false);
  }

  void _toggleAutoplay() {
    setState(() {
      _autoplay = !_autoplay;
      if (_autoplay) _speakEnCurrent();
    });
  }

  Widget _buildFlashcard(Vocab card) {
    return GestureDetector(
      key: ValueKey(_showBack),
      onTap: _flip,
      child: Card(
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          height: 300,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _showBack ? 'Tiếng Việt' : 'English',
                style: TextStyle(
                  fontSize: 18,
                  color: _showBack ? Colors.green : Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _showBack ? card.vi : card.en,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              if (_showBack)
                TextButton.icon(
                  onPressed: _speakViCurrent,
                  icon: const Icon(Icons.record_voice_over, color: Colors.green),
                  label: const Text('Phát âm VI'),
                )
              else
                TextButton.icon(
                  onPressed: _speakEnCurrent,
                  icon: const Icon(Icons.volume_up, color: Colors.blue),
                  label: const Text('Phát âm EN'),
                ),
              const SizedBox(height: 8),
              Text(
                'Chạm để lật',
                style: TextStyle(color: Colors.grey[500], fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    if (_cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Flashcards')),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.casino, size: 64, color: Colors.black26),
              SizedBox(height: 16),
              Text('Danh sách từ vựng trống', style: TextStyle(fontSize: 18, color: Colors.black54)),
              Text('Thêm từ vựng mới hoặc kiểm tra dữ liệu của bạn.', style: TextStyle(color: Colors.black38)),
            ],
          ),
        ),
      );
    }

    final card = _cards[_index];

    return Scaffold(
      appBar: AppBar(
        title: Text('Thẻ ${_index + 1}/${_cards.length}'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(_autoplay ? Icons.volume_up : Icons.volume_off),
            tooltip: _autoplay ? 'Tắt Tự động phát âm' : 'Bật Tự động phát âm',
            color: _autoplay ? Theme.of(context).colorScheme.primary : Colors.grey,
            onPressed: _toggleAutoplay,
          ),
          IconButton(
            icon: Icon(_speaking ? Icons.stop_circle_outlined : Icons.volume_up),
            tooltip: _speaking ? 'Dừng phát âm' : 'Phát âm',
            color: _speaking ? Colors.red : Theme.of(context).colorScheme.primary,
            onPressed: _speaking ? _stopSpeak : (_showBack ? _speakViCurrent : _speakEnCurrent),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                final offsetAnimation = Tween<Offset>(
                  begin: const Offset(0.0, 0.1),
                  end: Offset.zero,
                ).animate(animation);

                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  ),
                );
              },
              child: _buildFlashcard(card),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 120,
                  child: FilledButton.icon(
                    onPressed: _prev,
                    icon: const Icon(Icons.arrow_back_ios),
                    label: const Text('Trước'),
                  ),
                ),
                const SizedBox(width: 24),
                SizedBox(
                  width: 120,
                  child: FilledButton.icon(
                    onPressed: _next,
                    icon: const Icon(Icons.arrow_forward_ios),
                    label: const Text('Tiếp'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}