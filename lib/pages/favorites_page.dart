import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/vocab.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import 'detail_page.dart';
import '../services/vocab_service.dart';

class FavoritesPage extends StatefulWidget {
  final List<Vocab>? favorites;
  const FavoritesPage({Key? key, this.favorites}) : super(key: key);

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final StorageService _storage = StorageService();
  final VocabService _vocabService = VocabService();
  List<Vocab> _favorites = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.favorites != null) {
      _favorites = List<Vocab>.from(widget.favorites!)
        ..sort((a, b) => a.en.toLowerCase().compareTo(b.en.toLowerCase()));
      _loading = false;
    } else {
      _loadFavoritesForUser();
    }
  }

  Future<void> _loadFavoritesForUser() async {
    setState(() {
      _loading = true;
      _favorites = [];
    });

    final auth = context.read<AuthService>();
    final username = auth.currentUsername;

    final favIds = await _storage.loadFavorites(username: username);

    final userVocabs = await _storage.loadUserVocab();
    final found = <Vocab>[];

    for (final id in favIds) {
      final idx = userVocabs.indexWhere((v) => v.id == id);
      if (idx >= 0) found.add(userVocabs[idx]);
    }

    try {
      final base = await _vocabService.loadFromAssets('assets/data/vocabulary_en_vi.json');
      for (final id in favIds) {
        if (found.any((v) => v.id == id)) continue;
        final idx = base.indexWhere((v) => v.id == id);
        if (idx >= 0) found.add(base[idx]);
      }
    } catch (_) {}

    found.sort((a, b) => a.en.toLowerCase().compareTo(b.en.toLowerCase()));

    if (!mounted) return;
    setState(() {
      _favorites = found;
      _loading = false;
    });
  }

  Future<void> _toggleFavorite(Vocab v) async {
    final auth = context.read<AuthService>();
    final username = auth.currentUsername;
    final ids = await _storage.loadFavorites(username: username);
    final set = ids.toSet();

    if (set.contains(v.id)) {
      set.remove(v.id);
      if (mounted) {
        setState(() {
          _favorites.removeWhere((x) => x.id == v.id);
        });
      }
    } else {
      set.add(v.id);
    }

    await _storage.saveFavorites(set.toList(), username: username);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã xóa "${v.en}" khỏi danh sách yêu thích.')));
    }
  }

  Widget _buildEmptyState(AuthService auth) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.favorite_border,
            size: 80,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 24),
          const Text(
            'Chưa có từ vựng yêu thích',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              auth.isLoggedIn
                  ? 'Nhấn vào biểu tượng trái tim ❤️ bên cạnh từ ở trang chủ để thêm vào danh sách này.'
                  : 'Đăng nhập hoặc nhấn vào biểu tượng trái tim ❤️ ở trang chủ để lưu từ yêu thích của bạn.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final accountText = auth.isLoggedIn ? '(${auth.currentUsername})' : '(Khách)';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Từ Yêu Thích'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24.0),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              accountText,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _favorites.isEmpty
          ? _buildEmptyState(auth)
          : ListView.separated(
        itemCount: _favorites.length,
        separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
        itemBuilder: (context, i) {
          final v = _favorites[i];
          return ListTile(
            title: Text(
              v.en,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              v.vi,
              style: const TextStyle(color: Colors.black87),
            ),
            leading: const Icon(Icons.star, color: Colors.amber),
            trailing: IconButton(
              icon: const Icon(Icons.favorite, color: Colors.redAccent),
              onPressed: () => _toggleFavorite(v),
              tooltip: 'Bỏ yêu thích',
            ),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailPage(
                    vocab: v,
                    isFavorite: true,
                    onToggleFav: () async {
                      await _toggleFavorite(v);
                      if (mounted) Navigator.of(context).pop();
                    },
                  ),
                ),
              );
              if (widget.favorites == null && mounted) await _loadFavoritesForUser();
            },
          );
        },
      ),
    );
  }
}