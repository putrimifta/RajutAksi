import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../models/app_models.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common_widgets.dart';
import '../event/event_detail_screen.dart';
import '../activity/activity_history_screen.dart';
import '../../widgets/notification_bell.dart';
import '../profile/profile_screen.dart';
import 'sponsor_list_screen.dart';

class HomeSponsorScreen extends StatefulWidget {
  const HomeSponsorScreen({super.key});

  @override
  State<HomeSponsorScreen> createState() => _HomeSponsorScreenState();
}

class _HomeSponsorScreenState extends State<HomeSponsorScreen> {
  late Future<List<EventItem>> _future;
  late Future<double> _myContributionFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = SupabaseService.instance.fetchEvents(onlyNeedSponsor: true);
    _myContributionFuture = SupabaseService.instance.fetchMyAcceptedSponsorshipTotal();
  }

  @override
  Widget build(BuildContext context) {
    final profile = SupabaseService.instance.currentProfile;
    final name = profile?.fullName ?? 'Mitra';

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => setState(_load),
        child: ListView(
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
                Row(children: [
                  const NotificationBell(),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
                    child: AppAvatar(url: profile?.avatarUrl, name: name, radius: 16),
                  ),
                ]),
              ],
            ),
            const SizedBox(height: 18),
            Text('Halo, $name!', style: const TextStyle(color: AppColors.textGrey)),
            const Text('Mari wujudkan aksi nyata hari ini.', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 18),
            // Kartu ini sekarang menampilkan data MILIK SPONSOR YANG SEDANG LOGIN,
            // bukan angka gabungan semua sponsor (yang sebelumnya membingungkan
            // karena terlihat seperti pencapaian pribadi padahal bukan).
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(18)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Kontribusi Saya', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 4),
                  FutureBuilder<double>(
                    future: _myContributionFuture,
                    builder: (context, snap) {
                      final total = snap.data ?? 0;
                      return Text(formatRupiahFull(total),
                          style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold));
                    },
                  ),
                  const SizedBox(height: 6),
                  const Text('Dari penawaran sponsor yang sudah diterima', style: TextStyle(color: Colors.white70, fontSize: 11.5)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FutureBuilder<List<EventItem>>(
                    future: _future,
                    builder: (context, snap) {
                      final count = snap.data?.length ?? 0;
                      return _statCard('Proyek Butuh Sponsor', '$count', Icons.groups_2_outlined);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ActivityHistoryScreen())),
                    child: _statCard('Lihat Riwayat Penawaran', 'Activity →', Icons.receipt_long_outlined),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Proyek Butuh Sponsor', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SponsorListScreen()),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Text('Lihat Semua', style: TextStyle(color: AppColors.primary, fontSize: 13)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Ini daftar kegiatan sosial yang butuh dana sponsor. Ketuk salah satu untuk lihat detail dan ajukan penawaran.',
              style: TextStyle(color: AppColors.textGrey, fontSize: 12),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<EventItem>>(
              future: _future,
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                final events = snap.data!;
                if (events.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text('Belum ada proyek yang membutuhkan sponsor saat ini.', style: TextStyle(color: AppColors.textGrey)),
                  );
                }
                // Tampilkan preview maksimal 3 di Home, sisanya lihat di "Lihat Semua"
                final preview = events.take(3).toList();
                return Column(children: preview.map((e) => SponsorProjectCard(event: e)).toList());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: AppColors.textGrey, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
        ],
      ),
    );
  }
}

/// Kartu proyek yang butuh sponsor. Bahasa & susunan info dibuat lebih jelas:
/// judul dulu, lalu progres dana dengan angka LENGKAP (bukan disingkat) supaya
/// sponsor tahu persis berapa yang sudah terkumpul dan berapa sisa target.
class SponsorProjectCard extends StatelessWidget {
  final EventItem event;
  const SponsorProjectCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final remaining = (event.targetFunding - event.collectedFunding).clamp(0, double.infinity);
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: event.id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: event.posterUrl != null
                    ? Image.network(event.posterUrl!, height: 140, width: double.infinity, fit: BoxFit.cover)
                    : Container(height: 140, color: AppColors.primaryLight, child: const Icon(Icons.image_outlined, size: 36, color: AppColors.primary)),
              ),
              Positioned(top: 10, left: 10, child: AppBadge(text: 'Butuh Sponsor', color: AppColors.accent)),
            ]),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5)),
                  const SizedBox(height: 4),
                  Row(children: [
                    AppBadge(text: event.sdgCategory, color: AppColors.primaryLight, textColor: AppColors.primaryDark),
                    const SizedBox(width: 6),
                    AppBadge(text: event.categoryLabel, color: AppColors.chipLingkungan, textColor: AppColors.primaryDark),
                  ]),
                  const SizedBox(height: 10),
                  Text(event.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textGrey, fontSize: 12.5)),
                  const SizedBox(height: 14),
                  AppProgressBar(value: event.fundingProgress),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Sudah terkumpul', style: TextStyle(fontSize: 10.5, color: AppColors.textGrey)),
                          Text(formatRupiahFull(event.collectedFunding), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Masih dibutuhkan', style: TextStyle(fontSize: 10.5, color: AppColors.textGrey)),
                          Text(formatRupiahFull(remaining), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.accent)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: event.id, openSponsorForm: true))),
                      child: const Text('Ajukan Sponsor'),
                    ),
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
