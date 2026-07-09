import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../models/app_models.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common_widgets.dart';
import '../event/create_event_screen.dart';
import '../event/all_managed_events_screen.dart';

class HomeOrganizationScreen extends StatefulWidget {
  const HomeOrganizationScreen({super.key});

  @override
  State<HomeOrganizationScreen> createState() => _HomeOrganizationScreenState();
}

class _HomeOrganizationScreenState extends State<HomeOrganizationScreen> {
  late Future<List<EventItem>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final uid = SupabaseService.instance.authUser?.id;
    _future = SupabaseService.instance.fetchEvents(organizerId: uid);
  }

  @override
  Widget build(BuildContext context) {
    final profile = SupabaseService.instance.currentProfile;
    final name = profile?.fullName ?? 'Organisasi';

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
                const Icon(Icons.notifications_none, color: AppColors.textDark),
              ],
            ),
            const SizedBox(height: 16),
            Text('Selamat datang, $name', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Mari terus merajut aksi untuk keberlanjutan bumi melalui kolaborasi yang nyata dan berdampak.',
                style: TextStyle(color: AppColors.textGrey, fontSize: 12.5)),
            const SizedBox(height: 16),
            FutureBuilder<List<EventItem>>(
              future: _future,
              builder: (context, snap) {
                final events = snap.data ?? [];
                final totalRelawan = events.fold<int>(0, (p, e) => p + e.filledCount);
                return GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.8,
                  children: [
                    _statCard('TOTAL EVENT', '${events.length}'),
                    _statCard('RELAWAN AKTIF', '$totalRelawan'),
                    _statCard('SDG TERPENUHI', '6'),
                    _statCard('RATING ORGANISASI', '4.9 ★'),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(18)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Siap memulai dampak baru?', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Rancang kampanye Anda dan temukan relawan yang tepat.', style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary),
                      onPressed: () async {
                        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateEventScreen()));
                        setState(_load);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Buat Event Baru'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Event yang Dikelola', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AllManagedEventsScreen())),
                  child: const Row(children: [
                    Text('Lihat Semua', style: TextStyle(color: AppColors.primary, fontSize: 13)),
                    Icon(Icons.arrow_forward, size: 14, color: AppColors.primary),
                  ]),
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
                    child: Text('Anda belum membuat event. Yuk mulai buat event pertama!', style: TextStyle(color: AppColors.textGrey)),
                  );
                }
                return Column(children: events.map((e) => ManagedEventCard(event: e)).toList());
              },
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Aktivitas Terkini', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  _ActivityRow(icon: Icons.person_add_alt_outlined, text: 'Andi Pratama baru saja mendaftar sebagai relawan.', time: '2 menit yang lalu'),
                  SizedBox(height: 10),
                  _ActivityRow(icon: Icons.chat_bubble_outline, text: 'Ada pesan baru di grup diskusi koordinasi lapangan.', time: '15 menit yang lalu'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textGrey, fontSize: 10, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final String time;
  const _ActivityRow({required this.icon, required this.text, required this.time});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(radius: 14, backgroundColor: AppColors.primaryLight, child: Icon(icon, size: 14, color: AppColors.primaryDark)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text, style: const TextStyle(fontSize: 12.5)),
              Text(time, style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
            ],
          ),
        ),
      ],
    );
  }
}