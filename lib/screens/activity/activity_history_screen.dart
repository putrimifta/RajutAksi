import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../models/app_models.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common_widgets.dart';
import '../event/event_detail_screen.dart';
import '../certificate/certificate_screen.dart';

/// Halaman Activity ini menampilkan data BERBEDA tergantung peran aktif user:
/// - Relawan   -> daftar event yang sudah didaftar + status pendaftaran
/// - Organisasi -> daftar event yang sudah dibuat + progres kuota relawan
/// - Sponsor   -> daftar penawaran sponsor yang sudah diajukan + statusnya
class ActivityHistoryScreen extends StatefulWidget {
  const ActivityHistoryScreen({super.key});

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen> {
  late String _role;
  String _filter = 'Semua';

  @override
  void initState() {
    super.initState();
    _role = SupabaseService.instance.currentProfile?.activeRole ?? AppRole.relawan;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(children: [
                      Icon(Icons.public, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text('RajutAksi', style: TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.bold)),
                    ]),
                    const Icon(Icons.search, color: AppColors.textDark),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Riwayat Aktivitas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(_subtitleForRole(_role), style: const TextStyle(color: AppColors.textGrey, fontSize: 12.5)),
                const SizedBox(height: 14),
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filtersForRole(_role).length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final f = _filtersForRole(_role)[i];
                      final selected = f == _filter;
                      return ChoiceChip(
                        label: Text(f),
                        selected: selected,
                        onSelected: (_) => setState(() => _filter = f),
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(color: selected ? Colors.white : AppColors.textDark),
                        backgroundColor: AppColors.surface,
                        side: const BorderSide(color: AppColors.border),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          Expanded(child: _buildBodyForRole(_role)),
        ],
      ),
      ),
    );
  }

  String _subtitleForRole(String role) {
    switch (role) {
      case AppRole.organisasi:
        return 'Pantau event yang sudah kamu buat dan progresnya.';
      case AppRole.sponsor:
        return 'Pantau status penawaran sponsorship yang kamu ajukan.';
      default:
        return 'Pantau kontribusi dan aksi sosial yang kamu ikuti.';
    }
  }

  List<String> _filtersForRole(String role) {
    switch (role) {
      case AppRole.organisasi:
        return ['Semua', 'Published', 'Draft', 'Selesai'];
      case AppRole.sponsor:
        return ['Semua', 'Pending', 'Diterima', 'Ditolak'];
      default:
        return ['Semua', 'Pending', 'Disetujui', 'Selesai'];
    }
  }

  Widget _buildBodyForRole(String role) {
    switch (role) {
      case AppRole.organisasi:
        return _OrganizerActivityList(filter: _filter);
      case AppRole.sponsor:
        return _SponsorActivityList(filter: _filter);
      default:
        return _VolunteerActivityList(filter: _filter);
    }
  }
}

// ---------------------------------------------------------------------------
// RELAWAN
// ---------------------------------------------------------------------------
class _VolunteerActivityList extends StatefulWidget {
  final String filter;
  const _VolunteerActivityList({required this.filter});

  @override
  State<_VolunteerActivityList> createState() => _VolunteerActivityListState();
}

