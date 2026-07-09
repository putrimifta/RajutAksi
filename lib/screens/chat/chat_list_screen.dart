import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/app_theme.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common_widgets.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  bool _isSearching = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _future = SupabaseService.instance.fetchConversations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _future = SupabaseService.instance.fetchConversations();
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  List<Map<String, dynamic>> _applySearch(List<Map<String, dynamic>> conversations, String? uid) {
    if (_searchQuery.trim().isEmpty) return conversations;
    final q = _searchQuery.toLowerCase();
    return conversations.where((c) {
      final isUserA = c['user_a'] != null && c['user_a']['id'] == uid;
      final other = isUserA ? c['user_b'] : c['user_a'];
      final name = (other?['full_name'] ?? '').toString().toLowerCase();
      return name.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final uid = SupabaseService.instance.authUser?.id;
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!_isSearching) ...[
                  const Row(children: [
                    Icon(Icons.public, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text('RajutAksi', style: TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.bold)),
                  ]),
                  Row(children: [
                    IconButton(
                      icon: const Icon(Icons.search, color: AppColors.textDark),
                      onPressed: _toggleSearch,
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: AppColors.textDark),
                      onSelected: (value) {
                        if (value == 'refresh') {
                          _reload();
                        } else if (value == 'read_all') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Semua pesan ditandai terbaca')),
                          );
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'refresh', child: Text('Muat ulang')),
                        PopupMenuItem(value: 'read_all', child: Text('Tandai semua dibaca')),
                      ],
                    ),
                  ]),
                ] else
                  Expanded(
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
                          onPressed: _toggleSearch,
                        ),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            onChanged: (value) => setState(() => _searchQuery = value),
                            decoration: const InputDecoration(
                              hintText: 'Cari percakapan...',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.close, color: AppColors.textDark),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Pesan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Terhubung dengan sesama penggerak perubahan.', style: TextStyle(color: AppColors.textGrey, fontSize: 12.5)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _future,
              builder: (context, snap) {
                if (!snap.hasData) return const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator()));
                final conversations = _applySearch(snap.data!, uid);
                if (conversations.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Center(
                      child: Text(
                        _searchQuery.isNotEmpty
                            ? 'Tidak ada percakapan dengan nama "$_searchQuery"'
                            : 'Belum ada percakapan. Mulai chat dari halaman event atau profil.',
                        style: const TextStyle(color: AppColors.textGrey),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return Column(
                  children: conversations.map((c) {
                    final isUserA = c['user_a'] != null && c['user_a']['id'] == uid;
                    final other = isUserA ? c['user_b'] : c['user_a'];
                    final name = other?['full_name'] ?? 'Pengguna';
                    final avatar = other?['avatar_url'];
                    final lastMsg = c['last_message'] ?? 'Mulai percakapan...';
                    final lastAt = c['last_message_at'] != null ? DateTime.tryParse(c['last_message_at']) : null;
                    return GestureDetector(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ChatDetailScreen(conversationId: c['id'].toString(), otherName: name, otherAvatar: avatar))),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                        child: Row(
                          children: [
                            AppAvatar(url: avatar, name: name, radius: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      if (lastAt != null)
                                        Text(timeago.format(lastAt, locale: 'id'), style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(lastMsg, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textGrey, fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}