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
  final _searchCtrl = TextEditingController();
  bool _searching = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = SupabaseService.instance.fetchConversations();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _future = SupabaseService.instance.fetchConversations();
    });
  }

  Future<void> _markAllRead() async {
    await SupabaseService.instance.markAllConversationsRead();
    if (!mounted) return;
    _reload();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Semua percakapan ditandai sudah dibaca')),
    );
  }

  Future<void> _openConversation(Map<String, dynamic> c, String name, String? avatar) async {
    await SupabaseService.instance.markConversationRead(c['id'].toString());
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ChatDetailScreen(conversationId: c['id'].toString(), otherName: name, otherAvatar: avatar)));
    if (mounted) _reload();
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
                const Row(children: [
                  Icon(Icons.public, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text('RajutAksi', style: TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.bold)),
                ]),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(_searching ? Icons.close : Icons.search, color: AppColors.textDark),
                      onPressed: () => setState(() {
                        _searching = !_searching;
                        if (!_searching) {
                          _searchCtrl.clear();
                          _query = '';
                        }
                      }),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: AppColors.textDark),
                      onSelected: (value) {
                        if (value == 'reload') _reload();
                        if (value == 'mark_read') _markAllRead();
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'reload',
                          child: Row(children: [Icon(Icons.refresh, size: 18), SizedBox(width: 10), Text('Muat Ulang')]),
                        ),
                        PopupMenuItem(
                          value: 'mark_read',
                          child: Row(children: [Icon(Icons.done_all, size: 18), SizedBox(width: 10), Text('Tandai Semua Dibaca')]),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            if (_searching) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Cari nama...',
                  prefixIcon: Icon(Icons.search, size: 20),
                ),
                onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              ),
            ],
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
                var conversations = snap.data!;

                if (_query.isNotEmpty) {
                  conversations = conversations.where((c) {
                    final isUserA = c['user_a'] != null && c['user_a']['id'] == uid;
                    final other = isUserA ? c['user_b'] : c['user_a'];
                    final name = (other?['full_name'] ?? '').toString().toLowerCase();
                    return name.contains(_query);
                  }).toList();
                }

                if (conversations.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Center(
                      child: Text(
                        _query.isNotEmpty ? 'Tidak ada percakapan dengan nama "$_query".' : 'Belum ada percakapan. Mulai chat dari halaman event atau profil.',
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
                    final lastReadRaw = isUserA ? c['last_read_a'] : c['last_read_b'];
                    final lastRead = lastReadRaw != null ? DateTime.tryParse(lastReadRaw) : null;
                    final isUnread = lastAt != null && (lastRead == null || lastAt.isAfter(lastRead));

                    return GestureDetector(
                      onTap: () => _openConversation(c, name, avatar),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isUnread ? AppColors.primary : AppColors.border, width: isUnread ? 1.4 : 1),
                        ),
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
                                  Text(
                                    lastMsg,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isUnread ? AppColors.textDark : AppColors.textGrey,
                                      fontSize: 13,
                                      fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isUnread) ...[
                              const SizedBox(width: 8),
                              Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
                            ],
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