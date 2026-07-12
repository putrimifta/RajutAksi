import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/app_theme.dart';
import '../../models/app_models.dart';
import '../../services/supabase_service.dart';
import '../event/event_detail_screen.dart';

/// RajutAksi belum punya tabel "notifications" tersendiri di database, jadi
/// halaman ini merangkum notifikasi secara pintar dari data yang sudah ada:
/// perubahan status pendaftaran relawan, status tawaran sponsor, dan pesan chat.
/// Ini menghindari perlu migrasi database baru sekaligus tetap terasa "hidup".
class _NotificationEntry {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final DateTime time;
  final VoidCallback? onTap;
  _NotificationEntry({required this.icon, required this.color, required this.title, required this.subtitle, required this.time, this.onTap});
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<_NotificationEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = _buildNotifications();
  }

  Future<List<_NotificationEntry>> _buildNotifications() async {
    final service = SupabaseService.instance;
    final role = service.currentProfile?.activeRole ?? AppRole.relawan;
    final entries = <_NotificationEntry>[];

    try {
      if (role == AppRole.relawan) {
        final regs = await service.fetchMyRegisteredEventsDetailed();
        for (final r in regs) {
          final event = r['event'] as Map<String, dynamic>?;
          if (event == null) continue;
          final eventItem = EventItem.fromMap(event);
          final status = r['status'] as String? ?? 'pending';
          if (status == 'pending') continue; // belum ada perkembangan, tidak perlu dinotifikasi
          entries.add(_NotificationEntry(
            icon: status == 'completed' ? Icons.workspace_premium_outlined : Icons.check_circle_outline,
            color: status == 'completed' ? AppColors.success : AppColors.primary,
            title: status == 'completed' ? 'Kegiatan selesai, sertifikat siap!' : 'Pendaftaran disetujui',
            subtitle: eventItem.title,
            time: DateTime.tryParse(r['registered_at'] ?? '') ?? DateTime.now(),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: eventItem.id))),
          ));
        }
      } else if (role == AppRole.sponsor) {
        final sponsorships = await service.fetchMySponsorshipsDetailed();
        for (final s in sponsorships) {
          final event = s['event'] as Map<String, dynamic>?;
          if (event == null) continue;
          final eventItem = EventItem.fromMap(event);
          final status = s['status'] as String? ?? 'pending';
          if (status == 'pending') continue;
          entries.add(_NotificationEntry(
            icon: status == 'accepted' ? Icons.check_circle_outline : Icons.cancel_outlined,
            color: status == 'accepted' ? AppColors.success : AppColors.danger,
            title: status == 'accepted' ? 'Tawaran sponsor diterima' : 'Tawaran sponsor ditolak',
            subtitle: eventItem.title,
            time: DateTime.tryParse(s['created_at'] ?? '') ?? DateTime.now(),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: eventItem.id))),
          ));
        }
      } else if (role == AppRole.organisasi) {
        final uid = service.authUser?.id;
        final events = await service.fetchEvents(organizerId: uid);
        for (final e in events) {
          if (e.filledCount > 0) {
            entries.add(_NotificationEntry(
              icon: Icons.person_add_alt_outlined,
              color: AppColors.primary,
              title: '${e.filledCount} relawan mendaftar',
              subtitle: e.title,
              time: e.createdAt,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: e.id))),
            ));
          }
          if (e.needSponsor && e.collectedFunding > 0) {
            entries.add(_NotificationEntry(
              icon: Icons.workspace_premium_outlined,
              color: AppColors.accent,
              title: 'Ada dana sponsor masuk',
              subtitle: e.title,
              time: e.createdAt,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: e.id))),
            ));
          }
        }
      }

      // Pesan chat terbaru juga dianggap notifikasi
      final conversations = await service.fetchConversations();
      final uid = service.authUser?.id;
      for (final c in conversations) {
        final lastMsg = c['last_message'] as String?;
        if (lastMsg == null || lastMsg.isEmpty) continue;
        final isUserA = c['user_a'] != null && c['user_a']['id'] == uid;
        final other = isUserA ? c['user_b'] : c['user_a'];
        final name = other?['full_name'] ?? 'Seseorang';
        entries.add(_NotificationEntry(
          icon: Icons.chat_bubble_outline,
          color: AppColors.primary,
          title: 'Pesan baru dari $name',
          subtitle: lastMsg,
          time: DateTime.tryParse(c['last_message_at'] ?? '') ?? DateTime.now(),
        ));
      }
    } catch (_) {
      // Kalau salah satu sumber gagal diambil, tetap tampilkan yang berhasil
    }

    entries.sort((a, b) => b.time.compareTo(a.time));
    return entries.take(30).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Notifikasi')),
      body: SafeArea(
        child: FutureBuilder<List<_NotificationEntry>>(
          future: _future,
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final entries = snap.data!;
            if (entries.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: Text('Belum ada notifikasi. Aktivitas terbaru kamu akan muncul di sini.',
                      textAlign: TextAlign.center, style: TextStyle(color: AppColors.textGrey)),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final n = entries[i];
                return InkWell(
                  onTap: n.onTap,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(radius: 18, backgroundColor: n.color.withOpacity(0.12), child: Icon(n.icon, color: n.color, size: 18)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                              const SizedBox(height: 2),
                              Text(n.subtitle, style: const TextStyle(fontSize: 12.5, color: AppColors.textGrey), maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text(timeago.format(n.time, locale: 'id'), style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