class _VolunteerActivityListState extends State<_VolunteerActivityList> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = SupabaseService.instance.fetchMyRegisteredEventsDetailed();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => setState(() {
        _future = SupabaseService.instance.fetchMyRegisteredEventsDetailed();
      }),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          var items = snap.data!;
          if (widget.filter != 'Semua') {
            final target = {'Pending': 'pending', 'Disetujui': 'approved', 'Selesai': 'completed'}[widget.filter];
            items = items.where((e) => e['status'] == target).toList();
          }
          if (items.isEmpty) {
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              children: const [
                Center(
                  child: Text('Belum ada kegiatan yang kamu ikuti.\nYuk cari kegiatan di halaman Home!',
                      textAlign: TextAlign.center, style: TextStyle(color: AppColors.textGrey)),
                ),
              ],
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i];
              final event = item['event'] as Map<String, dynamic>?;
              if (event == null) return const SizedBox();
              final eventItem = EventItem.fromMap(event);
              final status = item['status'] as String? ?? 'pending';
              if (status == 'completed') {
                final volunteerName = SupabaseService.instance.currentProfile?.fullName ?? 'Relawan';
                return _ActivityCardWithCertificate(
                  title: eventItem.title,
                  subtitle: eventItem.eventDate != null ? DateFormat('d MMM y').format(eventItem.eventDate!) : 'Tanggal belum ditentukan',
                  posterUrl: eventItem.posterUrl,
                  onTapCard: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: eventItem.id))),
                  onTapCertificate: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => CertificateScreen(
                      volunteerName: volunteerName,
                      eventTitle: eventItem.title,
                      eventDate: eventItem.eventDate,
                      organizerName: eventItem.organizerName ?? 'RajutAksi',
                    ),
                  )),
                );
              }
              return GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: eventItem.id))),
                child: _ActivityCard(
                  title: eventItem.title,
                  subtitleIcon: Icons.calendar_today_outlined,
                  subtitle: eventItem.eventDate != null ? DateFormat('d MMM y').format(eventItem.eventDate!) : 'Tanggal belum ditentukan',
                  statusLabel: _statusLabel(status),
                  statusColor: _statusColor(status),
                  posterUrl: eventItem.posterUrl,
                  progressValue: eventItem.progress,
                  progressLeft: 'Kuota terisi',
                  progressRight: '${eventItem.filledCount}/${eventItem.quota} Relawan',
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'approved':
        return 'Disetujui';
      case 'completed':
        return 'Selesai';
      case 'rejected':
        return 'Ditolak';
      default:
        return 'Menunggu';
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'approved':
        return AppColors.primary;
      case 'completed':
        return AppColors.success;
      case 'rejected':
        return AppColors.danger;
      default:
        return AppColors.accent;
    }
  }
}

// ---------------------------------------------------------------------------
// ORGANISASI
// ---------------------------------------------------------------------------
class _OrganizerActivityList extends StatefulWidget {
  final String filter;
  const _OrganizerActivityList({required this.filter});

  @override
  State<_OrganizerActivityList> createState() => _OrganizerActivityListState();
}

class _OrganizerActivityListState extends State<_OrganizerActivityList> {
  late Future<List<EventItem>> _future;

  @override
  void initState() {
    super.initState();
    final uid = SupabaseService.instance.authUser?.id;
    _future = SupabaseService.instance.fetchEvents(organizerId: uid);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => setState(() {
        final uid = SupabaseService.instance.authUser?.id;
        _future = SupabaseService.instance.fetchEvents(organizerId: uid);
      }),
      child: FutureBuilder<List<EventItem>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          var items = snap.data!;
          if (widget.filter != 'Semua') {
            final target = {'Published': 'published', 'Draft': 'draft', 'Selesai': 'done'}[widget.filter];
            items = items.where((e) => e.status == target).toList();
          }
          if (items.isEmpty) {
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              children: const [
                Center(
                  child: Text('Belum ada event yang kamu buat.\nYuk buat event pertamamu dari halaman Home!',
                      textAlign: TextAlign.center, style: TextStyle(color: AppColors.textGrey)),
                ),
              ],
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final e = items[i];
              return GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: e.id))),
                child: _ActivityCard(
                  title: e.title,
                  subtitleIcon: Icons.calendar_today_outlined,
                  subtitle: e.eventDate != null ? DateFormat('d MMM y').format(e.eventDate!) : 'Belum dijadwalkan',
                  statusLabel: _statusLabel(e.status),
                  statusColor: _statusColor(e.status),
                  posterUrl: e.posterUrl,
                  progressValue: e.progress,
                  progressLeft: 'Kuota terisi',
                  progressRight: '${e.filledCount}/${e.quota} Relawan',
                  extraLine: e.needSponsor ? 'Dana: ${formatRupiah(e.collectedFunding)} / ${formatRupiah(e.targetFunding)}' : null,
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'draft':
        return 'Draft';
      case 'done':
        return 'Selesai';
      case 'ongoing':
        return 'Berlangsung';
      default:
        return 'Published';
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'draft':
        return AppColors.textGrey;
      case 'done':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }
}

