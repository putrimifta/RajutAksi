import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../models/app_models.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common_widgets.dart';
import '../event/event_detail_screen.dart';
import 'sponsor_list_screen.dart';

class HomeSponsorScreen extends StatefulWidget {
  const HomeSponsorScreen({super.key});

  @override
  State<HomeSponsorScreen> createState() => _HomeSponsorScreenState();
}

class _HomeSponsorScreenState extends State<HomeSponsorScreen> {
  late Future<List<EventItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = SupabaseService.instance.fetchEvents(onlyNeedSponsor: true);
  }

  @override
  Widget build(BuildContext context) {
    final profile = SupabaseService.instance.currentProfile;
    final name = profile?.fullName ?? 'Mitra';

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => setState(() {
          _future = SupabaseService.instance.fetchEvents(onlyNeedSponsor: true);
        }),
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
                  const Icon(Icons.notifications_none, color: AppColors.textDark),
                  const SizedBox(width: 10),
                  AppAvatar(url: profile?.avatarUrl, name: name, radius: 16),
                ]),
              ],
            ),
            const SizedBox(height: 18),
            Text('Halo, $name!', style: const TextStyle(color: AppColors.textGrey)),
            const Text('Mari wujudkan aksi nyata hari ini.', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(18)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Penyaluran', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 4),
                  FutureBuilder<List<EventItem>>(
                    future: _future,
                    builder: (context, snap) {
                      final total = (snap.data ?? []).fold<double>(0, (p, e) => p + e.collectedFunding);
                      return Text(formatRupiah(total),
                          style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold));
                    },
                  ),
                  const SizedBox(height: 4),
                  const Row(children: [
                    Icon(Icons.trending_up, color: Colors.white70, size: 16),
                    SizedBox(width: 4),
                    Text('+12% bulan ini', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 14),
            FutureBuilder<List<EventItem>>(
              future: _future,
              builder: (context, snap) {
                final count = snap.data?.length ?? 0;
                return Row(
                  children: [
                    Expanded(child: _statCard('Proyek Aktif', '$count', Icons.groups_2_outlined)),
                    const SizedBox(width: 12),
                    Expanded(child: _statCard('Dampak SDG', '82%', Icons.verified_outlined)),
                  ],
                );
              },
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
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Optimalkan Dampak Anda', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                  const SizedBox(height: 4),
                  const Text('Proyek dengan label "Urgent" membutuhkan pendanaan cepat untuk menjaga keberlanjutan operasional.',
                      style: TextStyle(color: AppColors.textGrey, fontSize: 12.5)),
                  const SizedBox(height: 8),
                  Row(children: const [
                    Text('Pelajari Kriteria', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 14, color: AppColors.primary),
                  ]),
                ],
              ),
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
          Text(label.toUpperCase(), style: const TextStyle(color: AppColors.textGrey, fontSize: 10.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
        ],
      ),
    );
  }
}

class SponsorProjectCard extends StatelessWidget {
  final EventItem event;
  const SponsorProjectCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
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
                Row(children: [
                  AppBadge(text: event.sdgCategory, color: AppColors.primaryLight, textColor: AppColors.primaryDark),
                  const SizedBox(width: 6),
                  AppBadge(text: event.categoryLabel.toUpperCase(), color: AppColors.chipLingkungan, textColor: AppColors.primaryDark),
                ]),
                const SizedBox(height: 8),
                Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5)),
                const SizedBox(height: 4),
                Text(event.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textGrey, fontSize: 12.5)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tercapai: ${formatRupiah(event.collectedFunding)}', style: const TextStyle(fontSize: 11.5, color: AppColors.textGrey)),
                    Text('Target: ${formatRupiah(event.targetFunding)}', style: const TextStyle(fontSize: 11.5, color: AppColors.textGrey)),
                  ],
                ),
                const SizedBox(height: 6),
                AppProgressBar(value: event.fundingProgress),
                const SizedBox(height: 12),
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
    );
  }
}