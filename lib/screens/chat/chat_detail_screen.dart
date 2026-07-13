import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common_widgets.dart';

class ChatDetailScreen extends StatefulWidget {
  final String conversationId;
  final String otherName;
  final String? otherAvatar;
  const ChatDetailScreen({super.key, required this.conversationId, required this.otherName, this.otherAvatar});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  late Stream<List<Map<String, dynamic>>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = SupabaseService.instance.messageStream(widget.conversationId);
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    await SupabaseService.instance.sendMessage(conversationId: widget.conversationId, content: text);
  }

  @override
  Widget build(BuildContext context) {
    final myId = SupabaseService.instance.authUser?.id;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            AppAvatar(url: widget.otherAvatar, name: widget.otherName, radius: 18),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.otherName, style: const TextStyle(fontSize: 15, color: AppColors.primaryDark)),
                const Text('Active now', style: TextStyle(fontSize: 11, color: AppColors.success)),
              ],
            ),
          ],
        ),
        actions: const [
          Icon(Icons.call_outlined, color: AppColors.primary),
          SizedBox(width: 16),
          Icon(Icons.more_vert, color: AppColors.primary),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _stream,
                builder: (context, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());

                  // Urutkan pesan dari yang paling lama ke paling baru
                  final messages = List<Map<String, dynamic>>.from(snap.data!)
                    ..sort((a, b) {
                      final ta = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
                      final tb = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now();
                      return ta.compareTo(tb);
                    });

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollCtrl.hasClients) {
                      _scrollCtrl.animateTo(
                        _scrollCtrl.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                      );
                    }
                  });

                  return ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, i) {
                      final m = messages[i];
                      final mine = m['sender_id'] == myId;
                      final time = DateTime.tryParse(m['created_at'] ?? '') ?? DateTime.now();
                      return Align(
                        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                          decoration: BoxDecoration(
                            color: mine ? AppColors.primary : AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: mine ? null : Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(m['content'] ?? '', style: TextStyle(color: mine ? Colors.white : AppColors.textDark)),
                              const SizedBox(height: 4),
                              Text(DateFormat('HH:mm').format(time),
                                  style: TextStyle(fontSize: 10, color: mine ? Colors.white70 : AppColors.textGrey)),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.add_circle_outline, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      decoration: const InputDecoration(hintText: 'Type a message...', contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 18), onPressed: _send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