// ---------------------------------------------------------------------------
// SPONSOR
// ---------------------------------------------------------------------------
class _SponsorActivityList extends StatefulWidget {
  final String filter;
  const _SponsorActivityList({required this.filter});

  @override
  State<_SponsorActivityList> createState() => _SponsorActivityListState();
}

class _SponsorActivityListState extends State<_SponsorActivityList> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = SupabaseService.instance.fetchMySponsorshipsDetailed();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => setState(() {
        _future = SupabaseService.instance.fetchMySponsorshipsDetailed();
      }),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          var items = snap.data!;
          if (widget.filter != 'Semua') {
            final target = {'Pending': 'pending', 'Diterima': 'accepted', 'Ditolak': 'rejected'}[widget.filter];
            items = items.where((e) => e['status'] == target).toList();
          }
          if (items.isEmpty) {
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              children: const [
                Center(
                  child: Text('Belum ada penawaran sponsor yang kamu ajukan.\nCari proyek yang butuh sponsor di halaman Home!',
                      textAlign: TextAlign.center, style: TextStyle(color: AppColors.textGrey)),
                ),
              ],
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i];
              final event = item['event'] as Map<String, dynamic>?;
              if (event == null) return const SizedBox();
              final eventItem = EventItem.fromMap(event);
              final status = item['status'] as String? ?? 'pending';
              final amount = (item['amount'] ?? 0).toDouble();
              final message = item['message'] as String? ?? '';
              final createdAt = DateTime.tryParse(item['created_at'] ?? '');
              return _SponsorshipCard(
                event: eventItem,
                amount: amount,
                message: message,
                createdAt: createdAt,
                statusLabel: _statusLabel(status),
                statusColor: _statusColor(status),
                statusExplanation: _statusExplanation(status),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: eventItem.id))),
              );
            },
          );
        },
      ),
    );
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'accepted':
        return 'Diterima';
      case 'rejected':
        return 'Ditolak';
      default:
        return 'Menunggu';
    }
  }

  String _statusExplanation(String s) {
    switch (s) {
      case 'accepted':
        return 'Penawaran kamu sudah diterima penyelenggara. Terima kasih atas kontribusinya!';
      case 'rejected':
        return 'Penawaran kamu belum bisa diterima kali ini.';
      default:
        return 'Sedang ditinjau oleh penyelenggara. Biasanya diproses dalam 2×24 jam.';
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'accepted':
        return AppColors.success;
      case 'rejected':
        return AppColors.danger;
      default:
        return AppColors.accent;
    }
  }
}

// ---------------------------------------------------------------------------
// KARTU RIWAYAT PENAWARAN SPONSOR — dibuat lebih detail & mudah dipahami:
// nominal ditampilkan lengkap (bukan disingkat), ada tanggal pengajuan,
// dan penjelasan singkat apa arti status saat ini.
// ---------------------------------------------------------------------------
class _SponsorshipCard extends StatelessWidget {
  final EventItem event;
  final double amount;
  final String message;
  final DateTime? createdAt;
  final String statusLabel;
  final Color statusColor;
  final String statusExplanation;
  final VoidCallback onTap;

