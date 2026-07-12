import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../models/app_models.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common_widgets.dart';
import '../event/event_detail_screen.dart';
import '../event/all_events_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';

class HomeVolunteerScreen extends StatefulWidget {
  const HomeVolunteerScreen({super.key});

  @override
  State<HomeVolunteerScreen> createState() => _HomeVolunteerScreenState();
}

class _HomeVolunteerScreenState extends State<HomeVolunteerScreen> {
  String _category = 'Semua';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();
  late Future<List<EventItem>> _future;
  final _categories = ['Semua', 'Lingkungan', 'Pendidikan', 'Kesehatan', 'Sosial'];

  @override
  void initState() {
    super.initState();
    _future = SupabaseService.instance.fetchEvents(category: _category);
  }

  void _reload() {
    setState(() {
      _future = SupabaseService.instance.fetchEvents(category: _category);
    });
  }

  List<EventItem> _applySearch(List<EventItem> events) {
    if (_searchQuery.isEmpty) return events;
    return events.where((e) {
      final title = e.title.toLowerCase();
      final location = e.location.toLowerCase();
      final category = e.categoryLabel.toLowerCase();
      return title.contains(_searchQuery) || location.contains(_searchQuery) || category.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final profile = SupabaseService.instance.currentProfile;
    final name = profile?.fullName.split(' ').first ?? 'Sahabat';

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => _reload(),
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
                  IconButton(
                    icon: const Icon(Icons.notifications_none, color: AppColors.textDark),
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
                    child: AppAvatar(url: profile?.avatarUrl, name: profile?.fullName ?? '?', radius: 16),
                  ),
                ]),
              ],
            ),
            const SizedBox(height: 16),
            Text('Halo, $name!', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            FutureBuilder<List<EventItem>>(
              future: _future,
              builder: (context, snap) {
                final count = _applySearch(snap.data ?? []).length;
                return RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    children: [
                      TextSpan(text: '$count kegiatan ', style: const TextStyle(color: AppColors.primary)),
                      const TextSpan(text: 'sedang menunggu'),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Cari aksi kebaikan...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                fillColor: AppColors.surface,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final c = _categories[i];
                  final selected = c == _category;
                  return ChoiceChip(
                    label: Text(c),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _category = c);
                      _reload();
                    },
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(color: selected ? Colors.white : AppColors.textDark),
                    backgroundColor: AppColors.surface,
                    side: const BorderSide(color: AppColors.border),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Unggulan Untukmu', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AllEventsScreen()),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                    child: Text('Lihat Semua', style: TextStyle(color: AppColors.primary, fontSize: 13)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 260,
              child: FutureBuilder<List<EventItem>>(
                future: _future,
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final events = _applySearch(snap.data!);
                  if (events.isEmpty) {
                    return Center(
                      child: Text(
                        _searchQuery.isNotEmpty ? 'Tidak ada hasil untuk "$_searchQuery"' : 'Belum ada kegiatan di kategori ini',
                        style: const TextStyle(color: AppColors.textGrey),
                      ),
                    );
                  }
                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: events.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (context, i) => _FeaturedCard(event: events[i]),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            const Text('Agenda Terdekat', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            FutureBuilder<List<EventItem>>(
              future: _future,
              builder: (context, snap) {
                final events = _applySearch(snap.data ?? []);
                final upcoming = events.isNotEmpty ? events.first : null;
                if (upcoming == null) return const SizedBox();
                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(18)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        upcoming.eventDate != null
                            ? DateFormat("EEEE, HH:mm 'WIB'", 'id_ID').format(upcoming.eventDate!)
                            : 'Segera',
                        style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(upcoming.title,
                          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(Icons.people_alt_outlined, color: Colors.white70, size: 16),
                        const SizedBox(width: 6),
                        Text('${upcoming.filledCount} Relawan lainnya ikut serta',
                            style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ]),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary),
                          onPressed: () => Navigator.of(context)
                              .push(MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: upcoming.id))),
                          child: const Text('Lihat Detail'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final EventItem event;
  const _FeaturedCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: event.id))),
      child: Container(
        width: 190,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  child: event.posterUrl != null
                      ? Image.network(event.posterUrl!, height: 110, width: double.infinity, fit: BoxFit.cover)
                      : Container(height: 110, color: AppColors.primaryLight,
                          child: const Icon(Icons.image_outlined, color: AppColors.primary, size: 32)),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: AppBadge(text: event.categoryLabel.toUpperCase(), color: AppColors.primaryDark.withOpacity(0.85)),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textGrey),
                    const SizedBox(width: 2),
                    Expanded(child: Text(event.location, style: const TextStyle(color: AppColors.textGrey, fontSize: 11.5), overflow: TextOverflow.ellipsis)),
                  ]),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 34,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(padding: EdgeInsets.zero, textStyle: const TextStyle(fontSize: 12.5)),
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: event.id))),
                      child: const Text('Daftar Sekarang'),
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