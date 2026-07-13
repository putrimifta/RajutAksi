import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/app_theme.dart';
import '../../models/app_models.dart';
import '../../services/supabase_service.dart';
import '../event/event_detail_screen.dart';

/// Notifikasi ASLI dari tabel `notifications`, otomatis terisi lewat trigger
/// database (pendaftaran, sponsorship, chat). Dilengkapi realtime supaya
/// notifikasi baru langsung nampil tanpa perlu refresh manual.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<NotificationItem>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = SupabaseService.instance.fetchNotifications();
  }

  Future<void> _onTapNotification(NotificationItem n) async {
    if (!n.isRead) {
      await SupabaseService.instance.markNotificationRead(n.id);
      setState(_load);
    }
    if (n.relatedEventId != null && mounted) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: n.relatedEventId!)));
    }
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'registration':
      case 'registration_status':
        return Icons.volunteer_activism_outlined;
      case 'sponsorship':
      case 'sponsorship_status':
        return Icons.workspace_premium_outlined;
      case 'message':
        return Icons.chat_bubble_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          TextButton(
            onPressed: () async {
              await SupabaseService.instance.markAllNotificationsRead();
              setState(_load);
            },
            child: const Text('Tandai semua dibaca', style: TextStyle(color: AppColors.primary, fontSize: 12.5)),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => setState(_load),
          child: FutureBuilder<List<NotificationItem>>(
            future: _future,
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final items = snap.data!;
              if (items.isEmpty) {
                return ListView(
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: Text('Belum ada notifikasi. Aktivitas terbaru kamu akan muncul di sini.',
                            textAlign: TextAlign.center, style: TextStyle(color: AppColors.textGrey)),
                      ),
                    ),
                  ],
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final n = items[i];
                  return InkWell(
                    onTap: () => _onTapNotification(n),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: n.isRead ? AppColors.surface : AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(radius: 18, backgroundColor: AppColors.primary.withOpacity(0.12), child: Icon(_iconFor(n.type), color: AppColors.primary, size: 18)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(n.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                                const SizedBox(height: 2),
                                Text(n.body, style: const TextStyle(fontSize: 12.5, color: AppColors.textGrey), maxLines: 2, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Text(timeago.format(n.createdAt, locale: 'id'), style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
                              ],
                            ),
                          ),
                          if (!n.isRead)
                            Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 4), decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