  const _SponsorshipCard({
    required this.event,
    required this.amount,
    required this.message,
    required this.createdAt,
    required this.statusLabel,
    required this.statusColor,
    required this.statusExplanation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onTap,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  child: event.posterUrl != null
                      ? Image.network(event.posterUrl!, height: 110, width: double.infinity, fit: BoxFit.cover)
                      : Container(height: 110, width: double.infinity, color: AppColors.primaryLight,
                          child: const Icon(Icons.image_outlined, size: 30, color: AppColors.primary)),
                ),
                Positioned(top: 10, left: 10, child: AppBadge(text: statusLabel, color: statusColor)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: onTap,
                  child: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                const SizedBox(height: 2),
                Text(
                  '${event.categoryLabel} • ${event.sdgCategory}',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textGrey),
                ),
                const SizedBox(height: 12),
                // Kotak nominal — dibuat menonjol supaya sponsor langsung
                // tahu berapa yang mereka tawarkan tanpa harus menghitung sendiri.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Nilai Penawaran Anda', style: TextStyle(fontSize: 12, color: AppColors.primaryDark)),
                      Text(formatRupiahFull(amount), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                if (createdAt != null)
                  Row(children: [
                    const Icon(Icons.event_note_outlined, size: 13, color: AppColors.textGrey),
                    const SizedBox(width: 4),
                    Text('Diajukan ${DateFormat('d MMM y', 'id_ID').format(createdAt!)}', style: const TextStyle(fontSize: 11.5, color: AppColors.textGrey)),
                  ]),
                if (message.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('"$message"', style: const TextStyle(fontSize: 12, color: AppColors.textGrey, fontStyle: FontStyle.italic), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 14, color: statusColor),
                      const SizedBox(width: 6),
                      Expanded(child: Text(statusExplanation, style: TextStyle(fontSize: 11.5, color: statusColor))),
                    ],
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

// ---------------------------------------------------------------------------
// KARTU AKTIVITAS + TOMBOL CETAK SERTIFIKAT (khusus relawan yang statusnya "Selesai")
// ---------------------------------------------------------------------------
class _ActivityCardWithCertificate extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? posterUrl;
  final VoidCallback onTapCard;
  final VoidCallback onTapCertificate;

  const _ActivityCardWithCertificate({
    required this.title,
    required this.subtitle,
    this.posterUrl,
    required this.onTapCard,
    required this.onTapCertificate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onTapCard,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  child: posterUrl != null
                      ? Image.network(posterUrl!, height: 120, width: double.infinity, fit: BoxFit.cover)
                      : Container(height: 120, width: double.infinity, color: AppColors.primaryLight,
                          child: const Icon(Icons.image_outlined, size: 32, color: AppColors.primary)),
                ),
                const Positioned(top: 10, left: 10, child: _SelesaiBadge()),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: onTapCard,
                  child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textGrey),
                  const SizedBox(width: 4),
                  Expanded(child: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textGrey))),
                ]),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onTapCertificate,
                    icon: const Icon(Icons.workspace_premium_outlined, size: 18),
                    label: const Text('Cetak Sertifikat'),
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

class _SelesaiBadge extends StatelessWidget {
  const _SelesaiBadge();

  @override
  Widget build(BuildContext context) {
    return AppBadge(text: 'Selesai', color: AppColors.success);
  }
}


class _ActivityCard extends StatelessWidget {
  final String title;
  final IconData subtitleIcon;
  final String subtitle;
  final String statusLabel;
  final Color statusColor;
  final String? posterUrl;
  final double? progressValue;
  final String? progressLeft;
  final String? progressRight;
  final String? extraLine;

  const _ActivityCard({
    required this.title,
    required this.subtitleIcon,
    required this.subtitle,
    required this.statusLabel,
    required this.statusColor,
    this.posterUrl,
    this.progressValue,
    this.progressLeft,
    this.progressRight,
    this.extraLine,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: posterUrl != null
                    ? Image.network(posterUrl!, height: 120, width: double.infinity, fit: BoxFit.cover)
                    : Container(height: 120, width: double.infinity, color: AppColors.primaryLight,
                        child: const Icon(Icons.image_outlined, size: 32, color: AppColors.primary)),
              ),
              Positioned(top: 10, left: 10, child: AppBadge(text: statusLabel, color: statusColor)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(subtitleIcon, size: 12, color: AppColors.textGrey),
                  const SizedBox(width: 4),
                  Expanded(child: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textGrey))),
                ]),
                if (extraLine != null) ...[
                  const SizedBox(height: 4),
                  Text(extraLine!, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
                ],
                if (progressValue != null) ...[
                  const SizedBox(height: 12),
                  AppProgressBar(value: progressValue!),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(progressLeft ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
                      Text(progressRight ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
